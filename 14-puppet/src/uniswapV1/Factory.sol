// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IUniswapV1Factory} from "../Interface/IUniswapV1Factory.sol";
import {UniswapV1Exchange} from "./Exchange.sol";

contract UniswapV1Factory is IUniswapV1Factory {
    address public override exchangeTemplate;
    mapping(address => address) private tokenToExchange;
    mapping(address => address) private exchangeToToken;
    mapping(uint256 => address) private idToToken;
    uint256 private tokenCount;

    // event NewExchange(address indexed token, address indexed exchange);

    function initializeFactory(address template) external override {
        require(exchangeTemplate == address(0), "Factory: already initialized");
        require(template != address(0), "Factory: invalid template");
        exchangeTemplate = template;
    }

    function createExchange(
        address token
    ) external override returns (address out) {
        require(token != address(0), "Factory: invalid token");
        require(
            tokenToExchange[token] == address(0),
            "Factory: exchange exists"
        );
        // address exchange = createClone(exchangeTemplate);
        address payable exchange = payable(createClone(exchangeTemplate));

        UniswapV1Exchange(exchange).setup(token);
        tokenToExchange[token] = exchange;
        exchangeToToken[exchange] = token;
        idToToken[tokenCount] = token;
        tokenCount++;
        emit NewExchange(token, exchange);
        return exchange;
    }

    function getExchange(
        address token
    ) external view override returns (address out) {
        return tokenToExchange[token];
    }

    function getToken(
        address exchange
    ) external view override returns (address out) {
        return exchangeToToken[exchange];
    }

    function getTokenWithId(
        uint256 token_id
    ) external view override returns (address out) {
        return idToToken[token_id];
    }

    // EIP-1167: Minimal Proxy Contract (clone factory)
    function createClone(address target) private returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone, 0x14), targetBytes)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            result := create(0, clone, 0x37)
        }
        require(result != address(0), "Factory: clone creation failed");
    }
}
