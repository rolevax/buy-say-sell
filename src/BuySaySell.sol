// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {IERC721Errors} from "openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol";
import {IERC721Metadata} from "openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {IERC165} from "openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {List} from "./List.sol";

contract BuySaySell is
    Ownable2Step,
    IERC165,
    IERC721,
    IERC721Metadata,
    IERC721Errors
{
    using Strings for uint256;

    error PriceError();
    error TransferError();
    error NotSupportedError();

    struct Comment {
        address owner;
        string content;
        uint256 price;
        uint256 timestamp;
        bool isLog;
    }

    struct Story {
        uint256 index;
        address owner;
        uint256 sellPrice;
        Comment[] comments;
    }

    // Array of all stories
    Story[] private _stories;

    // Linked list of stories in the market
    List.Entry private _list;

    // Stories owned by each user
    mapping(address owner => uint256[]) private _balances;

    constructor() Ownable(msg.sender) {
        List.init(_list);
    }

    // Create a new story
    function create(string memory content, uint256 price) public {
        // Checks

        // Effects

        Story storage story = _stories.push();

        story.index = _stories.length - 1;
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

        List.insertHead(_list);
        _balances[story.owner].push(story.index);

        // Interactions
    }

    // ADd comment to a story and set its listing price
    function addComment(
        uint256 index,
        string memory content,
        uint256 price
    ) public {
        // Checks

        if (index >= _stories.length) {
            revert ERC721NonexistentToken(index);
        }

        Story storage story = _stories[index];
        if (story.owner != msg.sender) {
            revert ERC721InvalidSender(msg.sender);
        }

        // Effects

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
            List.moveToHead(_list, index);
        }

        // Interactions
    }

    // Change listing price of a story
    function changePrice(uint256 storyIndex, uint256 price) public {
        // Checks

        if (storyIndex >= _stories.length) {
            revert ERC721NonexistentToken(storyIndex);
        }

        Story storage story = _stories[storyIndex];
        if (story.owner != msg.sender) {
            revert ERC721InvalidSender(msg.sender);
        }

        // Effects

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
            List.remove(_list, storyIndex);
        } else {
            List.moveToHead(_list, storyIndex);
        }

        // Interactions
    }

    // Buy a listed story
    function buy(uint256 storyIndex) public payable {
        // Checks

        if (storyIndex >= _stories.length) {
            revert ERC721NonexistentToken(storyIndex);
        }

        Story storage story = _stories[storyIndex];
        address prevOwner = story.owner;
        if (prevOwner == msg.sender) {
            revert ERC721InvalidSender(msg.sender);
        }

        uint256 price = story.sellPrice;
        uint256 fee = (price * 5) / 10000;
        if (price == 0 || msg.value != price + fee) {
            revert PriceError();
        }

        // Effects

        _transfer(story, msg.sender);
        story.comments.push(
            Comment({
                owner: msg.sender,
                content: "buy",
                price: price,
                timestamp: block.timestamp,
                isLog: true
            })
        );

        // Interactions

        (bool sent, ) = prevOwner.call{value: price}("");
        if (!sent) {
            revert TransferError();
        }
    }

    function _transfer(Story storage story, address to) private {
        address from = story.owner;
        uint256 index = story.index;

        story.sellPrice = 0;
        story.owner = to;

        List.remove(_list, index);

        _balances[to].push(index);
        uint256[] storage prevList = _balances[from];
        uint256 prevTotal = prevList.length;
        for (uint256 i = 0; i < prevTotal; i++) {
            if (prevList[i] == index) {
                prevList[i] = prevList[prevTotal - 1];
                prevList.pop();
                break;
            }
        }

        emit Transfer(from, to, index);
    }

    // Get paged stories in the market
    function getStories(
        uint256 offset,
        uint256 length
    ) public view returns (Story[] memory data, uint256 total) {
        (uint256[] memory indices, uint256 size) = List.get(
            _list,
            offset,
            length
        );

        Story[] memory result = new Story[](size);
        for (uint256 i = 0; i < size; i++) {
            result[i] = _stories[indices[i]];
        }

        return (result, _list.size);
    }

    // Get one story by index
    function getStory(uint256 index) public view returns (Story memory) {
        if (index >= _stories.length) {
            revert ERC721NonexistentToken(index);
        }

        return _stories[index];
    }

    // Get paged stories owned by a user
    function getBalance(
        address owner,
        uint256 offset,
        uint256 length
    ) public view returns (Story[] memory data, uint256 total) {
        uint256[] storage list = _balances[owner];

        total = list.length;
        data = new Story[](total - offset > length ? length : total - offset);

        for (uint256 i = 0; i < length && i + offset < total; i++) {
            data[i] = _stories[list[i + offset]];
        }
    }

    // ERC-165
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId;
    }

    // ERC-721 metadata
    function name() external pure override returns (string memory) {
        return "Buy Say Sell";
    }

    // ERC-721 metadata
    function symbol() external pure override returns (string memory) {
        return "BSS";
    }

    // ERC-721 metadata
    function tokenURI(
        uint256 tokenId
    ) external pure override returns (string memory) {
        bytes memory data = abi.encodePacked(
            "{",
            '"name": "Buy Say Sell #',
            tokenId.toString(),
            '"',
            "}"
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(data)
                )
            );
    }

    // ERC-721
    function balanceOf(
        address owner
    ) external view override returns (uint256 balance) {
        return _balances[owner].length;
    }

    // ERC-721
    function ownerOf(
        uint256 tokenId
    ) external view override returns (address owner) {
        if (tokenId >= _stories.length) {
            revert ERC721NonexistentToken(tokenId);
        }

        return _stories[tokenId].owner;
    }

    // ERC-721
    // Override ERC-721 interface to display in wallets or market apps
    // Not actually implementing for avoiding risks
    function transferFrom(address, address, uint256) public pure override {
        revert NotSupportedError();
    }

    // ERC-721
    function safeTransferFrom(
        address,
        address,
        uint256,
        bytes memory
    ) public pure override {
        revert NotSupportedError();
    }

    // ERC-721
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external pure override {
        safeTransferFrom(from, to, tokenId, "");
    }

    // ERC-721
    function approve(address, uint256) external pure override {
        revert NotSupportedError();
    }

    // ERC-721
    function setApprovalForAll(address, bool) external pure override {
        revert NotSupportedError();
    }

    // ERC-721
    function getApproved(
        uint256
    ) public pure override returns (address operator) {
        return address(0);
    }

    // ERC-721
    function isApprovedForAll(
        address,
        address
    ) public pure override returns (bool) {
        return false;
    }

    // Withdraw
    function ensureBestExperience() external onlyOwner {
        (bool sent, ) = payable(msg.sender).call{value: address(this).balance}(
            ""
        );
        if (!sent) {
            revert TransferError();
        }
    }
}
