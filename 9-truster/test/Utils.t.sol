// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test, console2} from "forge-std/Test.sol";

import {TrusterLenderPool} from "../src/TrusterLenderPool.sol";
import {DamnValuableToken} from "../src/DamnValuableToken.sol";
import {Target} from "./Target.sol";

abstract contract UtilsTest is Test {
    TrusterLenderPool trusterLenderPool;
    DamnValuableToken token;
    Target target;

    address flashLoaner = makeAddr("flash Loaner");
    address attacker = makeAddr("attacker");

    function setUp() public virtual {
        token = new DamnValuableToken();
        trusterLenderPool = new TrusterLenderPool(DamnValuableToken(token));

        token.transfer(address(trusterLenderPool), 1000000 ether);

        target = new Target(token, trusterLenderPool, attacker);
    }
}
