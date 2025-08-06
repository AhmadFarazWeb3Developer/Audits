// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {DamnValuableNFT} from "../src/DamnValuableNFT.sol";
import {Exchange} from "../src/Exchange.sol";
import {TrustfulOracleInitializer} from "../src/TrustfulOracleInitializer.sol";
import {TrustfulOracle} from "../src/TrustfulOracle.sol";
import {Attack} from "./Attack.sol";

abstract contract UtilsTest is Test {
    DamnValuableNFT nft;
    TrustfulOracleInitializer trustfulOracleInitializer;
    TrustfulOracle trustfulOracle;
    Exchange exchange;
    Attack attacker;

    address buyer1 = makeAddr("buyer1");
    address buyer2 = makeAddr("buyer2");

    address source1;
    address source2;
    address source3 = makeAddr("source3");

    function setUp() public virtual {
        nft = new DamnValuableNFT();

        address[] memory sources = new address[](3);
        string[] memory symbols = new string[](3);
        uint256[] memory initialPrices = new uint256[](3);
        source1 = vm.addr(
            0x7d15bba26c523683bfc3dc7cdc5d1b8a2744447597cf4da1705cf6c993063744
        );
        source1 = vm.addr(
            0x68bd020ad186b647a691c6a5c0c1529f21ecd09dcc45241402ac60ba377c4159
        );

        sources[0] = source1;
        sources[1] = source2;
        sources[2] = source3;

        symbols[0] = "DVNFT";
        symbols[1] = "DVNFT";
        symbols[2] = "DVNFT";

        initialPrices[0] = 999 ether;
        initialPrices[1] = 998 ether;
        initialPrices[2] = 998 ether;

        trustfulOracleInitializer = new TrustfulOracleInitializer(
            sources,
            symbols,
            initialPrices
        );
        exchange = new Exchange(address(trustfulOracleInitializer.oracle()));
        trustfulOracle = trustfulOracleInitializer.oracle();

        attacker = new Attack(trustfulOracle, exchange);
        vm.deal(address(exchange), 1000 ether);
    }
}
