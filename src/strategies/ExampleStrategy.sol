// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IStrategy} from "../interfaces/IStrategy.sol";

contract ExampleStrategy is IStrategy {
    IERC20 public rewardToken;
    uint256 public totalInvested;
    mapping(address => uint256) public userInvestments;
    mapping(address => uint256) public userRewards;

    uint256 public rewardRate = 10;

    constructor(address _rewardToken) {
        rewardToken = IERC20(_rewardToken);
    }

    function deposit(uint256 amount) external override {
        totalInvested += amount;
        userInvestments[msg.sender] += amount;

        uint256 rewards = calculateRewards(msg.sender);
        userRewards[msg.sender] += rewards;
    }

    function withdraw(uint256 amount) external override {
        require(totalInvested >= amount, "Insufficient funds");
        totalInvested -= amount;

        userInvestments[msg.sender] -= amount;

        uint256 rewards = calculateRewards(msg.sender);
        userRewards[msg.sender] -= rewards;
    }

    function calculateRewards(address user) internal view returns (uint256) {
        uint256 userInvestment = userInvestments[user];
        return (userInvestment * rewardRate) / 100;
    }

    function getRewards() external override view returns (uint256) {
       return userRewards[msg.sender];
    }

    function getAPY() external override pure returns (uint256) {
        return 10;
    }

    function distributedRewards(uint256 totalRewards) external override {
        require(totalRewards > 0, "No rewards to distribute");
        rewardToken.transfer(msg.sender, totalRewards);
    }    
}