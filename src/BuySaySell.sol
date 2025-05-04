// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

contract BuySaySell {
    uint256 private s_nextID;
    Story[] private s_stories;

    struct Story {
        uint256 id;
        string[] contents;
    }

    function createStory(string memory content) public {
        Story memory story;
        story.id = s_nextID++;
        story.contents = new string[](1);
        story.contents[0] = content;

        s_stories.push(story);
    }
}
