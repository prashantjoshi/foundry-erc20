// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

error ManualToken__InvalidAddress();
error ManualToken__InsufficientBalance();

contract ManualToken {
    string private s_name;
    string private s_symbol;
    uint8 private s_decimals = 18;
    uint256 private s_totalSupply;
    mapping(address => uint256) public s_balances;
    mapping(address => mapping(address => uint256)) private s_allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        uint256 initialSupply
    ) {
        s_name = tokenName;
        s_symbol = tokenSymbol;
        s_totalSupply = initialSupply * 10 ** s_decimals;
        s_balances[msg.sender] = s_totalSupply;

        //notifies token creation
        emit Transfer(address(0), msg.sender, s_totalSupply);
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return s_balances[_owner];
    }

    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0) || to == address(0))
            revert ManualToken__InvalidAddress();
        if (s_balances[from] < value) revert ManualToken__InsufficientBalance();
        // uint256 prevBalance = s_balances[from] + s_balances[to];
        s_balances[from] -= value;
        s_balances[to] += value;

        emit Transfer(from, to, value);
        // assert(prevBalance == s_balances[from] + s_balances[to]);
    }

    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view returns (uint256) {
        return s_allowance[owner][spender];
    }
    function approve(address spender, uint256 value) public returns (bool) {
        if (spender == address(0)) revert ManualToken__InvalidAddress();
        s_allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public returns (bool) {
        uint256 currentAllowance = s_allowance[from][msg.sender];
        if (currentAllowance < value) revert ManualToken__InsufficientBalance();
        _transfer(from, to, value);
        s_allowance[from][msg.sender] = currentAllowance - value;
        emit Transfer(from, to, value);
        return true;
    }

    function name() public view returns (string memory) {
        return s_name;
    }

    function symbol() public view returns (string memory) {
        return s_symbol;
    }
    function decimals() public view returns (uint8) {
        return s_decimals;
    }
    function totalSupply() public view returns (uint256) {
        return s_totalSupply;
    }
}
