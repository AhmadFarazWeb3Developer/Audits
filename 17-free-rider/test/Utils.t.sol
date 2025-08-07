// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {DamnValuableNFT} from "../src/DamnValuableNFT.sol";
import {FreeRiderNFTMarketplace} from "../src/FreeRiderNFTMarketplace.sol";
import {FreeRiderRecoveryManager} from "../src/FreeRiderRecoveryManager.sol";
import {FlashLoanPool} from "./strategy/FlashLoanPool.sol";
import {Resolver} from "./Resolver.sol";

abstract contract UtilsTest is Test {
    DamnValuableNFT nft;
    FreeRiderNFTMarketplace marketPlace;
    FreeRiderRecoveryManager recoveryManager;

    FlashLoanPool pool;
    Resolver resolver;

    address marketPlaceOwner = makeAddr("owner");
    address beneficiary = makeAddr("beneficiary");
    uint256 mintAmount = 6;

    function setUp() public virtual {
        vm.startPrank(marketPlaceOwner);
        marketPlace = new FreeRiderNFTMarketplace(mintAmount);

        nft = marketPlace.token();

        vm.deal(marketPlaceOwner, 45 ether);
        recoveryManager = new FreeRiderRecoveryManager{value: 45 ether}(
            beneficiary,
            address(nft),
            marketPlaceOwner,
            45 ether
        );
        vm.stopPrank();

        resolver = new Resolver(marketPlace, recoveryManager, beneficiary);
        pool = new FlashLoanPool();
        vm.deal(address(pool), 100 ether);
    }
}
