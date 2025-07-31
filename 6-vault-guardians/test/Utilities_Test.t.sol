// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;
import {Test, console2} from "forge-std/Test.sol";

// import {} from "forge-std";
import {VaultGuardians} from "../src/protocol/VaultGuardians.sol";
import {VaultGuardianToken} from "../src/dao/VaultGuardianToken.sol";
import {VaultGuardiansBase} from "../src/protocol/VaultGuardiansBase.sol";

import {IVaultData} from "../src/interfaces/IVaultData.sol";
import {ERC20Mock} from "./mocks/ERC20Mock.sol";

import {UniswapRouterMock} from "./mocks/UniswapRouterMock.sol";
import {AavePoolMock} from "./mocks/AavePoolMock.sol";
import {UniswapFactoryMock} from "./mocks/UniswapFactoryMock.sol";

//  Testing Vault Guardian, the main contract
abstract contract Utilities_Test is Test, IVaultData {
    VaultGuardians public vaultGuardians;
    VaultGuardianToken public vaultGuardiansToken;

    ERC20Mock public WEHT_TOKEN;
    ERC20Mock public USDC_TOKEN;
    ERC20Mock LINK_TOKEN;

    ERC20Mock public aWeth;

    AavePoolMock public aavePool;
    UniswapRouterMock public uniswapRouter;
    UniswapFactoryMock public uniswapFactoryMock;

    address public vaultGuardianToken;

    // function setUp() public virtual {
    //     WEHT_TOKEN = new ERC20Mock();
    //     USDC_TOKEN = new ERC20Mock();
    //     LINK_TOKEN = new ERC20Mock();

    //     // the token which aave protocol return as a ownership

    //     aWeth = new ERC20Mock();

    //     aavePool = new AavePoolMock();
    //     aavePool.updateAtokenAddress(address(WEHT_TOKEN), address(aWeth));

    //     uniswapFactoryMock = new UniswapFactoryMock();

    //     uniswapRouter = new UniswapRouterMock(
    //         address(uniswapFactoryMock),
    //         address(WEHT_TOKEN)
    //     );
    //     vaultGuardiansToken = new VaultGuardianToken();
    //     vaultGuardians = new VaultGuardians(
    //         address(aavePool),
    //         address(uniswapRouter),
    //         address(WEHT_TOKEN),
    //         address(USDC_TOKEN),
    //         address(LINK_TOKEN),
    //         address(vaultGuardianToken)
    //     );
    // }
    function setUp() public virtual {
        // Create base tokens
        WEHT_TOKEN = new ERC20Mock();
        USDC_TOKEN = new ERC20Mock();
        LINK_TOKEN = new ERC20Mock();

        // Setup Aave
        aWeth = new ERC20Mock();
        aavePool = new AavePoolMock();
        aavePool.updateAtokenAddress(address(WEHT_TOKEN), address(aWeth));

        // Initialize Uniswap
        uniswapFactoryMock = new UniswapFactoryMock();

        // Create required pairs BEFORE router/vault creation
        address wethUsdcPair = uniswapFactoryMock.createPair(
            address(WEHT_TOKEN),
            address(USDC_TOKEN)
        );
        address wethLinkPair = uniswapFactoryMock.createPair(
            address(WEHT_TOKEN),
            address(LINK_TOKEN)
        );

        // Now create router and vault
        uniswapRouter = new UniswapRouterMock(
            address(uniswapFactoryMock),
            address(WEHT_TOKEN)
        );

        vaultGuardiansToken = new VaultGuardianToken();
        vaultGuardians = new VaultGuardians(
            address(aavePool),
            address(uniswapRouter),
            address(WEHT_TOKEN),
            address(USDC_TOKEN),
            address(LINK_TOKEN),
            address(vaultGuardiansToken)
        );
    }
}
