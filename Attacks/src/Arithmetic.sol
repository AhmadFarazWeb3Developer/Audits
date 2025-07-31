// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

contract Overflow {
    uint8 public count; // 0 - 255

    function increment(uint8 _amount) public {
        // allow to bypass the overflow, let overlow
        unchecked {
            count = count + _amount;
        }
    }
}

contract Underflow {
    uint8 public count;

    function decrement(uint8 _amount) public {
        unchecked {
            count = count - _amount;
        }
    }
}

contract PrecisionLoss {
    uint256 public moneyToSplitUp = 255;
    uint256 public users = 4;

    function shareMoney() public view returns (uint256) {
        return moneyToSplitUp / users;
    }
}
