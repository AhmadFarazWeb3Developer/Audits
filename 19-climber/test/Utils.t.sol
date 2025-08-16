// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {ClimberVault} from "../src/ClimberVault.sol";
import {ClimberTimelock} from "../src/ClimberTimelock.sol";
import {DamnValuableToken} from "../src/DamnValuableToken.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

abstract contract UtilsTest is Test {
    ClimberVault valut;
    ClimberTimelock climberTimelock;
    DamnValuableToken token;

    ERC1967Proxy erc1967Proxy;

    address admin = makeAddr("admin");
    address proposer = makeAddr("proposer");
    address sweeper = makeAddr("sweeper");

    function setUp() public virtual {
        valut = new ClimberVault();

        token = new DamnValuableToken();

        token.transfer(address(valut), 10000 ether);
        token.approve(address(valut), 10000 ether);

        erc1967Proxy = new ERC1967Proxy(
            address(valut),
            abi.encodeWithSelector(
                valut.initialize.selector,
                admin,
                proposer,
                sweeper
            )
        );
    }
}
