// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;
import {Test} from "../../lib/forge-std/src/Test.sol";
import {StdInvariant} from "../../lib/forge-std/src/StdInvariant.sol";
import {ERC20} from "../mocks/ERC20Mock.sol";

import {PoolFactory} from "../../src/PoolFactory.sol";
import {TSwapPool} from "../../src/TSwapPool.sol";

contract Invariant is StdInvariant, Test {
    // these pools have 2 assets

    ERC20Mock poolToken;
    ERC20Mock weth;

    PoolFactory factory;
    TSwapPool pool;
    int256 constant STARTING_X = 100e18; // starting ERC20/ poolToken
    int256 constant STARTING_Y = 50e18; // starting WETH

    function setUp() public {
        weth = new weth();
        poolToken = new ERC20Mock();
        factory = new PoolFactory(address(weth));
        pool = TSwapPool(factory.createPool(address(poolToken)));

        // Create those initial x & y balances

        poolToken.mint((address(this)), uint256(STARTING_X));
        weth.mint(address(this), uint256(STARTING_Y));
        poolToken.approve(address(pool), type(uint256).max);
        weth.approve(address(pool), type(uint256).max);

        // Deposit into the pool, givn the starting X& Y balancer
        pool.deposit(
            uint256(STARTING_Y),
            uint256(STARTING_Y),
            uint256(STARTING_X),
            uint64(block.timestamp)
        );
    }

    function statefullFuzz_ConstantProductFormulaStaysTheSame() public {
        assert();
        // The change in the pool size of WETH should follow this function:
        // delta X = ((Beta/1-Beta))* X
        
    }
}
