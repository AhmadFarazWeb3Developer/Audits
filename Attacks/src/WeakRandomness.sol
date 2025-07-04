// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.22;

contract WeakRandomness {
    function getRandomNumber() external view returns (uint256) {
        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(msg.sender, block.prevrandao, block.timestamp)
            )
        ) % 3;
        return randomNumber;
    }
}
