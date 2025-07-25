// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
import {Test, console2} from "forge-std/Test.sol";

import {Utilities_Test} from "../../Utilities_Test.t.sol";

contract VaultGuardiansBaseTest is Utilities_Test {
    address public guardian = makeAddr("guardian");
    address public user = makeAddr("user");

    // 500 hold, 250 uniswap, 250 aave
    AllocationData allocationData = AllocationData(500, 250, 250);

    function setUp() public override {
        Utilities_Test.setUp();
    }

    function testbecomeGuardian() public {
        vm.prank(guardian);
        console2.log(guardian);
        vaultGuardians.becomeGuardian(allocationData);
        Utili
    }
}

