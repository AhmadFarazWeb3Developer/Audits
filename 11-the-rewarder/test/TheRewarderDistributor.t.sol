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
        Claim[] memory claim = Claim[](1);
        claim[0] = Claim({
            batchNumber: 0,
            amount: 100,
            tokenIndex: 0,
            proof: firstUserProof
        });

        IERC20[] memory tokens = IERC20[](1);
        tokens[0] = (address(usdcMock));
        rewarderDistributor.claimRewards(claim, tokens);
    }
}
