// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./ICollection.sol";

contract NFTCreatorFactory {
    struct CollectionInfo {
        uint recordId;
        address creator;
        uint voteCount;
        uint voteTotalPower;
        uint price;
        uint nonce;
    }
    mapping(address => CollectionInfo) public collectionInfo;
    mapping(uint256 => address) public recordIdCollection;
    mapping(address => address[]) public creatorCollections;

    address[] public collections;

    address public gameToken;

    address public collectionImpl;

    event CollectionCreated(
        uint recordId,
        address indexed collection,
        address indexed creator
    );

    event VoteCreated(address collection, uint votePower);

    event NFTBought(address collection, address buyer);

    constructor(address _gameToken, address _collectionImpl) {
        gameToken = _gameToken;
        collectionImpl = _collectionImpl;
    }

    function setCollectionImpl(address _collectionImpl) external {
        collectionImpl = _collectionImpl;
    }

    function createCollection(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        uint recordId
    ) external returns (address newCollection) {
        require(
            recordIdCollection[recordId] == address(0),
            "RecordId has already used"
        );

        bytes32 salt = keccak256(
            abi.encode(name, symbol, msg.sender, recordId)
        );

        newCollection = Clones.cloneDeterministic(collectionImpl, salt);
        ICollection(newCollection).initialize(name, symbol, baseTokenURI);

        recordIdCollection[recordId] = newCollection;
        creatorCollections[msg.sender].push(newCollection);
        collectionInfo[newCollection] = CollectionInfo(
            recordId,
            msg.sender,
            0,
            0,
            0,
            0
        );

        collections.push(newCollection);

        emit CollectionCreated(
            recordId,
            newCollection,
            msg.sender
        );

        return newCollection;
    }

    function getAllCollections() external view returns (address[] memory) {
        return collections;
    }

    function getCollectionsByCreator(
        address creator
    ) external view returns (address[] memory) {
        return creatorCollections[creator];
    }

    function getCollectionsLengthByCreator(
        address creator
    ) external view returns (uint) {
        return creatorCollections[creator].length;
    }

    function voteCollection(address collection, uint votePower) external {
        require(votePower >= 1 && votePower <= 5, "Vote power out of range");

        CollectionInfo storage collectionFullInfo = collectionInfo[collection];
        collectionFullInfo.voteCount += 1;
        collectionFullInfo.voteTotalPower += votePower;
        emit VoteCreated(collection, votePower);
    }

    function setPrice(address collection, uint price) external {
        CollectionInfo storage collectionFullInfo = collectionInfo[collection];
        collectionFullInfo.price = price;
    }

    function buyNFT(address collection) external {
        CollectionInfo storage collectionFullInfo = collectionInfo[collection];

        IERC20(gameToken).transferFrom(
            msg.sender,
            collectionFullInfo.creator,
            collectionFullInfo.price
        );
        ICollection(collection).mint(msg.sender, collectionFullInfo.nonce);
        collectionFullInfo.nonce += 1;

        emit NFTBought(collection, msg.sender);
    }
}
