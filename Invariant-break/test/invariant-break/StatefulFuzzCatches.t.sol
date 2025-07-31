//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {StatefulFuzzCatches} from "../../src/StatefulFuzzCatches.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";

contract StatefulFuzzCatchesTest is StdInvariant, Test {
    StatefulFuzzCatches sfc;

    function setUp() public {
        sfc = new StatefulFuzzCatches();
        targetContract(address(sfc));
    }

    function test_FuzzCatchesBugStateful(uint128 _randomNumber) public {
        assert(sfc.doMoreMathAgain(_randomNumber) != 0);
    }

    function statefulFuzz_catchesInvariant() public view{
        assert(sfc.storedValue() != 0);
        
    }
}
