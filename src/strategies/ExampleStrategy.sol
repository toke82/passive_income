// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IStrategy} from "../interfaces/IStrategy.sol";

contract ExampleStrategy is IStrategy {
    IERC20 public rewardToken;
    uint256 public totalInvested;

    constructor(address _rewardToken) {
        rewardToken = IERC20(_rewardToken);
    }

    function deposit(uint256 amount) external override {
        totalInvested += amount;
    }

    function withdraw(uint256 amount) external override {
        require(totalInvested >= amount, "Insufficient funds");
        totalInvested -= amount;
    }

    function getRewards() external override returns (uint256) {
        return totalInvested / 10;
    }

    function getAPY() external override returns (uint256) {
        return 10;
    }
}