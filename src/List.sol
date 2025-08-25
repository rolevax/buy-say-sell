// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

library List {
    uint256 constant nullIndex = type(uint256).max;

    struct Entry {
        uint256 head;
        Node[] nodes;
    }

    struct Node {
        uint256 prev;
        uint256 next;
    }

    function init(Entry storage entry) public {
        entry.head = nullIndex;
    }

    function insertHead(Entry storage entry) public {
        entry.nodes.push(Node({prev: nullIndex, next: entry.head}));

        if (entry.head != nullIndex) {
            entry.nodes[entry.head].prev = entry.nodes.length - 1;
        }

        entry.head = entry.nodes.length - 1;
    }

    function moveToHead(Entry storage entry, uint256 index) public {
        if (index == entry.head) {
            return;
        }

        uint256 prev = entry.nodes[index].prev;
        uint256 next = entry.nodes[index].next;

        if (prev != nullIndex) {
            entry.nodes[prev].next = next;
        }

        if (next != nullIndex) {
            entry.nodes[next].prev = prev;
        }

        entry.nodes[index].prev = nullIndex;
        entry.nodes[index].next = entry.head;
        entry.head = index;
    }

    function remove(Entry storage entry, uint256 index) public {
        uint256 prev = entry.nodes[index].prev;
        uint256 next = entry.nodes[index].next;

        if (prev != nullIndex) {
            entry.nodes[prev].next = next;
        }

        if (next != nullIndex) {
            entry.nodes[next].prev = prev;
        }

        entry.nodes[index].prev = nullIndex;
        entry.nodes[index].next = nullIndex;
        if (index == entry.head) {
            entry.head = next;
        }
    }

    function get(
        Entry storage entry,
        uint256 begin,
        uint256 size
    ) public view returns (uint256[] memory, uint256) {
        uint256 index = entry.head;
        uint256[] memory result = new uint256[](size);

        for (uint256 i = 0; i < begin && index != nullIndex; i++) {
            index = entry.nodes[index].next;
        }

        uint256 j = 0;
        for (; j < size && index != nullIndex; j++) {
            result[j] = index;
            index = entry.nodes[index].next;
        }

        return (result, j);
    }
}
