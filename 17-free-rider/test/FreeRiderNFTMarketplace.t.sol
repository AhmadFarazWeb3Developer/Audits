// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {UtilsTest} from "./Utils.t.sol";
import {IERC3156FlashBorrower} from "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";

contract FreeRiderNFTMarketplaceTest is UtilsTest {
    function setUp() public override {
        UtilsTest.setUp();
    }

    function testMarketPlace() public {
        nft.balanceOf(marketPlaceOwner);
    }

    function testOfferMany() public {
        uint256[] memory tokenIds = new uint256[](6);
        for (uint256 i = 0; i < mintAmount; i++) {
            tokenIds[i] = i;
        }

        uint256[] memory prices = new uint256[](6);
        for (uint256 i = 0; i < mintAmount; i++) {
            prices[i] = 15;
        }

        vm.startPrank(marketPlaceOwner);
        nft.setApprovalForAll(address(marketPlace), true);
        marketPlace.offerMany(tokenIds, prices);
        vm.stopPrank();

        vm.startPrank(address(resolver), address(resolver)); // sets both msg.sender and tx.origin
        pool.flashLoan(IERC3156FlashBorrower(resolver), 15 ether, "");
    }
}
