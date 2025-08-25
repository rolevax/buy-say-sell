// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {console} from "forge-std/Test.sol";
import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "./List.sol";

contract BuySaySell is ERC721 {
    Story[] private s_stories;
    List.Entry private s_list;

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
        List.init(s_list);
    }

    function createStory(string memory content, uint256 price) public {
        Story storage story = s_stories.push();

        story.index = s_stories.length - 1;
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

        List.insertHead(s_list);
    }

    function addComment(
        uint256 storyIndex,
        string memory content,
        uint256 price
    ) public {
        if (storyIndex >= s_stories.length) {
            revert UserArgError();
        }

        Story storage story = s_stories[storyIndex];
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

        List.moveToHead(s_list, storyIndex);
    }

    function changeSellPrice(uint256 storyIndex, uint256 price) public {
        if (storyIndex >= s_stories.length) {
            revert UserArgError();
        }

        Story storage story = s_stories[storyIndex];
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
            List.remove(s_list, storyIndex);
        } else {
            List.moveToHead(s_list, storyIndex);
        }
    }

    function agreeSellPrice(uint256 storyIndex) public payable {
        if (storyIndex >= s_stories.length) {
            revert UserArgError();
        }

        Story storage story = s_stories[storyIndex];
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

        List.remove(s_list, storyIndex);
    }

    function getStories() public view returns (Story[] memory) {
        (uint256[] memory indices, uint256 size) = List.get(s_list, 0, 10);

        Story[] memory result = new Story[](size);
        for (uint256 i = 0; i < size; i++) {
            result[i] = s_stories[indices[i]];
        }

        return result;
    }

    function getStory(uint256 index) public view returns (Story memory) {
        if (index >= s_stories.length) {
            revert UserArgError();
        }

        return s_stories[index];
    }
}
