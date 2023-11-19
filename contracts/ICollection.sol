// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface ICollection {
    function initialize(
        string memory name_,
        string memory symbol_,
        string memory baseURI_
    ) external;

    function mint(address owner, uint tokenId) external;
}
