// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {List} from "../src/List.sol";

contract ListTest is Test {
    List.Entry list;

    function setUp() public {
        List.init(list);
    }

    function test_empty() public view {
        (, uint256 size) = List.get(list, 0, 10);

        assertEq(size, 0);
    }

    function test_insertHead() public {
        List.insertHead(list);
        (uint256[] memory res, uint256 size) = List.get(list, 0, 10);

        assertEq(size, 1);
        assertEq(res[0], 0);

        List.insertHead(list);
        (res, size) = List.get(list, 0, 10);

        assertEq(size, 2);
        assertEq(res[0], 1);
        assertEq(res[1], 0);

        List.insertHead(list);
        (res, size) = List.get(list, 0, 10);

        assertEq(size, 3);
        assertEq(res[0], 2);
        assertEq(res[1], 1);
        assertEq(res[2], 0);
    }

    modifier initData(uint256 size) {
        for (uint256 i = 0; i < size; i++) {
            List.insertHead(list);
        }

        _;
    }

    function test_moveToHead() public initData(3) {
        // [2, 1, 0]

        List.moveToHead(list, 1);
        (uint256[] memory res, uint256 size) = List.get(list, 0, 10);

        // [1, 2, 0]
        assertEq(size, 3);
        assertEq(res[0], 1);
        assertEq(res[1], 2);
        assertEq(res[2], 0);

        List.moveToHead(list, 0);
        (res, size) = List.get(list, 0, 10);

        // [0, 1, 2]
        assertEq(size, 3);
        assertEq(res[0], 0);
        assertEq(res[1], 1);
        assertEq(res[2], 2);

        List.moveToHead(list, 0);
        (res, size) = List.get(list, 0, 10);

        // still [0, 1, 2]
        assertEq(size, 3);
        assertEq(res[0], 0);
        assertEq(res[1], 1);
        assertEq(res[2], 2);
    }

    function test_remove() public initData(5) {
        // [4, 3, 2, 1, 0]

        List.remove(list, 2);
        (uint256[] memory res, uint256 size) = List.get(list, 0, 10);

        // [4, 3, 1, 0]
        assertEq(size, 4);
        assertEq(res[0], 4);
        assertEq(res[1], 3);
        assertEq(res[2], 1);
        assertEq(res[3], 0);

        List.remove(list, 4);
        (res, size) = List.get(list, 0, 10);

        // [3, 1, 0]
        assertEq(size, 3);
        assertEq(res[0], 3);
        assertEq(res[1], 1);
        assertEq(res[2], 0);

        List.remove(list, 0);
        (res, size) = List.get(list, 0, 10);

        // [3, 1]
        assertEq(size, 2);
        assertEq(res[0], 3);
        assertEq(res[1], 1);

        List.moveToHead(list, 0);
        (res, size) = List.get(list, 0, 10);

        // [0, 3, 1]
        assertEq(size, 3);
        assertEq(res[0], 0);
        assertEq(res[1], 3);
        assertEq(res[2], 1);
    }

    function test_get() public initData(10) {
        (uint256[] memory res, uint256 size) = List.get(list, 3, 2);

        // [0, 3, 1]
        assertEq(size, 2);
        assertEq(res[0], 6);
        assertEq(res[1], 5);

        (res, size) = List.get(list, 10, 20);
        assertEq(size, 0);

        (res, size) = List.get(list, 5, 0);
        assertEq(size, 0);
    }

    function test_complex() public {
        List.insertHead(list);
        List.insertHead(list);
        List.moveToHead(list, 0);

        // [0, 1]
        (uint256[] memory res, uint256 size) = List.get(list, 0, 10);
        assertEq(size, 2, "a");
        assertEq(res[0], 0, "a");
        assertEq(res[1], 1, "a");

        List.remove(list, 1);

        // [0]
        (res, size) = List.get(list, 0, 10);
        assertEq(size, 1, "b");
        assertEq(res[0], 0, "b");

        List.moveToHead(list, 1);

        // [1, 0]
        (res, size) = List.get(list, 0, 10);
        assertEq(size, 2, "c");
        assertEq(res[0], 1, "c");
        assertEq(res[1], 0, "c");

        List.insertHead(list);

        // [2, 1, 0]
        (res, size) = List.get(list, 0, 10);
        assertEq(size, 3, "d");
        assertEq(res[0], 2, "d");
        assertEq(res[1], 1, "d");
        assertEq(res[2], 0, "d");
    }
}
