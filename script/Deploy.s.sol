// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {BuySaySell} from "../src/BuySaySell.sol";

contract DeployScript is Script {
    BuySaySell public bss;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        bss = new BuySaySell();

        vm.stopBroadcast();
    }
}
