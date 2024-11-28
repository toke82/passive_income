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

    function setUp() public {
        stableToken = new ERC20Mock();
        protocol = new PassiveIncomeProtocol(address(stableToken), owner);
        strategy = new ExampleStrategy(address(stableToken));
        stableToken.mint(user, 100 ether);

        vm.startPrank(user);
        stableToken.approve(address(protocol), 100 ether);
        vm.stopPrank();

        protocol.addStrategy(address(strategy));
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
        protocol.addStrategy((address(strategy)));
        assertEq(protocol.strategies(0), address(strategy));
    }

    function testRewardsCollection() public {
        vm.startPrank(user);
        protocol.deposit(50 ether);
        vm.stopPrank();

        uint256 initialRewards = strategy.getRewards();

        vm.startPrank(owner);
        protocol.collectRewards();
        uint256 totalRewards = strategy.getRewards();
        assertEq(totalRewards, initialRewards + 5 ether);

        vm.stopPrank();
    }

    function testMinting() public {
        uint256 initialSupply = stableToken.totalSupply();

        vm.startPrank(owner);
        stableToken.mint(address(protocol), 50 ether);
        vm.stopPrank();

        assertEq(stableToken.totalSupply(), initialSupply + 50 ether);
    }
}