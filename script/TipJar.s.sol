// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {TipJar} from "../src/TipJar.sol";

contract DeployTipJar is Script {
    function run() external returns (TipJar) {
        // Starts recording real transactions to broadcast to network.
        vm.startBroadcast();
        TipJar tipJar = new TipJar();
        vm.stopBroadcast();

        console2.log("TipJar deployed to:", address(tipJar));
        console2.log("Owner is: ", tipJar.owner());

        return tipJar;
    }
}
