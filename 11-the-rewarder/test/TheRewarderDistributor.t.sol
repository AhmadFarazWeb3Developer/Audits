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

        claim[1] = Claim({
            batchNumber: 0,
            amount: 100,
            tokenIndex: 0,
            proof: firstUserProof
        });
        claim[3] = Claim({
            batchNumber: 0,
            amount: 100,
            tokenIndex: 0,
            proof: firstUserProof
        });

        tokens[0] = usdcMock;
        // tokens[1] = wethMock;

        vm.startPrank(0x0000000000000000000000000000000000000001);
        rewarderDistributor.claimRewards(claim, tokens);
        vm.stopPrank();
    }
}
