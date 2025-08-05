// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {DamnValuableNFT} from "../src/DamnValuableNFT.sol";
import {Exchange} from "../src/Exchange.sol";
import {TrustfulOracleInitializer} from "../src/TrustfulOracleInitializer.sol";
import {TrustfulOracle} from "../src/TrustfulOracle.sol";

abstract contract UtilsTest is Test {
    DamnValuableNFT nft;
    TrustfulOracleInitializer trustfulOracleInitializer;
    TrustfulOracle trustfulOracle;
    Exchange exchange;

    address source1 = makeAddr("source1");
    address source2 = makeAddr("source2");
    address source3 = makeAddr("source3");

    function setUp() public virtual {
        nft = new DamnValuableNFT();

        // Initialize arrays properly
        address[] memory sources = new address[](3);
        string[] memory symbols = new string[](3);
        uint256[] memory initialPrices = new uint256[](3);

        // Fill the arrays
        sources[0] = source1;
        sources[1] = source2;
        sources[2] = source3;

        symbols[0] = "DVNFT";
        symbols[1] = "DVNFT";
        symbols[2] = "DVNFT";

        initialPrices[0] = 999 ether;
        initialPrices[1] = 998 ether;
        initialPrices[2] = 998 ether;

        // Pass arrays to constructor
        trustfulOracleInitializer = new TrustfulOracleInitializer(
            sources,
            symbols,
            initialPrices
        );
        trustfulOracle = new TrustfulOracle(sources, true);
    }
}
