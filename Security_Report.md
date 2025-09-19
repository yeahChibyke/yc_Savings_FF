## Audit Report for Savings FF Contract

### [H-1] Incorrect Reward Payout Due To Miscalculation

**Summary:** 

The `withdraw()` function calls the `calculateRewards()` function with the parameters in the wrong order.

**Vulnerability Details:**

In the `else` block of the `withdraw()` function, the rewards for users are calculated using the `calculateRewards()` function. But where the order of parameters in the `calculaterewards()` function is `(uint256 _amount, uint256 _timeElapsed)`, it is messed up in the `withdraw()` function - `(uint256 timeElapsed, uint256 amount)`.

```solidity
    function withdraw(uint256 _depositId) external {
        ...
        ...
        else {
            // Normal withdrawal with rewards
            uint256 reward = calculateReward(timeElapsed, amount); // <-- wrong order of parameters>
            ...
            ...
        }
    }
```

**Impact:**

Incorrect reward calculations and payout

**Proof of Code:**

Run the `test_wrong_reward_cal()` test:

```solidity
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

    function test_wrong _reward_cal() public {
        _trio_deposits();

        /// get expected rewards
        uint256 expectedRewards = tls.calculateReward(100, 60 days);
        (uint256 payoutWithoutRewards,,,,) = tls.getDepositInfo(alice, 0);

        vm.warp(block.timestamp + 60 days);

        assert(usdc.balanceOf(alice) == 0); // alice has zero usdc before withdrawal

        vm.prank(alice);
        tls.withdraw(0);

        assert(usdc.balanceOf(alice) != (payoutWithoutRewards + expectedRewards)); // alice did not get any extra rewards despite meeting requirements
        assert(usdc.balanceOf(alice) == 100);
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
```

**Recommended Mitigation:**

Fix the order of the parameters in the `withdraw()` function:

```diff
        function withdraw(uint256 _depositId) external {
        ...
        ...    
        else {
-           uint256 reward = calculateReward(timeElapsed, amount);
+           uint256 reward = calculateReward(amount, timeElapsed);
            ...
            ...
        }
    }
```

### [H-2] WHere Is The Yield?

**Summary:**

If only one person saves, they get no extra rewards. If multiple people save and no one chooses to withdraw early, the last person gets no rewards. Ponzi vibes.

**Proof of Code:**

The issue in `H-1` should be fixed first.

Run the `test_ponzi()` test:

```solidity
    function test_ponzi() public {
        _alice_deposits();

        vm.warp(block.timestamp + 60 days);

        vm.prank(alice);
        vm.expectRevert();
        tls.withdraw(0);
    }
```

**Recommended Mitigation:**

Utilize popular yield generating protocols.