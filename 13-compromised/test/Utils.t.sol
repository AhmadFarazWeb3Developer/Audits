// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {DamnValuableNFT} from "../src/DamnValuableNFT.sol";
abstract contract UtilsTest {
    DamnValuableNFT nft;

    function setUp() public virtual {
        nft = new DamnValuableNFT();
    }
}
