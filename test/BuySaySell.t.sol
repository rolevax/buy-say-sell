// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {BuySaySell} from "../src/BuySaySell.sol";

contract BuySaySellTest is Test {
    BuySaySell public bss;

    function setUp() public {
        bss = new BuySaySell();
    }

    function test_createStory() public {
        bss.createStory("PHP is the best programming language in the world!");
        // assertEq(bss.(), 1);
    }
}
