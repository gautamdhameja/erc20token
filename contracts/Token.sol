pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol";

contract Token is StandardToken {
    address public owner;

    string public constant name = "DemoToken";                         // Set the token name for display
    string public constant symbol = "DTO";                             // Set the token symbol for display

    // SUPPLY
    uint8 public constant decimals = 0;                               // Set the number of decimals for display
    uint256 public constant initialSupply = 1000000000;               // Token total supply

    // all balance
    uint256 public totalSupply;
    bool private unFreeze;

    // mapping
    mapping(address => bool) public frozenAccount;

    // list of receiver accounts
    address[] public receivers;

    // events
    event FundsFrozen(address target, bool frozen);
    event AccountFrozenError();
    event Refund(address target, uint256 amount);

    // modifier
    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function.");
        _;
    }

    // constructor function
    constructor() public {
        // set _owner
        owner = msg.sender;

        // total supply
        totalSupply = initialSupply;

        // owner of token contract has all tokens
        balances[msg.sender] = initialSupply;

        // frozen by default
        unFreeze = false;
    }

    // returns full list of receiver addresses
    function getAccountList() public view returns (address[]) {
        address[] memory v = new address[](receivers.length);
        for (uint256 i = 0; i < receivers.length; i++) {
            v[i] = receivers[i];
        }
        return v;
    }

    // freeze accounts
    function changeFreezeStatus(address target, bool freeze) public onlyOwner {
        frozenAccount[target] = freeze;
        emit FundsFrozen(target, freeze);
    }

    // unfreeze all accounts
    function unFreezeAll() public onlyOwner {
        unFreeze = true;
    }

    /**
    * @dev Transfer token for a specified address when not paused
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        // source account should not be frozen if contract is in not open state
        if (frozenAccount[msg.sender] && !unFreeze) {
            emit AccountFrozenError();
            return false;
        }
        
        // transfer fund first if sender is not frozen
        require(super.transfer(_to, _value), "Transfer failed.");

        // record the receiver address into list
        receivers.push(_to);
        
        // automatically freeze receiver that is not whitelisted
        if (frozenAccount[_to] == false && !unFreeze) {
            frozenAccount[_to] = true;
            emit FundsFrozen(_to, true);
        }
        return true;
    }

    /**
    * @dev Transfer tokens from one address to another when not paused
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the amount of tokens to be transferred
    */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        // source account should not be frozen if contract is in not open state
        if (frozenAccount[_from] && !unFreeze) {
            emit AccountFrozenError();
            return false;
        }
        
        // transfer funds
        require(super.transferFrom(_from, _to, _value), "Transfer failed.");
        
        // record the receiver address into list
        receivers.push(_to);
        
        // automatically freeze account
        // don't freeze if open to all
        if (frozenAccount[_to] == false && !unFreeze) {
            frozenAccount[_to] = true;
            emit FundsFrozen(_to, true);
        }
        return true;
    }

    /**
    * @dev Refund - transfer tokens back to the owner
    * Requires the refund account to approve the owner to withdraw the amount
    * @param _to address Refund account address
    * @param _value uint256 the amount of tokens to be transferred
    */
    function refund(address _to, uint256 _value) public onlyOwner returns (bool) {
        // transfer funds from refund account to owner
        require(super.transferFrom(_to, owner, _value), "Transfer failed.");
        emit Refund(_to, _value);
        return true;
    }
}