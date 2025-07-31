// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {HandlerStatefulFuzzCatches} from "../../../src/HandlerStatefulFuzzCatches.sol";
import {MockUSDC} from "../mocks/MockUSDC.sol";
import {YeildERC20} from "../mocks/YeildERC20.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract HandlerStatefullFuzzCatches is StdInvariant, Test {
    HandlerStatefulFuzzCatches handlerStatefulFuzzCatches;
    MockUSDC mockUSDC;
    YeildERC20 yeildERC20;
    IERC20[] supportedTokens;
    
    address user = makeAddr("user");
    uint256 startingAmount;

    function setUp() public {
        vm.startPrank(user);

        mockUSDC = new MockUSDC();
        yeildERC20 = new YeildERC20();

        startingAmount = yeildERC20.INITIAL_SUPPLY();
        mockUSDC.mint(user, startingAmount);

        supportedTokens.push(mockUSDC);
        supportedTokens.push(yeildERC20);

        handlerStatefulFuzzCatches = new HandlerStatefulFuzzCatches(
            supportedTokens
        );
        targetContract(address(handlerStatefulFuzzCatches));

        vm.stopPrank();
    }

    function testStartingAmountTheSame() public view {
        assert(startingAmount == yeildERC20.balanceOf(user));
        assert(startingAmount == mockUSDC.balanceOf(user));
        console2.log(yeildERC20.balanceOf(user));
    }

    function statefulFuzz_testInvariantBreaks() public {
        vm.startPrank(user);

        handlerStatefulFuzzCatches.withdrawToken(mockUSDC);
        handlerStatefulFuzzCatches.withdrawToken(yeildERC20);
        vm.stopPrank();

        assert(mockUSDC.balanceOf(address(handlerStatefulFuzzCatches)) == 0);
        assert(mockUSDC.balanceOf(address(handlerStatefulFuzzCatches)) == 0);

        assert(mockUSDC.balanceOf(address(user)) == startingAmount);
        assert(mockUSDC.balanceOf(address(user)) == startingAmount);
    }
}
