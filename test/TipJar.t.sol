// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {TipJar} from "../src/TipJar.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract TipJarTest is Test {
    TipJar public tipJar;

    // Create 3 distinct addresses to test the contract
    address public owner = makeAddr("owner");
    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");

    /// @notice Run before each test
    /// @dev Deploys a new instance of TipJar and gives user1 and user2 test ETH
    function setUp() public {
        // We use vm.prank to set the owner as the deployer for next call (deploying the contract)
        vm.prank(owner);
        tipJar = new TipJar();

        // Give user1 and user2 test ETH to tip
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
    }

    /// @notice Test the initial state of the contract
    function test_InitialState() public view {
        assertEq(tipJar.owner(), owner);
        assertEq(tipJar.totalReceived(), 0);
        assertEq(address(tipJar).balance, 0);
    }

    // Test Deposit Functionality

    function test_DepositOnce() public {
        vm.prank(user1);
        tipJar.deposit{value: 1 ether}();

        assertEq(tipJar.totalTipped(user1), 1 ether);
        assertEq(tipJar.totalReceived(), 1 ether);
        assertEq(address(tipJar).balance, 1 ether);
    }

    function test_DepositTwice() public {
        vm.prank(user1);
        tipJar.deposit{value: 1 ether}();

        vm.prank(user1);
        tipJar.deposit{value: 2 ether}();

        assertEq(tipJar.totalTipped(user1), 3 ether);
        assertEq(tipJar.totalReceived(), 3 ether);
        assertEq(address(tipJar).balance, 3 ether);
    }

    function test_DepositDifferentUsers() public {
        vm.prank(user1);
        tipJar.deposit{value: 1 ether}();

        vm.prank(user2);
        tipJar.deposit{value: 2 ether}();

        assertEq(tipJar.totalTipped(user1), 1 ether);
        assertEq(tipJar.totalTipped(user2), 2 ether);
        assertEq(tipJar.totalReceived(), 3 ether);
        assertEq(address(tipJar).balance, 3 ether);
    }

    function test_ZeroDeposit() public {
        vm.expectRevert("TipJar: Cannot deposit zero value");
        vm.prank(user1);
        tipJar.deposit{value: 0}();
    }

    // Test Withdraw Functionality

    function test_OwnerWithdraw() public {
        vm.prank(user1);
        tipJar.deposit{value: 1 ether}();

        uint256 ownerInitialBalance = owner.balance;

        vm.prank(owner);
        tipJar.withdraw();

        assertEq(tipJar.totalReceived(), 1 ether);
        assertEq(address(tipJar).balance, 0);
        assertEq(owner.balance, ownerInitialBalance + 1 ether);
    }

    function test_NonOwnerWithdraw() public {
        vm.prank(user1);
        tipJar.deposit{value: 1 ether}();

        // Expect a revert from OwnableUnauthorizedAccount with the user2 address
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user2));
        vm.prank(user2);
        tipJar.withdraw();
    }

    function test_EmptyWithdraw() public {
        vm.expectRevert("TipJar: No balance to withdraw");
        vm.prank(owner);
        tipJar.withdraw();
    }

    // Test events

    // Declare the event signature to match TipJar.sol
    event Tipped(address indexed from, uint256 amount, uint256 newTotal);

    function test_EmitTippedEvent() public {
        // vm.expectEmit() checks for 3 topics and 1 data payload
        // checkTopic1 (from), checkTopic2 (none), checkTopic3 (none), checkData (amount, newTotal), emitter address
        vm.expectEmit(true, false, false, true, address(tipJar));

        // Emit what we EXPECT to see:
        emit Tipped(user1, 1 ether, 1 ether);

        // Perform the deposit that triggers the event:
        vm.prank(user1);
        tipJar.deposit{value: 1 ether}();
    }
}
