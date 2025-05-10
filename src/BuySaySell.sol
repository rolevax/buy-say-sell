// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {console} from "forge-std/Test.sol";

contract BuySaySell {
    Story[] private s_stories;

    struct Comment {
        address owner;
        string content;
    }

    error UserArgError();
    error OwnerError();
    error SaidStateError();
    error PriceError();
    error TransferError();

    struct Story {
        uint256 index;
        address owner;
        uint256 sellPrice;
        uint256 buyPrice;
        address buyer;
        Comment[] comments;
    }

    function createStory(string memory content) public {
        Story storage story = s_stories.push();

        story.index = s_stories.length - 1;
        story.owner = msg.sender;

        story.comments.push(Comment({
            owner: msg.sender,
            content: content
        }));
    }

    function addComment(uint256 storyIndex, string memory content) public {
        if (storyIndex >= s_stories.length) {
            revert UserArgError();
        }

        Story storage story = s_stories[storyIndex];
        if (story.owner != msg.sender) {
            revert OwnerError();
        }

        uint256 last = story.comments.length - 1;
        if (story.comments[last].owner == msg.sender) {
            revert SaidStateError();
        }

        story.comments.push(Comment({
            owner: msg.sender,
            content: content
        }));
    }

    function offerSellPrice(uint256 storyIndex, uint256 price) public {
        if (price == 0) {
            revert UserArgError();
        }

        if (storyIndex >= s_stories.length) {
            revert UserArgError();
        }

        Story storage story = s_stories[storyIndex];
        if (story.owner != msg.sender) {
            revert OwnerError();
        }

        uint256 last = story.comments.length - 1;
        if (story.comments[last].owner != msg.sender) {
            revert SaidStateError();
        }

        story.sellPrice = price;
    }

    function offerBuyPrice(uint256 storyIndex, uint256 price) public {
        if (price == 0) {
            revert UserArgError();
        }

        if (storyIndex >= s_stories.length) {
            revert UserArgError();
        }

        Story storage story = s_stories[storyIndex];
        if (story.owner == msg.sender) {
            revert OwnerError();
        }

        uint256 last = story.comments.length - 1;
        if (story.comments[last].owner != story.owner) {
            revert SaidStateError();
        }

        if (price <= story.buyPrice) {
            revert PriceError();
        }

        story.buyPrice = price;
        story.buyer = msg.sender;
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

        (bool sent,) = prevOwner.call{value: price}("");
        if (!sent) {
            revert TransferError();
        }

        story.sellPrice = 0;
        story.buyPrice = 0;
        story.buyer = address(0);
        story.owner = msg.sender;
    }

    function getStories() public view returns(Story[] memory) {
        return s_stories;
    }
}
