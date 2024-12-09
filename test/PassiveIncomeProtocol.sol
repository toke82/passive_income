// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/PassiveIncomeProtocol.sol";
import "../src/strategies/ExampleStrategy.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract PassiveIncomeProtocolTest is Test {
    PassiveIncomeProtocol protocol;
    ExampleStrategy strategy;
    ERC20Mock stableToken;
    address user = address(0x123);
    address owner = address(0x456);
    uint256 depositAmount = 50 ether;

    function setUp() public {
        stableToken = new ERC20Mock();
        protocol = new PassiveIncomeProtocol(address(stableToken), owner);
        strategy = new ExampleStrategy(address(stableToken));

        stableToken.mint(user, 100 ether);
        stableToken.mint(address(strategy), 100 ether);

        vm.startPrank(owner);
        protocol.addStrategy(address(strategy));
        vm.stopPrank();

        vm.startPrank(user);
        stableToken.approve(address(protocol), 100 ether);
        vm.stopPrank();
    }

    function testDepositAndWithdraw() public {
        vm.startPrank(user);
        protocol.deposit(50 ether);

        uint256 balanceAfterDeposit = protocol.userBalances(user);
        assertEq(balanceAfterDeposit, 50 ether);

        protocol.withdraw(20 ether);
        uint256 balanceAfterWithdraw = protocol.userBalances(user);
        assertEq(balanceAfterWithdraw, 30 ether);

        vm.stopPrank();
    }

    function testAddStrategy() public {
        vm.startPrank(owner);
        protocol.addStrategy((address(strategy)));
        vm.stopPrank();
        assertEq(protocol.strategies(0), address(strategy));
    }

    function testOnlyOwnerCanAddStrategy() public {
        vm.startPrank(user);
        try protocol.addStrategy(address(strategy)) {
            fail();
        } catch (bytes memory) {
        }
        vm.stopPrank();
    }
    
    function testRewardsCollection() public {
        // User deposits 50 ether into the protocol
        vm.startPrank(user);
        protocol.deposit(depositAmount);
        vm.stopPrank();

        // Initial rewards should be 0 before deposit (or based on existing strategy logic)
        uint256 initialRewards = strategy.getRewards();
        console.log("Initial rewards: ", initialRewards);
        assertEq(initialRewards, 5 ether, "Initial rewards should be 5 ether");

        // Total invested should be 50 ether
        uint256 totalInvested = strategy.totalInvested();
        console.log("Total invested: ", totalInvested);
        assertEq(totalInvested, 50 ether, "Total invested should be 50 ether");

        // Owner collects rewards
        vm.startPrank(owner);
        protocol.collectRewards();  // This will call distributedRewards on the strategy
        vm.stopPrank();

        // After rewards collection, check new rewards
        uint256 totalRewards = strategy.getRewards();
        console.log("Total rewards after collection: ", totalRewards);

        // The difference in rewards should be 5 ether (10% of the deposit)
        uint256 rewardsDifference = totalRewards - initialRewards;
        console.log("Rewards difference: ", rewardsDifference);
        assertEq(rewardsDifference, 5 ether, "The reward difference should be 5 ether");

        // User's balance should have increased by 5 ether
        uint256 userBalanceBefore = stableToken.balanceOf(user);
        uint256 rewardsDistributed = 5 ether;  // The amount of rewards expected

        uint256 userBalanceAfter = stableToken.balanceOf(user);
        assertEq(userBalanceAfter, userBalanceBefore + rewardsDistributed, "User balance after rewards collection is incorrect");
    }


    function testMinting() public {
        uint256 initialSupply = stableToken.totalSupply();

        vm.startPrank(owner);
        stableToken.mint(address(protocol), 50 ether);
        vm.stopPrank();

        assertEq(stableToken.totalSupply(), initialSupply + 50 ether);
    }
}