// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

contract BullBear is ERC721, ERC721Enumerable, Ownable, KeeperCompatible {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    uint256 immutable interval;
    uint256 public lastTimestamp;
    uint256 public currentPrice;
    string uri;

    AggregatorV3Interface public priceFeed;

    string bullUrisIpfs =
        "https://ipfs.io/ipfs/QmRXyfi3oNZCubDxiVFre3kLZ8XeGt6pQsnAQRZ7akhSNs?filename=gamer_bull.json";
    string bearUrisIpfs =
        "https://ipfs.io/ipfs/Qmdx9Hx7FCDZGExyjLR6vYcnutUR8KhBZBnZfAPHiUommN?filename=beanie_bear.json";

    event TokensUpdated(string indexed trend);

    constructor(uint256 updatedInterval, address _priceFeed)
        ERC721("Bull&Bear", "BBTK")
    {
        interval = updatedInterval;
        lastTimestamp = block.timestamp;

        priceFeed = AggregatorV3Interface(_priceFeed);
        uri = bullUrisIpfs;
        currentPrice = getLatestPrice();
    }

    function checkUpkeep(bytes calldata)
        external
        view
        override
        returns (bool upkeepNedded, bytes memory performData)
    {
        upkeepNedded = (block.timestamp - lastTimestamp) > interval;
    }

    function performUpkeep(bytes calldata performData) external override {
        if ((block.timestamp - lastTimestamp) > interval) {
            lastTimestamp = block.timestamp;

            uint256 lastPrice = getLatestPrice();

            if (lastPrice == currentPrice) {
                return;
            }

            if (lastPrice < currentPrice) {
                updateTokensUri("bear");
            } else {
                updateTokensUri("bull");
            }

            currentPrice = lastPrice;
        }
    }

    function getLatestPrice() public view returns (uint256) {
        int256 price;
        (, price, , , ) = priceFeed.latestRoundData();

        return uint256(price);
    }

    function updateTokensUri(string memory trend) internal {
        if (compareStrings("bear", trend)) {
            uri = bearUrisIpfs;
        } else {
            uri = bullUrisIpfs;
        }

        emit TokensUpdated(trend);
    }

    function setPricefeed(address _priceFeed) public onlyOwner {
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    function compareStrings(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function safeMint() public {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        _requireMinted(tokenId);
        return uri;
    }
}
