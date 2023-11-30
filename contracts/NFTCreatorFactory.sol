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

    struct CreatorInfo {
        address creator;
        uint totalReward;
        uint voteCount;
        uint voteTotalPower;
        uint claimedAmount;
    }

    mapping(address => CollectionInfo) public collectionInfo;
    mapping(uint256 => address) public recordIdCollection;
    mapping(address => address[]) public creatorCollections;
    mapping(address => mapping(address => bool)) public isBought; // buyer => collection => bool
    mapping(address => address[]) public collectionListBought; // buyer => collections
    mapping(address => CreatorInfo) public creatorInfo;
    mapping(address => bool) public isCreator;
    mapping(address => mapping(uint => uint)) public voteHistory;

    address[] public collections;
    address[] public creators;

    address public gameToken;

    address public collectionImpl;

    uint public totalRewardAmount;

    uint public totalVotingPower;

    event CollectionCreated(
        uint recordId,
        address indexed collection,
        address indexed creator
    );

    event VoteCreated(address collection, uint votePower);

    event NFTBought(address collection, address buyer);

    event RewardClaimed(address creator, uint availableAmount);

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
            1000000,
            0
        );

        collections.push(newCollection);

        creatorInfo[msg.sender] = CreatorInfo(msg.sender, 0, 0, 0, 0);

        if (isCreator[msg.sender] == false) {
            creators.push(msg.sender);
            isCreator[msg.sender] = true;
        }

        emit CollectionCreated(recordId, newCollection, msg.sender);

        return newCollection;
    }

    function getAllCollectionsLength() external view returns (uint) {
        return collections.length;
    }

    function getAllCollections() external view returns (address[] memory) {
        return collections;
    }

    function getAllCreatorsLength() external view returns (uint) {
        return creators.length;
    }

    function getAllCreators() external view returns (address[] memory) {
        return creators;
    }

    function getAllCreatorsFullInfo()
        external
        view
        returns (CreatorInfo[] memory)
    {
        CreatorInfo[] memory creatorsFullInfo = new CreatorInfo[](
            creators.length
        );
        for (uint i = 0; i < creators.length; i++) {
            creatorsFullInfo[i] = creatorInfo[creators[i]];
            creatorsFullInfo[i].totalReward = totalVotingPower == 0
                ? 0
                : ((totalRewardAmount / 2) *
                    creatorInfo[creators[i]].voteTotalPower) / totalVotingPower;
        }
        return creatorsFullInfo;
    }

    function getCollectionsByCreator(
        address creator
    ) public view returns (address[] memory) {
        return creatorCollections[creator];
    }

    function getCollectionsLengthByCreator(
        address creator
    ) public view returns (uint) {
        return creatorCollections[creator].length;
    }

    function getCollectionsFullInfoByCreator(
        address creator
    ) external view returns (CollectionInfo[] memory) {
        address[] memory allCollections = getCollectionsByCreator(creator);
        CollectionInfo[] memory collectionFullInfo = new CollectionInfo[](
            allCollections.length
        );

        for (uint i = 0; i < allCollections.length; i++) {
            collectionFullInfo[i] = collectionInfo[allCollections[i]];
        }

        return collectionFullInfo;
    }

    function voteCollection(address collection, uint votePower) external {
        require(votePower >= 1 && votePower <= 5, "Vote power out of range");
        require(isBought[msg.sender][collection] == true, "Need buy NFT");

        CollectionInfo storage collectionFullInfo = collectionInfo[collection];
        require(
            voteHistory[msg.sender][collectionFullInfo.recordId] == 0,
            "Voted"
        );

        collectionFullInfo.voteCount += 1;
        collectionFullInfo.voteTotalPower += votePower;

        address creator = collectionFullInfo.creator;
        CreatorInfo storage creatorFullInfo = creatorInfo[creator];
        creatorFullInfo.voteCount += 1;
        creatorFullInfo.voteTotalPower += votePower;

        totalVotingPower += votePower;
        voteHistory[msg.sender][collectionFullInfo.recordId] = votePower;

        emit VoteCreated(collection, votePower);
    }

    function buyNFT(address[] memory allCollections) external {
        for (uint i = 0; i < allCollections.length; i++) {
            CollectionInfo storage collectionFullInfo = collectionInfo[
                allCollections[i]
            ];

            CreatorInfo storage creatorFullInfo = creatorInfo[
                collectionFullInfo.creator
            ];

            IERC20(gameToken).transferFrom(
                msg.sender,
                address(this),
                collectionFullInfo.price
            );
            creatorFullInfo.totalReward += collectionFullInfo.price;

            totalRewardAmount += collectionFullInfo.price;

            ICollection(allCollections[i]).mint(
                msg.sender,
                collectionFullInfo.nonce
            );
            collectionFullInfo.nonce += 1;
            isBought[msg.sender][allCollections[i]] = true;
            collectionListBought[msg.sender].push(allCollections[i]);

            emit NFTBought(allCollections[i], msg.sender);
        }
    }

    function getClaimInfo(
        address creator
    ) public view returns (uint, uint, uint) {
        CreatorInfo memory creatorFullInfo = creatorInfo[creator];
        uint totalReward = totalVotingPower == 0
            ? 0
            : ((totalRewardAmount / 2) * creatorFullInfo.voteTotalPower) /
                totalVotingPower;
        uint availableAmount = totalReward > creatorFullInfo.claimedAmount
            ? totalReward - creatorFullInfo.claimedAmount
            : 0;

        return (totalReward, creatorFullInfo.claimedAmount, availableAmount);
    }

    function claimReward() external {
        require(isCreator[msg.sender] == true, "User is not creator");
        CreatorInfo storage creatorFullInfo = creatorInfo[msg.sender];

        uint totalReward = totalVotingPower == 0
            ? 0
            : ((totalRewardAmount / 2) * creatorFullInfo.voteTotalPower) /
                totalVotingPower;
        uint availableAmount = totalReward > creatorFullInfo.claimedAmount
            ? totalReward - creatorFullInfo.claimedAmount
            : 0;

        creatorFullInfo.claimedAmount = totalReward;
        require(
            IERC20(gameToken).balanceOf(address(this)) >= availableAmount,
            "Not enough reward amount"
        );
        IERC20(gameToken).transfer(msg.sender, availableAmount);

        emit RewardClaimed(msg.sender, availableAmount);
    }

    function getCollectionListBoughtLength() external view returns (uint) {
        return collectionListBought[msg.sender].length;
    }

    function getCollectionListBought()
        external
        view
        returns (address[] memory)
    {
        return collectionListBought[msg.sender];
    }
}
