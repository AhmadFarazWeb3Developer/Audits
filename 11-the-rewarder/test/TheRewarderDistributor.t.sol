// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {UtilsTest} from "./Utils.t.sol";
import {Claim} from "../src/TheRewarderDistributor.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract TheRewarderDistributorTest is UtilsTest {
    function setUp() public override {
        UtilsTest.setUp();
    }

    function testGetNextBatchNumber() public {
        rewarderDistributor.getNextBatchNumber(address(usdcMock));
    }

    function testGetRemaining() public {
        rewarderDistributor.getRemaining(address(usdcMock));
    }

    function testGetRoot() public {
        rewarderDistributor.getRoot(address(usdcMock), 0);
    }

    function testClaimReward() public {
        IERC20[] memory tokens = new IERC20[](2);
        Claim[] memory claim = new Claim[](3);

        claim[0] = Claim({
            batchNumber: 0,
            amount: 100,
            tokenIndex: 0,
            proof: firstUserProof
        });

        claim[1] = claim[0];
        claim[2] = claim[0];

        tokens[0] = usdcMock;

        vm.startPrank(0x0000000000000000000000000000000000000001);
        rewarderDistributor.claimRewards(claim, tokens);
        vm.stopPrank();
    }

    function testCleanTokensWithoutAccessControl() public {
        IERC20[] memory tokens = new IERC20[](2);
        address attacker = address(0xBEEF);

        tokens[0] = usdcMock;
        tokens[1] = wethMock;

        uint256 balanceBefore = usdcMock.balanceOf(owner);

        vm.startPrank(attacker);
        rewarderDistributor.clean(tokens);
        vm.stopPrank();

        uint256 balanceAfter = usdcMock.balanceOf(owner);

        assertGt(
            balanceAfter,
            balanceBefore,
            "clean() should have transferred tokens"
        );
    }
}
