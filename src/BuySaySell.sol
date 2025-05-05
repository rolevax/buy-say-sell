// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

contract BuySaySell {
    Story[] private s_stories;

    struct Comment {
        address owner;
        string content;
    }

    struct Story {
        uint256 index;
        address owner;
        Comment[] comments;
    }

    function createStory(string memory content) public {
        Story storage story = s_stories.push();

        story.index = s_stories.length;
        story.owner = msg.sender;

        story.comments.push(Comment({
            owner: msg.sender,
            content: content
        }));
    }

    function getStories() public view returns(Story[] memory) {
        return s_stories;
    }
}
