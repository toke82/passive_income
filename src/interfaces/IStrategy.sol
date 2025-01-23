// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IStrategy {
    function deposit(uint256 amount) external;
    function withdraw(uint256 amout) external;
    function harvest() external;
    function getBalance() external view returns (uint256);
    function getRewards() external view returns (uint256);
    function distributedRewards(uint256 amount) external;
}