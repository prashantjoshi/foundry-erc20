//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {console, Test} from "forge-std/Test.sol";
// import {DeployManualToken} from "../script/DeployManualToken.s.sol";
import {ManualToken} from "../src/ManualToken.sol";
import {ManualToken__InsufficientBalance, ManualToken__InvalidAddress} from "../src/ManualToken.sol";

contract ManualTokenTest is Test {
    // DeployManualToken public deployer;
    ManualToken public token;
    address public deployerAddress;
    address public user = makeAddr("user");
    address public bob = makeAddr("bob");

    string public constant TOKEN_NAME = "Prash";
    string public constant TOKEN_SYMBOL = "PJ";
    uint256 public constant INITIAL_SUPPLY = 1000;
    uint8 public constant DECIMALS = 18;
    uint256 public totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function setUp() public {
        // deployer = new DeployManualToken();
        token = new ManualToken("Prash", "PJ", 1000);
        deployerAddress = address(this);
        totalSupply = INITIAL_SUPPLY * 10 ** DECIMALS;
    }

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR TESTS
    //////////////////////////////////////////////////////////////*/

    function testConstructorSetsCorrectValues() public view {
        assertEq(token.name(), TOKEN_NAME);
        assertEq(token.symbol(), TOKEN_SYMBOL);
        assertEq(token.decimals(), DECIMALS);
        assertEq(token.totalSupply(), totalSupply);
        assertEq(token.balanceOf(deployerAddress), totalSupply);
    }

    function testConstructorEmitsTransferEvent() public {
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), deployerAddress, totalSupply);
        new ManualToken("Prash", "PJ", 1000);
    }

    /*//////////////////////////////////////////////////////////////
                            TRANSFER TESTS
    //////////////////////////////////////////////////////////////*/
    function testTransferSuccess() public {
        uint256 value = 5 * 10 ** DECIMALS;
        uint256 userPrevBalance = token.balanceOf(user);
        vm.expectEmit(true, true, false, true);
        emit Transfer(deployerAddress, user, value);
        bool result = token.transfer(user, value);
        assert(result);
        console.log("user balance after transfer ", token.balanceOf(user));
        assertEq(token.balanceOf(user), userPrevBalance + value);
        assertEq(token.balanceOf(deployerAddress), totalSupply - value);
    }

    function testTransferZeroAmount() public {
        uint256 userPrevBalance = token.balanceOf(user);
        vm.expectEmit(true, true, false, true);
        emit Transfer(deployerAddress, user, 0);
        bool result = token.transfer(user, 0);
        assert(result);
        console.log("user balance after transfer ", token.balanceOf(user));
        assertEq(token.balanceOf(user), userPrevBalance);
    }

    function testTransferToZeroAddress() public {
        vm.expectRevert();
        emit Transfer(deployerAddress, address(0), 0);
        bool result = token.transfer(address(0), 0);
        assert(!result);
    }

    function testTransferInsufficientBalance() public {
        uint256 amount = token.balanceOf(deployerAddress);
        console.log("deployer address balance ", amount);
        console.log("trying to transfer ", amount + 1);
        vm.expectRevert(ManualToken__InsufficientBalance.selector);
        token.transfer(user, amount + 1);
    }

    function testTransferFromUserWithoutBalance() public {
        vm.prank(user);
        vm.expectRevert(ManualToken__InsufficientBalance.selector);
        token.transfer(bob, 10 ** DECIMALS);
    }

    /*//////////////////////////////////////////////////////////////
                            APPROVAL TESTS
    //////////////////////////////////////////////////////////////*/
    function testApprovalSuccess() public {
        uint256 approvalAmount = 15 ** DECIMALS;
        vm.expectEmit(true, true, false, true);
        emit Approval(deployerAddress, user, approvalAmount);
        // uint256 oldAllowedAmount = token.allowance(deployerAddress, user);
        token.approve(user, approvalAmount);
        uint256 newAllowedAmount = token.allowance(deployerAddress, user);
        // console.log("old allowed amount ", oldAllowedAmount);
        // console.log("new allowed amount ", newAllowedAmount);
        // console.log("approval amount ", approvalAmount);
        // console.log("diff ", newAllowedAmount - oldAllowedAmount);
        assertEq(approvalAmount, newAllowedAmount);
    }

    function testApprovalZeroAddress() public {
        vm.expectRevert(ManualToken__InvalidAddress.selector);
        token.approve(address(0), 5 * 10 ** DECIMALS);
    }

    function testApprovalOverwrite() public {
        uint256 firstAmount = 16 * 10 ** DECIMALS;
        uint256 secondAmount = 38 * 10 ** DECIMALS;
        uint256 allowanceAmount;
        token.approve(user, firstAmount);
        allowanceAmount = token.allowance(deployerAddress, user);
        console.log("allowed amount ", allowanceAmount);
        assertEq(firstAmount, allowanceAmount);
        token.approve(user, secondAmount);
        allowanceAmount = token.allowance(deployerAddress, user);
        console.log("allowed amount ", allowanceAmount);
        assertEq(secondAmount, allowanceAmount);
    }

    /*//////////////////////////////////////////////////////////////
                            TRANSFER_FROM TESTS
    //////////////////////////////////////////////////////////////*/

    function testTransferFromSuccess() public {
        /**
         * Scenario: Alice approves DEX contract to spend tokens on her behalf,
         * then DEX transfers tokens from Alice to Bob
         */
        address alice = makeAddr("alice");
        // bob = makeAddr("bob");
        uint256 transferAmount = 13 * 10 ** DECIMALS;
        uint256 approvedAmount = 18 * 10 ** DECIMALS;
        //token contract transfers to alice
        token.transfer(alice, approvedAmount);
        assertEq(token.balanceOf(alice), approvedAmount);

        vm.prank(alice);
        vm.expectEmit(true, true, false, true);
        emit Approval(alice, deployerAddress, approvedAmount);
        token.approve(deployerAddress, approvedAmount);
        assertEq(token.allowance(alice, deployerAddress), approvedAmount);

        uint256 aliceInitialBalance = token.balanceOf(alice);
        uint256 bobInitialBalance = token.balanceOf(bob);

        vm.expectEmit(true, true, false, true);
        emit Transfer(alice, bob, transferAmount);
        bool success = token.transferFrom(alice, bob, transferAmount);

        assert(success);
        assertEq(token.balanceOf(alice), aliceInitialBalance - transferAmount);
        assertEq(token.balanceOf(bob), bobInitialBalance + transferAmount);
        assertEq(
            token.allowance(alice, deployerAddress),
            approvedAmount - transferAmount
        );
    }

    function testTransferFromInsufficientAllowance() public {
        address alice = makeAddr("alice");
        // bob = makeAddr("bob");
        uint256 transferAmount = 25 * 10 ** DECIMALS;
        uint256 approvedAmount = 18 * 10 ** DECIMALS;
        //token contract transfers to alice
        token.transfer(alice, approvedAmount);
        assertEq(token.balanceOf(alice), approvedAmount);

        vm.prank(alice);
        vm.expectEmit(true, true, false, true);
        emit Approval(alice, deployerAddress, approvedAmount);
        token.approve(deployerAddress, approvedAmount);
        assertEq(token.allowance(alice, deployerAddress), approvedAmount);

        vm.expectRevert(ManualToken__InsufficientBalance.selector);
        token.transferFrom(alice, bob, transferAmount);
    }

    function testTransferFromNoAllowance() public {
        address alice = makeAddr("alice");
        // bob = makeAddr("bob");
        uint256 transferAmount = 18 * 10 ** DECIMALS;
        uint256 approvedAmount = 18 * 10 ** DECIMALS;
        //token contract transfers to alice
        token.transfer(alice, approvedAmount);
        assertEq(token.balanceOf(alice), approvedAmount);

        vm.expectRevert(ManualToken__InsufficientBalance.selector);
        token.transferFrom(alice, bob, transferAmount);
    }

    function testTransferFromInsufficientBalance() public {
        address alice = makeAddr("alice");
        uint256 transferAmount = token.totalSupply() + 1;
        token.transfer(alice, transferAmount);
        vm.prank(alice);
        token.approve(deployerAddress, transferAmount);
        vm.expectRevert(ManualToken__InsufficientBalance.selector);
        token.transferFrom(alice, bob, transferAmount);
    }

    function testTransferFromInvalidToAddress() public {
        address alice = makeAddr("alice");
        uint256 transferAmount = 18 * 10 ** DECIMALS;

        // Give Alice tokens and unlimited allowance
        token.transfer(alice, transferAmount);
        vm.prank(alice);
        token.approve(deployerAddress, transferAmount);

        // NOW this will reach _transfer() and hit the InvalidAddress check
        vm.expectRevert(ManualToken__InvalidAddress.selector);
        token.transferFrom(alice, address(0), transferAmount); // to = address(0)
    }

    function testTransferFromInvalidFromAddress() public {
        vm.expectRevert(ManualToken__InvalidAddress.selector);
        token.transferFrom(address(0), bob, 0);
    }

    /*//////////////////////////////////////////////////////////////
                            BALANCE TESTS
    //////////////////////////////////////////////////////////////*/
    function testBalanceOfDeployerAddress() public view {
        assertEq(token.balanceOf(deployerAddress), token.totalSupply());
    }

    function testBalanceOfInvalidAddress() public view {
        assertEq(token.balanceOf(address(0)), 0);
    }

    /*//////////////////////////////////////////////////////////////
                            ALLOWANCE TESTS
    //////////////////////////////////////////////////////////////*/
    function testAllowanceZeroByDefault() public view {
        assertEq(token.allowance(deployerAddress, bob), 0);
    }

    function testAllowanceAfterApproval() public {
        uint256 amount = 16 * 10 ** DECIMALS;
        bool success = token.approve(bob, amount);
        assert(success);
        console.log("amount approved ", token.allowance(deployerAddress, bob));
        assertEq(token.allowance(deployerAddress, bob), amount);
    }

    /*//////////////////////////////////////////////////////////////
                            FUZZ TESTS
    //////////////////////////////////////////////////////////////*/

    function testFuzzTransfer(uint256 amount) public {
        amount = bound(amount, 0, token.totalSupply());
        bool success = token.transfer(bob, amount);
        assert(success);
        assertEq(token.balanceOf(bob), amount);
    }

    function testFuzzApproval(uint256 amount) public {
        bool success = token.approve(bob, amount);
        assert(success);
        assertEq(token.allowance(deployerAddress, bob), amount);
    }

    function testFuzzTransferFrom(uint256 amount) public {
        address alice = makeAddr("alice");
        amount = bound(amount, 0, token.totalSupply());
        token.transfer(alice, amount);
        vm.prank(alice);
        token.approve(deployerAddress, amount);
        bool success = token.transferFrom(alice, bob, amount);
        assert(success);
        assertEq(token.balanceOf(bob), amount);
    }
}
