// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/PassiveIncomeProtocol.sol";

contract DeployPassiveIncome is Script {
    function run() external {
        address stableToken = vm.envAddress("STABLE_TOKEN");
        address ownerAddress = vm.envAddress("OWNER_ADDRESS");

        require(stableToken != address(0), "Invalid stable token address");
        require(ownerAddress != address(0), "Invalid owner address");

        vm.startBroadcast();
        PassiveIncomeProtocol protocol = new PassiveIncomeProtocol(stableToken, ownerAddress);

        console.log("PassiveIncomeProtocl deployed at: ", address(protocol));
        vm.stopBroadcast();
    }
}