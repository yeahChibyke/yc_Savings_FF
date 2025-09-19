// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {TimeLockSavings} from "../src/Savings.sol";
import {MockUSDC} from "./mocks/MockUSDC.sol";

contract TestSavings is Test {
    TimeLockSavings tls;
    MockUSDC usdc;

    address owner = makeAddr("owner");

    // users
    address alice = makeAddr("user_1");
    address bob = makeAddr("user_2");
    address clara = makeAddr("user_3");

    // attacker
    address yeahChibyke = makeAddr("attacker");

    function setUp() public {
        usdc = new MockUSDC();

        vm.prank(owner);
        tls = new TimeLockSavings(address(usdc));

        // mint users some usdc
        usdc.mint(alice, 100);
        usdc.mint(bob, 100);
        usdc.mint(clara, 100);

        // users approve
        vm.prank(alice);
        usdc.approve(address(tls), 100);
        vm.prank(bob);
        usdc.approve(address(tls), 100);
        vm.prank(clara);
        usdc.approve(address(tls), 100);
    }

    function test_ponzi() public {
        _alice_deposits();

        vm.warp(block.timestamp + 60 days);

        vm.prank(alice);
        vm.expectRevert();
        tls.withdraw(0);
    }

    // helper fxns

    function _alice_deposits() internal {
        vm.prank(alice);
        tls.deposit(100);
    }

    function _bob_deposits() internal {
        vm.prank(bob);
        tls.deposit(100);
    }

    function _clara_deposits() internal {
        vm.prank(clara);
        tls.deposit(100);
    }

    function _trio_deposits() internal {
        _alice_deposits();
        _bob_deposits();
        _clara_deposits();
    }
}

// function test_getter_functions_alice() public {
//     _alice_deposits();

//     // Test getUserDepositCount
//     uint256 depositCount = tls.getUserDepositCount(alice);
//     assertEq(depositCount, 1);

//     // Test getUserDeposits
//     TimeLockSavings.Deposit[] memory deposits = tls.getUserDeposits(alice);
//     assertEq(deposits.length, 1);
//     assertEq(deposits[0].amount, 50e6);
//     assertEq(deposits[0].withdrawn, false);

//     // Test getDepositInfo
//     (uint256 amount,, bool withdrawn, uint256 currentReward, bool canWithdraw) = tls.getDepositInfo(alice, 0);

//     assertEq(amount, 50e6);
//     assertEq(withdrawn, false);
//     assertEq(currentReward, 0); // No reward immediately after deposit
//     assertEq(canWithdraw, false); // Cannot withdraw immediately (lock period not met)

//     // Test totalDeposited
//     uint256 totalDeposited = tls.totalDeposited(alice);
//     assertEq(totalDeposited, 50e6);

//     // Test totalLocked
//     uint256 totalLocked = tls.totalLocked();
//     assertEq(totalLocked, 50e6);

//     // Test getContractStats
//     (uint256 statsTotalLocked, uint256 statsTotalRewardsPaid, uint256 statsContractBalance) = tls.getContractStats();

//     assertEq(statsTotalLocked, 50e6);
//     assertEq(statsTotalRewardsPaid, 0); // No rewards paid yet
//     assertEq(statsContractBalance, 50e6);
// }
