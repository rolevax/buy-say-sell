// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {BuySaySell} from "../src/BuySaySell.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract MoreDataScript is Script {
    BuySaySell public bss;

    // Anvil users
    uint256 KEY0 =
        0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    function setUp() public {}

    function run() public {
        vm.startBroadcast(KEY0);
        bss = new BuySaySell();
        vm.stopBroadcast();

        vm.startBroadcast(KEY0);

        for (uint256 i = 0; i < 100; i++) {
            bss.createStory(
                string.concat("anvil test post ", Strings.toString(i)),
                0.002 ether
            );
        }

        vm.stopBroadcast();
    }
}
