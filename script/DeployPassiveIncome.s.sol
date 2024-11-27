// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/PassiveIncomeProtocol.sol";

contract DeployPassiveIncome is Script {
    function run() external {
        vm.startBroadcast();
        address stableToken = 0x41E94Eb019C0762f9Bfcf9Fb1E58725BfB0e7582;
        new PassiveIncomeProtocol(stableToken);
        vm.stopBroadcast();
    }
}