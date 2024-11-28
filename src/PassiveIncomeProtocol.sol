// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IStrategy} from "./interfaces/IStrategy.sol";

contract PassiveIncomeProtocol is Ownable {
    IERC20 public stableToken;
    address[] public strategies;


    mapping(address => uint256) public userBalances;
    uint256 public totalDeposits;

    event Deposit(address indexed user, uint amount);
    event Withdraw(address indexed user, uint256 amount);
    event StrategyAdded(address strategy);
    event RewardsCollected(uint256 totalRewards);

    constructor(address _stableToken, address initialOwner) Ownable(initialOwner) {
        stableToken = IERC20(_stableToken);
    }

    function deposit(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        stableToken.transferFrom(msg.sender, address(this), amount);

        userBalances[msg.sender] += amount;
        totalDeposits += amount;

        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        require(userBalances[msg.sender] >= amount, "Insufficient balance");
        stableToken.transfer(msg.sender, amount);

        userBalances[msg.sender] -= amount;
        totalDeposits -= amount;

        emit Withdraw(msg.sender, amount);
    }

    function addStrategy(address strategy) external onlyOwner {
        strategies.push(strategy);
        emit StrategyAdded(strategy);
    }

    function collectRewards() external onlyOwner {
        uint256 totalRewards = 0;
        for (uint256 i = 0; i < strategies.length; i++) {
            totalRewards += IStrategy(strategies[i]).getRewards();
        }

        emit RewardsCollected(totalRewards);
    }
}
