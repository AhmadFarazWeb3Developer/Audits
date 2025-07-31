// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;
import {Test, console2} from "forge-std/Test.sol";
import {Utilities_Test} from "../../Utilities_Test.t.sol";
import {ERC20Mock} from "../../mocks/ERC20Mock.sol";

//  Testing Vault Guardian, the main contract

contract VaultGuardiansTest is Utilities_Test {
    address attacker = makeAddr("attacker");
    uint256 mintAmount = 100 ether;

    function setUp() public override {
        Utilities_Test.setUp();
    }

    function testVaultGuardianAddress() public view {
        console2.log("Vaut Guardian Address : ", address(vaultGuardians));
    }

    function testupdateGuardianStakePrice() public {
        uint256 new_guardianStakePrice = 15 ether;
        vaultGuardians.updateGuardianStakePrice(new_guardianStakePrice);

        vm.startPrank(attacker);
        vm.expectRevert();
        vaultGuardians.updateGuardianStakePrice(new_guardianStakePrice);
        vm.stopPrank();
    }

    function testupdateGuardianAndDaoCut() public {
        uint256 new_guardianAndDaoCut = 15 ether;
        vaultGuardians.updateGuardianAndDaoCut(new_guardianAndDaoCut);
        vm.startPrank(attacker);
        vm.expectRevert();
        vaultGuardians.updateGuardianStakePrice(new_guardianAndDaoCut);
        vm.stopPrank();
    }

    function testSweepErc20s() public {
        ERC20Mock mock = new ERC20Mock();

        mock.mint(mintAmount, msg.sender);

        console2.log(mock.balanceOf(address(msg.sender)));

        vm.prank(msg.sender);
        mock.transfer(address(vaultGuardians), mintAmount);
        console2.log(mock.balanceOf(address(vaultGuardians)));
        console2.log(mock.balanceOf(address(msg.sender)));

        vm.prank(attacker);
        vaultGuardians.sweepErc20s(mock);

        console2.log(mock.balanceOf(address(vaultGuardians)));

        console2.log(
            "Sytem owner balance ",
            mock.balanceOf(vaultGuardians.owner())
        );
    }
}
