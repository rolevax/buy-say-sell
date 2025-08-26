// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {BuySaySell} from "../src/BuySaySell.sol";

contract BuySaySellTest is Test {
    BuySaySell public bss;

    address USER1 = makeAddr("alice");
    address USER2 = makeAddr("bob");
    uint256 USER_BALANCE = 1 ether;

    function setUp() public {
        bss = new BuySaySell();
        deal(USER1, USER_BALANCE);
        deal(USER2, USER_BALANCE);
    }

    function test_createStory() public {
        vm.prank(USER1);

        bss.createStory("aaa", 114514);
        BuySaySell.Story[] memory stories = bss.getStories(0, 10);
        assertEq(stories.length, 1);

        BuySaySell.Story memory s = stories[0];
        assertEq(s.owner, USER1);
        assertEq(s.sellPrice, 114514);
        assertEq(s.comments[0].content, "aaa");
        assertEq(s.comments[0].owner, USER1);
    }

    function test_changeSellPrice() public {
        vm.startPrank(USER1);

        bss.createStory("aaa", 1);
        bss.changeSellPrice(0, 123);

        vm.stopPrank();

        BuySaySell.Story memory s = bss.getStory(0);
        assertEq(s.sellPrice, 123);
    }

    function test_agreeSell() public {
        vm.prank(USER1);
        bss.createStory("aaa", 123);

        vm.prank(USER2);
        uint256 user1Balance1 = USER1.balance;
        bss.agreeSellPrice{value: 123}(0);
        uint256 user1Balance2 = USER1.balance;

        BuySaySell.Story memory s = bss.getStory(0);
        assertEq(s.owner, USER2);
        assertEq(s.sellPrice, 0);
        assertEq(user1Balance2 - user1Balance1, 123);
    }

    function test_addComment() public {
        test_agreeSell();

        vm.prank(USER2);
        bss.addComment(0, "bbb", 114514);

        BuySaySell.Story memory s = bss.getStory(0);
        assertEq(s.sellPrice, 114514);
        assertEq(s.comments[2].content, "bbb");
        assertEq(s.comments[2].owner, USER2);
    }
}
