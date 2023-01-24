pragma solidity 0.6.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerbase.sol";

/**
 * @title AbcCollectible
 * @author Manuel Vicente
 * @dev An ABC collectible is a type ERC-721
 */
contract AbcCollectible is ERC721, VRFConsumerBase {
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
    {
        keyHash = _keyHash;
        fee = 0.1 * 10**18; // 0.1 LINK hardcoded (in wei)
        tokenCounter = 0;
    }

    /**
     * @dev Creates a collectible using ChainlinkVRF as RNG
     * @param tokenURI - Pointer to the collectibles metadata (JSON) *Could be an API call*
     * @return requestId - bytes32
     */
    function createCollectible(string memory tokenURI)
        public
        returns (bytes32)
    {
        /**
         * @dev requestRandomness - A Asynchronous request to the ChainlinkVRF
         * @param fee - Link token to fund RNG request
         * @param keyHash - Hash to verify numbers randomness
         */
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
}
