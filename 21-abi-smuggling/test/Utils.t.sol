// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console, console2} from "forge-std/Test.sol";
import {AuthorizedExecutor} from "../src/AuthorizedExecutor.sol";
import {DamnValuableToken} from "../src/DamnValuableToken.sol";
import {SelfAuthorizedVault} from "../src/SelfAuthorizedVault.sol";
import {Attacker} from "./Attacker.sol";

abstract contract UtilsTest is Test {
    SelfAuthorizedVault vault;
    AuthorizedExecutor authorized;
    DamnValuableToken token;

    Attacker attacker;

    function setUp() public virtual {
        token = new DamnValuableToken();
        vault = new SelfAuthorizedVault();

        vm.startPrank(address(token));
        token.transfer(address(vault), 1000000 ether);
        token.approve(address(vault), 1000000 ether);

        attacker = new Attacker(token, authorized);
    }
}
