//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {StatelessFuzzCatches} from "../../src/StatelessFuzzCatches.sol";

contract StatelessFuzzCatchesTest is Test {
    StatelessFuzzCatches sfc;

    function setUp() public {
        sfc = new StatelessFuzzCatches();
    }

    function test_FuzzCatchesBugStateless(uint128 _randomNumber) public view {
        assert(sfc.doMath(_randomNumber) != 0);
    }
}
