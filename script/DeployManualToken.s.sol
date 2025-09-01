//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {ManualToken} from "../src/ManualToken.sol";

contract DeployManualToken is Script {
    function run() external returns (ManualToken) {
        vm.startBroadcast();
        ManualToken manualToken = new ManualToken("Prash", "PJ", 1000);
        vm.stopBroadcast();
        return manualToken;
    }
}
