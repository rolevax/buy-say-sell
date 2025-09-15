// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {BuySaySell} from "../src/BuySaySell.sol";

contract BuySaySellTest is Test {
    BuySaySell public bss;

    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address carol = makeAddr("carol");
    uint256 constant USER_BALANCE = 1 ether;

    function setUp() public {
        bss = new BuySaySell();
        deal(alice, USER_BALANCE);
        deal(bob, USER_BALANCE);
        deal(carol, USER_BALANCE);
    }

    function test_createStory() public {
        vm.prank(alice);

        bss.createStory("aaa", 114514);
        (BuySaySell.Story[] memory stories, uint256 total) = bss.getStories(
            0,
            10
        );
        assertEq(stories.length, 1);
        assertEq(total, 1);

        BuySaySell.Story memory s = stories[0];
        assertEq(s.owner, alice);
        assertEq(s.sellPrice, 114514);
        assertEq(s.comments[0].content, "aaa");
        assertEq(s.comments[0].owner, alice);

        (stories, total) = bss.getBalance(alice, 0, 10);
        assertEq(stories.length, 1);
        assertEq(total, 1);
    }

    function test_changeSellPrice() public {
        vm.startPrank(alice);

        bss.createStory("aaa", 1);
        bss.changeSellPrice(0, 123);

        vm.stopPrank();

        BuySaySell.Story memory s = bss.getStory(0);
        assertEq(s.sellPrice, 123);
    }

    function test_agreeSell() public {
        uint256 price = 1230000;

        vm.prank(alice);
        bss.createStory("aaa", price);

        vm.prank(bob);
        uint256 user1Balance1 = alice.balance;
        bss.agreeSellPrice{value: price + (price * 5) / 10000}(0);
        uint256 user1Balance2 = alice.balance;

        BuySaySell.Story memory s = bss.getStory(0);
        assertEq(s.owner, bob);
        assertEq(s.sellPrice, 0);
        assertEq(user1Balance2 - user1Balance1, price);

        (BuySaySell.Story[] memory stories, uint256 total) = bss.getBalance(
            alice,
            0,
            10
        );
        assertEq(stories.length, 0);
        assertEq(total, 0);
        (stories, total) = bss.getBalance(bob, 0, 10);
        assertEq(stories.length, 1);
        assertEq(total, 1);
    }

    function test_addComment() public {
        test_agreeSell();

        vm.prank(bob);
        bss.addComment(0, "bbb", 114514);

        BuySaySell.Story memory s = bss.getStory(0);
        assertEq(s.sellPrice, 114514);
        assertEq(s.comments[2].content, "bbb");
        assertEq(s.comments[2].owner, bob);
    }

    function test_transfer() public {
        vm.prank(alice);
        vm.expectRevert();
        bss.transferFrom(alice, bob, 0);
    }

    function test_approval() public {
        vm.prank(alice);
        vm.expectRevert();
        bss.transferFrom(alice, bob, 0);
    }

    function test_approvalAll() public {
        vm.prank(alice);
        vm.expectRevert();
        bss.transferFrom(alice, bob, 0);
    }
}
