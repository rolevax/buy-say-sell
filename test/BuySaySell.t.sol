// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {BuySaySell} from "../src/BuySaySell.sol";

contract BuySaySellTest is Test {
    BuySaySell public bss;

    address USER = makeAddr("alice");

    function setUp() public {
        bss = new BuySaySell();
    }

    function test_createStory() public {
        vm.prank(USER);

        bss.createStory("aaa");
        BuySaySell.Story[] memory stories = bss.getStories();
        assertEq(stories.length, 1);

        BuySaySell.Story memory s = stories[0];
        assertEq(s.owner, USER);
        assertEq(s.comments[0].content, "aaa");
        assertEq(s.comments[0].owner, USER);
    }
}
