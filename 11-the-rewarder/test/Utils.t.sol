// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test, console2} from "forge-std/Test.sol";

import {TheRewarderDistributor} from "../src/TheRewarderDistributor.sol";


import {USDCMock} from "./mocks/USDCMock.sol";
import {WETHMock} from "./mocks/WETHMock.sol";

abstract contract UtilsTest is Test {
    TheRewarderDistributor rewarderDistributor;

    USDCMock usdcMock;
    WETHMock wethMock;

    address owner;
    bytes32 proof =
        0x3879d53cfda6af3ce4e4aaef2017ce13b2f8a3ad505c3d41293df7241a0f50cb;

    bytes32[] firstUserProof = [
        0x3321e9a72660cebc7303848db53fd0c194ff951253aaa99da2380a874d3c516a,
        0xe4fef2df2e569870a6000ece0cbb0538aef82b782d606422b09a79d0ee64d1ba
    ];


    function setUp() public virtual {
        rewarderDistributor = new TheRewarderDistributor();

        usdcMock = new USDCMock();
        wethMock = new WETHMock();

        owner = rewarderDistributor.owner();
        usdcMock.mint(owner, 1000 ether);
        vm.prank(owner);
        usdcMock.approve(address(rewarderDistributor), 1000 ether);

        vm.startPrank(owner);
        rewarderDistributor.createDistribution((usdcMock), proof, 1000 ether);
        vm.stopPrank();
    }
}
