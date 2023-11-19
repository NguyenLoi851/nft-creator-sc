// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

contract Collection is ERC721Upgradeable {
    string private _baseTokenURI;

    function initialize(
        string memory name_,
        string memory symbol_,
        string memory baseURI_
    ) external initializer{
        __ERC721_init_unchained(name_, symbol_);
        setBaseURI(baseURI_);
    }

    function setBaseURI(string memory newBaseTokenURI) public {
        _baseTokenURI = newBaseTokenURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function mint(address owner, uint tokenId) public {
        _mint(owner, tokenId);
    }
}
