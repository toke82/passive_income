// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/PassiveIncomeProtocol.sol";
import "../src/strategies/ExampleStrategy.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract PassiveIncomeProtocolTest is Test {
    PassiveIncomeProtocol protocol;
    ExampleStrategy strategy;
    ERC20 stableToken;
    address user = address(0x123);

    function setUp() public {
        stableToken = new ERC20("StableToken", "STABLE");
        protocol = new PassiveIncomeProtocol(address(stableToken));
        strategy = new ExampleStrategy(address(stableToken));
        stableToken.mint(user, 100 ether);
    }

    function testDepositAndWithdraw() public {
        vm.startPrank(user);
        stableToken.approve(address(protocol), 500 ether);
        protocol.deposit(500 ether);

        uint256 balanceAfterDeposit = protocol.userBalances(user);
        assertEq(balanceAfterDeposit, 500 ether);

        protocol.withdraw(200 ether);
        uint256 balanceAfterWithdraw = protocol.userBalances(user);
        assertEq(balanceAfterWithdraw, 300 ether);

        vm.stopPrank();
    }

    function testAddStrategy() public {
        protocol.addStrategy((address(strategy)));
        assertEq(protocol.strategies(0), address(strategy));
    }
}