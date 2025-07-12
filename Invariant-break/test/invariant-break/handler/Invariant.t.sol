// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Test, console2} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {HandlerStatefulFuzzCatches} from "../../../src/HandlerStatefulFuzzCatches.sol";
import {MockUSDC} from "../mocks/MockUSDC.sol";
import {YeildERC20} from "../mocks/YeildERC20.sol";
// will be fuzzing handler test contract
import {Handler} from "./Handler.t.sol";

contract HandlerStatefullFuzzCatches is StdInvariant, Test {
    HandlerStatefulFuzzCatches handlerStatefulFuzzCatches;
    MockUSDC mockUSDC;
    YeildERC20 yeildERC20;
    IERC20[] supportedTokens;
    uint256 startingAmount;

    address user = makeAddr("user");
    Handler handler;

    function setUp() public {
        vm.startPrank(user);

        mockUSDC = new MockUSDC();
        yeildERC20 = new YeildERC20();

        startingAmount = yeildERC20.INITIAL_SUPPLY();
        mockUSDC.mint(user, startingAmount);
        vm.stopPrank();

        supportedTokens.push(mockUSDC);
        supportedTokens.push(yeildERC20);

        handlerStatefulFuzzCatches = new HandlerStatefulFuzzCatches(
            supportedTokens
        );
        handler = new Handler(handlerStatefulFuzzCatches, mockUSDC, yeildERC20);
        targetContract(address(handler));

        bytes4[] memory selectors = new bytes4[](4);
        selectors[0] = handler.depositYeildERC20.selector;
        selectors[1] = handler.depositMockUSDC.selector;
        selectors[2] = handler.withdrawYeildERC20.selector;
        selectors[3] = handler.withdrawMockUSDC.selector;

        targetSelector(
            FuzzSelector({addr: address(handler), selectors: selectors})
        );
    }

    function statefulFuzz_testInvariantBreaksHandler() public {
        vm.startPrank(user);

        handlerStatefulFuzzCatches.withdrawToken(mockUSDC);
        handlerStatefulFuzzCatches.withdrawToken(yeildERC20);
        vm.stopPrank();

        assert(mockUSDC.balanceOf(address(handlerStatefulFuzzCatches)) == 0);
        assert(mockUSDC.balanceOf(address(handlerStatefulFuzzCatches)) == 0);

        assert(mockUSDC.balanceOf(address(user)) == startingAmount);
        assert(mockUSDC.balanceOf(address(user)) == startingAmount);
    }

    // -> deposit and withdraw yeildERC20
    // -> on the 10th one, it sends 10% of the yeildERC20 to the Owner of the contract !!
    // -> This breaks our invariant!!!

    //
}
