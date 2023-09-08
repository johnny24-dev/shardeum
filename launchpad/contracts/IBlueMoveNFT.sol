// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.19;

interface IBlueMoveNFT {
    function safeMint(address to, uint256 tokenId, string memory uri) external;
}