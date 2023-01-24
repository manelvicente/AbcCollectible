pragma solidity 0.6.6;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    mapping(address => uint8) private _owners; //Address is enabled or disabled (1 or 0)

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event DepositFunds(address from, uint256 amount);
    event WithdrawFunds(address to, uint256 amount);
    event TransferFunds(address from, address to, uint256 amount);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() internal {
        _owner = msg.sender;
        _owners[_owner] = 1;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @dev Checks if msg sender is a valid owner
     */
    modifier validOwner() {
        require(msg.sender == _owner || _owners[msg.sender] == 1);
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
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
     * @dev Allows owners to withdraw a certain amount
     */
    function withdraw(uint256 amount) public validOwner {
        msg.sender.transfer(amount);
        emit WithdrawFunds(msg.sender, amount);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
