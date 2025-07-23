// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;
import {Test, console2} from "forge-std/Test.sol";

// import {} from "forge-std";
import {VaultGuardians} from "../../../src/protocol/VaultGuardians.sol";
import {Base_Test} from "../../Base.t.sol";
import {ERC20Mock} from "../../mocks/ERC20Mock.sol";

import {VaultGuardianToken} from "../../../src/dao/VaultGuardianToken.sol";

import {UniswapRouterMock} from "../../mocks/UniswapRouterMock.sol";
import {AavePoolMock} from "../../mocks/AavePoolMock.sol";
import {UniswapFactoryMock} from "../../mocks/UniswapFactoryMock.sol";

//  Testing Vault Guardian, the main contract
contract VaultGuardiansTest is Test {
    VaultGuardians public vaultGuardians;
    VaultGuardianToken public vaultGuardiansToken;

    address public WEHT_TOKEN;
    address public USDC_TOKEN;
    address public LINK_TOKEN;

    AavePoolMock public aavePool;
    UniswapRouterMock public uniswapRouter;
    UniswapFactoryMock public uniswapFactoryMock;

    address public vaultGuardianToken;

    function setUp() public {
        ERC20Mock WEHT_TOKEN = new ERC20Mock();
        ERC20Mock USDC_TOKEN = new ERC20Mock();
        ERC20Mock LINK_TOKEN = new ERC20Mock();

        aavePool = new AavePoolMock();

        uniswapFactoryMock = new UniswapFactoryMock();

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
            address(vaultGuardianToken)
        );
    }

    function testVaultGuardianAddress() public {
        console2.log("Vaut Guardian Address : ", address(vaultGuardians));
    }
}
