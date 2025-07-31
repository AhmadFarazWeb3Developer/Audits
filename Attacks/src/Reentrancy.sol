// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/console.sol";

contract Victam {
    mapping(address => uint256) public userBalance;

    function deposit() public payable {
        userBalance[msg.sender] += msg.value;
    }

    // Follow CEI pattern
    function withdrawBalance() public {
        // Checks
        // Effects
        uint256 balance = userBalance[msg.sender];
        userBalance[msg.sender] = 0;

        //Interactions
        (bool success, ) = msg.sender.call{value: balance}(""); // when there is no eth or data send the tnx reverts
        if (!success) {
            revert();
        }
    }
}

contract Attacker {
    Victam victam;

    constructor(Victam _victam) {
        victam = _victam;
    }

    function attack() public payable {
        victam.deposit{value: 1 ether}();
        victam.withdrawBalance();
    }

    receive() external payable {
        if (address(victam).balance >= 1 ether) {
            victam.withdrawBalance();
        }
    }
}
