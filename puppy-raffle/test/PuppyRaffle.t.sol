// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import {Test, console} from "forge-std/Test.sol";
import {PuppyRaffle} from "../src/PuppyRaffle.sol";

contract PuppyRaffleTest is Test {
    PuppyRaffle puppyRaffle;
    uint256 entranceFee = 1e18; //  1_000_000_000_000_000_000 = 1 Eth
    address playerOne = address(1);
    address playerTwo = address(2);
    address playerThree = address(3);
    address playerFour = address(4);
    address feeAddress = address(99);
    uint256 duration = 1 days;

event RaffleEnter(address[] newPlayers);

    function setUp() public {
        puppyRaffle = new PuppyRaffle(entranceFee, feeAddress, duration);
    }

    //////////////////////
    /// EnterRaffle    ///
    /////////////////////

    function test_EnterRaffleWithDuplicate() public {
        address[] memory newPlayers = new address[](0);
        // newPlayers[0] = playerOne;
        // newPlayers[1] = playerTwo;
        // newPlayers[2] = playerOne;
        vm.expectRevert("PuppyRaffle: Duplicate player");
        puppyRaffle.enterRaffle{value: 3 ether}(newPlayers);
        vm.expectEmit();
    }




    function test_EmitRaffleEnterEvent() public {
        address[] memory newPlayers = new address[](2);
        newPlayers[0] = playerOne;
        newPlayers[1] = playerTwo;

        vm.expectEmit(false,false,false,true);

        emit RaffleEnter(newPlayers); 

        puppyRaffle.enterRaffle{value: 2 ether}(newPlayers);
    }
}
