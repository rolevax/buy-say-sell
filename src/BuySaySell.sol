// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {IERC721Errors} from "openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol";
import {ERC721Utils} from "openzeppelin-contracts/contracts/token/ERC721/utils/ERC721Utils.sol";
import {IERC721Metadata} from "openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {IERC165} from "openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {List} from "./List.sol";

contract BuySaySell is IERC165, IERC721, IERC721Metadata, IERC721Errors {
    using Strings for uint256;

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

    error PriceError();
    error TransferError();

    struct Story {
        uint256 index;
        address owner;
        uint256 sellPrice;
        Comment[] comments;
    }

    constructor() {
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

        // _safeMint(story.owner, story.index);

        List.insertHead(sList);
        sBalances[story.owner].push(story.index);
    }

    function addComment(
        uint256 storyIndex,
        string memory content,
        uint256 price
    ) public {
        if (storyIndex >= sStories.length) {
            revert ERC721NonexistentToken(storyIndex);
        }

        Story storage story = sStories[storyIndex];
        if (story.owner != msg.sender) {
            revert ERC721InvalidSender(msg.sender);
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
            revert ERC721NonexistentToken(storyIndex);
        }

        Story storage story = sStories[storyIndex];
        if (story.owner != msg.sender) {
            revert ERC721InvalidSender(msg.sender);
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
            revert ERC721NonexistentToken(storyIndex);
        }

        Story storage story = sStories[storyIndex];
        address prevOwner = story.owner;
        if (prevOwner == msg.sender) {
            revert ERC721InvalidSender(msg.sender);
        }

        uint256 price = story.sellPrice;
        if (price == 0 || msg.value != price) {
            revert PriceError();
        }

        (bool sent, ) = prevOwner.call{value: price}("");
        if (!sent) {
            revert TransferError();
        }

        doTransfer(story, msg.sender);
        story.comments.push(
            Comment({
                owner: msg.sender,
                content: "buy",
                price: price,
                timestamp: block.timestamp,
                isLog: true
            })
        );
    }

    function doTransfer(Story storage story, address to) private {
        address from = story.owner;

        story.sellPrice = 0;
        story.owner = to;

        List.remove(sList, story.index);

        sBalances[to].push(story.index);
        uint256[] storage prevList = sBalances[from];
        for (uint256 i = 0; i < prevList.length; i++) {
            if (prevList[i] == story.index) {
                prevList[i] = prevList[prevList.length - 1];
                prevList.pop();
                break;
            }
        }

        emit Transfer(from, to, story.index);
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
            revert ERC721NonexistentToken(index);
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

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId;
    }

    function name() external pure override returns (string memory) {
        return "Buy Say Sell";
    }

    function symbol() external pure override returns (string memory) {
        return "BSS";
    }

    function tokenURI(
        uint256 tokenId
    ) external pure override returns (string memory) {
        return tokenId.toString();
    }

    function balanceOf(
        address owner
    ) external view override returns (uint256 balance) {
        return sBalances[owner].length;
    }

    function ownerOf(
        uint256 tokenId
    ) external view override returns (address owner) {
        if (tokenId >= sStories.length) {
            revert ERC721NonexistentToken(tokenId);
        }

        return sStories[tokenId].owner;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        if (to == address(0)) {
            revert ERC721InvalidReceiver(address(0));
        }

        if (tokenId >= sStories.length) {
            revert ERC721NonexistentToken(tokenId);
        }

        Story storage story = sStories[tokenId];
        if (story.owner != from) {
            revert ERC721IncorrectOwner(from, tokenId, story.owner);
        }

        address spender = msg.sender;
        bool isAuth = from == spender ||
            isApprovedForAll(from, spender) ||
            getApproved(story.index) == spender;
        if (!isAuth) {
            revert ERC721InsufficientApproval(spender, story.index);
        }

        doTransfer(story, to);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override {
        transferFrom(from, to, tokenId);
        ERC721Utils.checkOnERC721Received(msg.sender, from, to, tokenId, data);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function approve(address to, uint256 tokenId) external override {}

    function setApprovalForAll(
        address operator,
        bool approved
    ) external override {}

    function getApproved(
        uint256 tokenId
    ) public view override returns (address operator) {}

    function isApprovedForAll(
        address owner,
        address operator
    ) public view override returns (bool) {}
}
