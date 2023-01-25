pragma solidity 0.6.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerbase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title AbcCollectible
 * @author Manuel Vicente
 */
contract AbcCollectible is ERC721, VRFConsumerBase, Ownable {
    //---------MultiSigWallet-------------------------------------------
    address private _owner;

    mapping(address => uint8) private _owners; //Address is enabled or disabled (1 or 0)

    uint256 constant MIN_SIGNATURES = 1;
    uint256 private _transactionIdx;

    /**
     * @dev Creates a transaction data type to
     */
    struct Transaction {
        address from;
        address to;
        uint256 amount;
        uint8 signatureCount;
        mapping(address => uint8) signatures;
    }

    /**
     * @dev Creates mapping associating TxIds and transactions and array with pending transactions
     */
    mapping(uint256 => Transaction) private _transactions;
    uint256[] private _pendingTransactions;

    /**
     * @dev arrays to log relevant event
     */
    event DepositFunds(address from, uint256 amount);
    event TransactionCreated(
        address from,
        address to,
        uint256 amount,
        uint256 transactionId
    );
    event TransactionCompleted(
        address from,
        address to,
        uint256 amount,
        uint256 transactionId
    );
    event TransactionSigned(address by, uint256 transactionId);

    //---------AbcCollectible-------------------------------------------

    bytes32 internal keyHash;
    uint256 public fee;
    uint256 tokenCounter;

    enum Letter {
        Alpha,
        Beta,
        Delta
    }

    mapping(bytes32 => address) public requestIdToSender;
    mapping(bytes32 => string) public requestIdToTokenURI;
    mapping(uint256 => Letter) public tokenIdToLetter;
    mapping(bytes32 => uint256) public requestIdToTokenId;

    event RequestedCollectible(bytes32 indexed requestId);
    event ReturnedCollectible(bytes32 indexed requestId, uint256 randomNumber);

    constructor(
        address _VRFCoordinator,
        address _LinkToken,
        bytes32 _keyHash
    )
        public
        VRFConsumerBase(_VRFCoordinator, _LinkToken)
        ERC721("Alphabet", "ABC")
        Ownable()
    {
        keyHash = _keyHash;
        fee = 0.1 * 10**18; // 0.1 LINK hardcoded (in wei)
        tokenCounter = 0;
        _owner = msg.sender;
        _owners[_owner] = 1;
    }

    /**
     * @dev Creates a collectible using ChainlinkVRF as RNG
     * @param tokenURI - Pointer to the collectibles metadata (JSON) *Could be an API call*
     * @return requestId - bytes32
     */
    function createCollectible(string memory tokenURI)
        public
        payable
        returns (bytes32)
    {
        /**
         * @dev requestRandomness - A Asynchronous request to the ChainlinkVRF
         * @param fee - Link token to fund RNG request
         * @param keyHash - Hash to verify numbers randomness
         */
        require(msg.value >= 0.01 ether, "Not enough Ether sent");
        bytes32 requestId = requestRandomness(keyHash, fee);
        // Confirm that request made is correctly returned to sender
        requestIdToSender[requestId] = msg.sender;
        requestIdToTokenURI[requestId] = tokenURI;
        emit RequestedCollectible(requestId);
    }

    /**
     * @dev The oracle fulfills the RNG request and returns the generated number
     * @param requestId - Request Identifier associated with off-chain event
     * @param randomNumber - number given by the off-chain oracle
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomNumber)
        internal
        override
    {
        address LetterOwner = requestIdToSender[requestId];
        string memory tokenURI = requestIdToTokenURI[requestId];
        uint256 newItemId = tokenCounter;
        _safeMint(LetterOwner, newItemId); // Creating Collectible with owners address and Item ID
        _setTokenURI(newItemId, tokenURI); // Setting the tokenURI to the correct token
        Letter letter = Letter(randomNumber % 3); // Get a number [0,1,2] to choose Letter type
        tokenIdToLetter[newItemId] = letter;
        requestIdToTokenId[requestId] = newItemId;
        tokenCounter++;
        emit ReturnedCollectible(requestId, randomNumber);
    }

    /**
     * @dev If the given spender is authorized to, set the tokenId to the tokenURI
     * @param tokenId - ID of the collectible
     * @param _tokenURI - Metadata of the collectible
     */
    function setTokenURI(uint256 tokenId, string memory _tokenURI)
        public
        approvedOrOwner(tokenId)
    {
        _setTokenURI(tokenId, _tokenURI);
    }

    /**
     * @dev Checks wether the given spender can transfer a given token ID
     * @param tokenId - ID of the collectible
     */
    modifier approvedOrOwner(uint256 tokenId) {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: Transfer caller is not owner nor approved"
        );
        _;
    }

    //---------MultiSigWallet-------------------------------------------

    /**
     * @dev Checks if msg sender is a valid owner
     */
    modifier validOwner() {
        require(msg.sender == _owner || _owners[msg.sender] == 1);
        _;
    }

    /**
     * @dev Adds another valid owner
     */
    function addOwner(address newOwner) public onlyOwner {
        _owners[newOwner] = 1;
    }

    /**
     * @dev Removes Owner (disables owner)
     */
    function removeOwner(address ownerToBeRemoved) public onlyOwner {
        _owners[ownerToBeRemoved] = 0;
    }

    /**
     * @dev allows owners to deposit
     */
    function deposit() public payable validOwner {
        emit DepositFunds(msg.sender, msg.value);
    }

    /**
     * @dev Allows a valid owner to iniciate a transaction to withdraw fund to a given address
     */
    function withdrawTo(address to, uint256 amount) public validOwner {
        require(address(this).balance >= amount);
        uint256 transactionId = _transactionIdx++;

        Transaction memory transaction;
        transaction.from = msg.sender;
        transaction.to = to;
        transaction.amount = amount;
        transaction.signatureCount = 0;

        _transactions[transactionId] = transaction;
        _pendingTransactions.push(transactionId);

        emit TransactionCreated(msg.sender, to, amount, transactionId);
    }

    /**
     * @dev Gets Pending transactions in Array
     * @return Array with transaction waiting to be completed
     */
    function getPendingTransactions()
        public
        view
        validOwner
        returns (uint256[] memory)
    {
        return _pendingTransactions;
    }

    /**
     * @dev Where valid owners to sign and complete pending transactions
     */
    function signTransaction(uint256 transactionId) public validOwner {
        Transaction storage transaction = _transactions[transactionId];

        // Transaction must exist
        require(address(0) != transaction.from);
        // Creator cannot sign the transaction
        require(msg.sender != transaction.from);
        // Cannot sign a transaction more than once
        require(transaction.signatures[msg.sender] != 1);

        transaction.signatures[msg.sender] = 1;
        transaction.signatureCount++;

        TransactionSigned(msg.sender, transactionId);

        if (transaction.signatureCount >= MIN_SIGNATURES) {
            require(address(this).balance >= transaction.amount);
            payable(transaction.to).transfer(transaction.amount);
            TransactionCompleted(
                transaction.from,
                transaction.to,
                transaction.amount,
                transactionId
            );
            deleteTransaction(transactionId);
        }
    }

    /**
     * @dev Where valid owners delete pending transactions
     */
    function deleteTransaction(uint256 transactionId) public validOwner {
        uint8 replace = 0;
        for (uint256 i = 0; i < _pendingTransactions.length; i++) {
            if (1 == replace) {
                _pendingTransactions[i - 1] = _pendingTransactions[i];
            } else if (transactionId == _pendingTransactions[i]) {
                replace = 1;
            }
        }
        _pendingTransactions.pop();
        delete _transactions[transactionId];
    }

    /**
     * @dev Check contracts balance
     * @return contracts balance
     */
    function walletBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
