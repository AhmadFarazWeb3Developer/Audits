// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {ClimberVault} from "../src/ClimberVault.sol";
import {ClimberTimelock} from "../src/ClimberTimelock.sol";
import {DamnValuableToken} from "../src/DamnValuableToken.sol";

abstract contract UtilsTest is Test {
    ClimberVault valut;
    ClimberTimelock climberTimelock;
    DamnValuableToken token;

    address admin = makeAddr("admin");
    address proposer = makeAddr("proposer");

    function setUp() public virtual {
        // climberTimelock = new ClimberTimelock(admin, proposer); // version 1 deployment

        valut = new ClimberVault();

        token = new DamnValuableToken();

        token.transfer(address(valut), 10000 ether);
        token.approve(address(valut), 10000 ether);
    }
}
