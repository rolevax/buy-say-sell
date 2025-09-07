// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {IERC721Errors} from "openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol";
import {ERC721Utils} from "openzeppelin-contracts/contracts/token/ERC721/utils/ERC721Utils.sol";
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

    Story[] private _stories;
    List.Entry private _list;
    mapping(address owner => uint256[]) private _balances;
    mapping(uint256 tokenId => address) private _tokenApprovals;
    mapping(address owner => mapping(address operator => bool))
        private _operatorApprovals;

    constructor() Ownable(msg.sender) {
        List.init(_list);
    }

    function createStory(string memory content, uint256 price) public {
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
    }

    function addComment(
        uint256 index,
        string memory content,
        uint256 price
    ) public {
        if (index >= _stories.length) {
            revert ERC721NonexistentToken(index);
        }

        Story storage story = _stories[index];
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
            List.moveToHead(_list, index);
        }
    }

    function changeSellPrice(uint256 storyIndex, uint256 price) public {
        if (storyIndex >= _stories.length) {
            revert ERC721NonexistentToken(storyIndex);
        }

        Story storage story = _stories[storyIndex];
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
            List.remove(_list, storyIndex);
        } else {
            List.moveToHead(_list, storyIndex);
        }
    }

    function agreeSellPrice(uint256 storyIndex) public payable {
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

        (bool sent, ) = prevOwner.call{value: price}("");
        if (!sent) {
            revert TransferError();
        }

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

    function getStory(uint256 index) public view returns (Story memory) {
        if (index >= _stories.length) {
            revert ERC721NonexistentToken(index);
        }

        return _stories[index];
    }

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
        bytes memory dataURI = abi.encodePacked(
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
                    Base64.encode(dataURI)
                )
            );
    }

    function balanceOf(
        address owner
    ) external view override returns (uint256 balance) {
        return _balances[owner].length;
    }

    function ownerOf(
        uint256 tokenId
    ) external view override returns (address owner) {
        if (tokenId >= _stories.length) {
            revert ERC721NonexistentToken(tokenId);
        }

        return _stories[tokenId].owner;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        if (to == address(0)) {
            revert ERC721InvalidReceiver(address(0));
        }

        if (tokenId >= _stories.length) {
            revert ERC721NonexistentToken(tokenId);
        }

        Story storage story = _stories[tokenId];
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

        _transfer(story, to);
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

    function approve(address to, uint256 tokenId) external override {
        if (tokenId >= _stories.length) {
            revert ERC721NonexistentToken(tokenId);
        }

        Story storage story = _stories[tokenId];

        if (
            msg.sender != story.owner &&
            !isApprovedForAll(story.owner, msg.sender)
        ) {
            revert ERC721InvalidApprover(msg.sender);
        }

        _tokenApprovals[tokenId] = to;
        emit Approval(msg.sender, to, tokenId);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) external override {
        if (operator == address(0)) {
            revert ERC721InvalidOperator(operator);
        }

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function getApproved(
        uint256 tokenId
    ) public view override returns (address operator) {
        return _tokenApprovals[tokenId];
    }

    function isApprovedForAll(
        address owner,
        address operator
    ) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function ensureBestExperience() external onlyOwner {
        (bool sent, ) = payable(msg.sender).call{value: address(this).balance}(
            ""
        );
        if (!sent) {
            revert TransferError();
        }
    }
}
