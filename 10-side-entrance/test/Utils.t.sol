// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test, console2} from "forge-std/Test.sol";

import {SideEntranceLenderPool} from "../src/SideEntranceLenderPool.sol";
import {Attack} from "./Attack.sol";

abstract contract UtilsTest is Test {
    SideEntranceLenderPool pool;
    Attack attack;

    function setUp() public virtual {
        pool = new SideEntranceLenderPool();
        pool.deposit{value: 1000000 ether}();
        attack = new Attack(pool);
    }
}
