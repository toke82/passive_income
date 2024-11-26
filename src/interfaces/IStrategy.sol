// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IStrategy {
    function deposit(uint256 amount) external;
    function withdraw(uint256 amout) external;
    function getRewards() external returns (uint256);
    function getAPY() external returns (uint256);
    function distributedRewards(uint256 totalRewards) external;
}