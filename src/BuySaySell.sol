// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {List} from "./List.sol";

contract BuySaySell is ERC721 {
    Story[] private sStories;
    List.Entry private sList;
    mapping(address owner => uint256[]) private sBalances;

    struct Comment {
        address owner;
        string content;
        uint256 price;
        uint256 timestamp;
        bool isLog;
    }

    error UserArgError();
    error OwnerError();
    error PriceError();
    error TransferError();

    struct Story {
        uint256 index;
        address owner;
        uint256 sellPrice;
        Comment[] comments;
    }

    constructor() ERC721("Buy Say Sell", "BSS") {
        List.init(sList);
    }

    function createStory(string memory content, uint256 price) public {
        Story storage story = sStories.push();

        story.index = sStories.length - 1;
        story.owner = msg.sender;
        story.sellPrice = price;

        story.comments.push(
            Comment({
                owner: msg.sender,
                content: content,
                price: price,
                timestamp: block.timestamp,
                isLog: false
            })
        );

        _safeMint(story.owner, story.index);

        List.insertHead(sList);
        sBalances[story.owner].push(story.index);
    }

    function addComment(
        uint256 storyIndex,
        string memory content,
        uint256 price
    ) public {
        if (storyIndex >= sStories.length) {
            revert UserArgError();
        }

        Story storage story = sStories[storyIndex];
        if (story.owner != msg.sender) {
            revert OwnerError();
        }

        story.comments.push(
            Comment({
                owner: msg.sender,
                content: content,
                price: price,
                timestamp: block.timestamp,
                isLog: false
            })
        );
        story.sellPrice = price;

        if (price > 0) {
            List.moveToHead(sList, storyIndex);
        }
    }

    function changeSellPrice(uint256 storyIndex, uint256 price) public {
        if (storyIndex >= sStories.length) {
            revert UserArgError();
        }

        Story storage story = sStories[storyIndex];
        if (story.owner != msg.sender) {
            revert OwnerError();
        }

        story.sellPrice = price;
        story.comments.push(
            Comment({
                owner: msg.sender,
                content: "change-price",
                price: price,
                timestamp: block.timestamp,
                isLog: true
            })
        );

        if (price == 0) {
            List.remove(sList, storyIndex);
        } else {
            List.moveToHead(sList, storyIndex);
        }
    }

    function agreeSellPrice(uint256 storyIndex) public payable {
        if (storyIndex >= sStories.length) {
            revert UserArgError();
        }

        Story storage story = sStories[storyIndex];
        address prevOwner = story.owner;
        if (prevOwner == msg.sender) {
            revert OwnerError();
        }

        uint256 price = story.sellPrice;
        if (price == 0 || msg.value != price) {
            revert PriceError();
        }

        (bool sent, ) = prevOwner.call{value: price}("");
        if (!sent) {
            revert TransferError();
        }

        story.sellPrice = 0;
        story.owner = msg.sender;
        story.comments.push(
            Comment({
                owner: msg.sender,
                content: "buy",
                price: price,
                timestamp: block.timestamp,
                isLog: true
            })
        );

        _safeTransfer(prevOwner, story.owner, story.index);

        List.remove(sList, storyIndex);

        sBalances[story.owner].push(storyIndex);
        uint256[] storage prevList = sBalances[prevOwner];
        for (uint256 i = 0; i < prevList.length; i++) {
            if (prevList[i] == storyIndex) {
                prevList[i] = prevList[prevList.length - 1];
                prevList.pop();
                break;
            }
        }
    }

    function getStories(
        uint256 offset,
        uint256 length
    ) public view returns (Story[] memory data, uint256 total) {
        (uint256[] memory indices, uint256 size) = List.get(
            sList,
            offset,
            length
        );

        Story[] memory result = new Story[](size);
        for (uint256 i = 0; i < size; i++) {
            result[i] = sStories[indices[i]];
        }

        return (result, sList.size);
    }

    function getStory(uint256 index) public view returns (Story memory) {
        if (index >= sStories.length) {
            revert UserArgError();
        }

        return sStories[index];
    }

    function getBalance(
        address owner,
        uint256 offset,
        uint256 length
    ) public view returns (Story[] memory data, uint256 total) {
        uint256[] storage list = sBalances[owner];
        Story[] memory result = new Story[](
            list.length - offset > length ? length : list.length - offset
        );

        for (uint256 i = 0; i < length && i + offset < list.length; i++) {
            result[i] = sStories[list[i + offset]];
        }

        return (result, list.length);
    }
}
