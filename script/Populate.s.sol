// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {BuySaySell} from "../src/BuySaySell.sol";

contract PopulateScript is Script {
    BuySaySell public bss;

    // Anvil users
    uint256 constant KEY0 =
        0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    uint256 constant KEY1 =
        0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;
    uint256 constant KEY2 =
        0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a;

    function setUp() public {}

    function run() public {
        vm.startBroadcast(KEY0);
        bss = new BuySaySell();
        vm.stopBroadcast();

        vm.startBroadcast(KEY0);
        bss.create("anvil test post 0, owned", 0.002 ether);
        bss.create("anvil test post 1, not selling", 0.002 ether);
        bss.addComment(0, "comment 1", 0.002 ether);
        vm.stopBroadcast();

        vm.startBroadcast(KEY1);
        bss.buy{value: 0.002 ether + (0.002 ether * 5) / 10000}(1);
        bss.addComment(1, "comment by buyer", 0);
        bss.create("anvil test post 2, selling", 0.003 ether);
        vm.stopBroadcast();
    }
}
