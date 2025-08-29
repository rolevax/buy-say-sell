// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

library List {
    uint256 constant NULL_INDEX = type(uint256).max;

    struct Entry {
        uint256 head;
        uint256 size;
        Node[] nodes;
    }

    struct Node {
        uint256 prev;
        uint256 next;
    }

    function init(Entry storage entry) public {
        entry.head = NULL_INDEX;
    }

    function insertHead(Entry storage entry) public {
        entry.nodes.push(Node({prev: NULL_INDEX, next: entry.head}));

        if (entry.head != NULL_INDEX) {
            entry.nodes[entry.head].prev = entry.nodes.length - 1;
        }

        entry.head = entry.nodes.length - 1;
        entry.size++;
    }

    function moveToHead(Entry storage entry, uint256 index) public {
        if (index == entry.head) {
            return;
        }

        uint256 prev = entry.nodes[index].prev;
        uint256 next = entry.nodes[index].next;

        if (prev != NULL_INDEX) {
            entry.nodes[prev].next = next;
        }

        if (next != NULL_INDEX) {
            entry.nodes[next].prev = prev;
        }

        entry.nodes[index].prev = NULL_INDEX;
        entry.nodes[index].next = entry.head;
        if (entry.head != NULL_INDEX) {
            entry.nodes[entry.head].prev = index;
        }

        entry.head = index;
        if (prev == NULL_INDEX && next == NULL_INDEX) {
            entry.size++;
        }
    }

    function remove(Entry storage entry, uint256 index) public {
        uint256 prev = entry.nodes[index].prev;
        uint256 next = entry.nodes[index].next;

        if (prev != NULL_INDEX) {
            entry.nodes[prev].next = next;
        }

        if (next != NULL_INDEX) {
            entry.nodes[next].prev = prev;
        }

        entry.nodes[index].prev = NULL_INDEX;
        entry.nodes[index].next = NULL_INDEX;
        if (index == entry.head) {
            entry.head = next;
        }

        entry.size--;
    }

    function get(
        Entry storage entry,
        uint256 begin,
        uint256 size
    ) public view returns (uint256[] memory, uint256) {
        uint256 index = entry.head;
        uint256[] memory result = new uint256[](size);

        for (uint256 i = 0; i < begin && index != NULL_INDEX; i++) {
            index = entry.nodes[index].next;
        }

        uint256 j = 0;
        for (; j < size && index != NULL_INDEX; j++) {
            result[j] = index;
            index = entry.nodes[index].next;
        }

        return (result, j);
    }
}
