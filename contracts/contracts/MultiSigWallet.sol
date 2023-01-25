pragma solidity 0.6.6;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MultiSigWallet
 * @dev The MultiSigWallet contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract MultiSigWallet is Ownable {
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

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() internal Ownable() {
        _owner = msg.sender;
        _owners[_owner] = 1;
    }

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
