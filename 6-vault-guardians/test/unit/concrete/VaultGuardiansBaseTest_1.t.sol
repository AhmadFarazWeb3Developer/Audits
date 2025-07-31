// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;
import {Test, console2} from "forge-std/Test.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Mock} from "../../mocks/ERC20Mock.sol";
import {Utilities_Test} from "../../Utilities_Test.t.sol";

contract VaultGuardiansBaseTest is Utilities_Test {
    address public guardian = makeAddr("guardian");
    address public user = makeAddr("user");
    uint256 mintAmount = 100 ether;

    // 500 hold, 250 uniswap, 250 aave
    AllocationData allocationData = AllocationData(500, 250, 250);

    function setUp() public override {
        Utilities_Test.setUp();
    }

    function testbecomeGuardian() public {
        WEHT_TOKEN.mint(mintAmount, guardian);
        USDC_TOKEN.mint(mintAmount, guardian); // Need both tokens for pairing

        vm.startPrank(guardian);
        WEHT_TOKEN.approve(address(vaultGuardians), mintAmount);
        USDC_TOKEN.approve(address(vaultGuardians), mintAmount);

        vaultGuardians.becomeGuardian(allocationData);
        vm.stopPrank();
    }
}
