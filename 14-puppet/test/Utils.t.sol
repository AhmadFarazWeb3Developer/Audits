// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {PuppetPool} from "../src/PuppetPool.sol";
import {UniswapV1Exchange} from "../src/uniswapV1/Exchange.sol";
import {UniswapV1Factory} from "../src/uniswapV1/Factory.sol";
import {DamnValuableToken} from "../src/DamnValuableToken.sol";

abstract contract UtilsTest is Test {
    PuppetPool pool;
    DamnValuableToken dvt;
    UniswapV1Exchange exchange;
    UniswapV1Factory factory;

    function setUp() public virtual {
        vm.deal(address(this), 100 ether);
        dvt = new DamnValuableToken();

        factory = new UniswapV1Factory();
        factory.createExchange(address(dvt));

        address exchangeAddress = factory.getExchange(address(dvt));
        exchange = UniswapV1Exchange(payable(exchangeAddress));

        pool = new PuppetPool(address(dvt), address(exchange));

        dvt.approve(address(exchange), type(uint256).max);
        dvt.approve(address(pool), type(uint256).max);

        // Provide liquidity
        dvt.transfer(address(exchange), 10 ether);
        dvt.transfer(address(pool), 10000 ether);

        exchange.addLiquidity{value: 10 ether}(
            0,
            10 ether,
            block.timestamp + 1 days
        );
    }
}
