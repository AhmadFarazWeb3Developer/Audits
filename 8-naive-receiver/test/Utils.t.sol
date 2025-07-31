// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test, console2} from "forge-std/Test.sol";
import {NaiveReceiverPool} from "../src/NaiveReceiverPool.sol";
import {FlashLoanReceiver} from "../src/FlashLoanReceiver.sol";
import {BasicForwarder} from "../src/BasicForwarder.sol";
import {RescueExploit} from "./Attack.sol";
import {WethMock} from "./mocks/WethMock.sol";
import {StealEth} from "./StealEth.sol";

abstract contract UtilsTest is Test {
    NaiveReceiverPool naivePool;
    FlashLoanReceiver flashLoanReceiver;
    BasicForwarder basicForwarder;
    RescueExploit attacker;
    StealEth stealEth;
    WethMock weth;

    address NaiveOwner = makeAddr("Naive owner");
    address feeRecepient = makeAddr("fee recepient");
    address feeStealer = makeAddr("fee stealer");
    address flashLoaner = makeAddr("flash Loaner");

    function setUp() public virtual {
        basicForwarder = new BasicForwarder();
        weth = new WethMock();

        // Fund test contract
        vm.deal(address(this), 100 ether);

        // Deploy the pool
        naivePool = new NaiveReceiverPool{value: 10 ether}(
            address(basicForwarder),
            payable(address(weth)),
            feeRecepient
        );

        // Provide pool with liquidity
        // weth.mint(address(naivePool), 3 ether);

        // Deploy and fund the victim
        flashLoanReceiver = new FlashLoanReceiver(address(naivePool));

        weth.mint(address(flashLoanReceiver), 1 ether);

        // Deploy attacker, who will target the victim
        attacker = new RescueExploit(
            address(naivePool),
            address(flashLoanReceiver)
        );

        stealEth = new StealEth(address(feeStealer));
    }
}
