// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import {Test} from "forge-std/Test.sol";

import {FxStateRootTunnel} from "src/FxStateRootTunnel.sol";
import {FxStateChildTunnel} from "src/FxStateChildTunnel.sol";
import {iHiIQ} from "src/utils/iHiIQ.sol";
import {FxChild} from "fx-portal/FxChild.sol";

contract TestFxPortal is Test {
    string constant MAINNET_RPC_URL =
        "https://mainnet.infura.io/v3/5343f766c12f4c0e8599d90f72c1a600";
    string constant POLYGON_RPC_URL =
        "https://polygon-mainnet.infura.io/v3/5343f766c12f4c0e8599d90f72c1a600";
    uint256 constant MAINNET_BLOCK = 15212643;
    uint256 constant POLYGON_BLOCK = 31126971;

    address constant FxRootEth = 0xfe5e5D361b2ad62c541bAb87C45a0B9B018389a2;
    address constant FxChildMatic = 0x8397259c983751DAf40400790063935a11afa28a;
    address constant checkPointManagerEth =
        0x86E4Dc95c7FBdBf52e33D563BbDB00823894C287;

    address constant hiIQ = 0x1bF5457eCAa14Ff63CC89EFd560E251e814E16Ba;
    address constant hiIQHolder = 0x9fEAB70f3c4a944B97b7565BAc4991dF5B7A69ff;

    uint256 mainnetFork;
    uint256 polygonFork;

    FxStateRootTunnel stateRootTunnel;
    FxStateChildTunnel stateChildTunnel;

    function setUp() public {
        mainnetFork = vm.createSelectFork(MAINNET_RPC_URL, MAINNET_BLOCK);
        stateRootTunnel =
            new FxStateRootTunnel(checkPointManagerEth, FxRootEth, hiIQ);

        polygonFork = vm.createSelectFork(POLYGON_RPC_URL, POLYGON_BLOCK);
        stateChildTunnel = new FxStateChildTunnel(FxChildMatic);
        stateChildTunnel.setFxRootTunnel(address(stateRootTunnel));

        vm.selectFork(mainnetFork);
        stateRootTunnel.setFxChildTunnel(address(stateChildTunnel));
    }

    function testMessageFromEthereum() public {
        // get mainnet values and send sync
        vm.selectFork(mainnetFork);
        iHiIQ.LockedBalance memory lock = iHiIQ(hiIQ).locked(hiIQHolder);
        stateRootTunnel.sync(hiIQHolder);

        bytes memory locked = abi.encode(hiIQHolder, lock.amount, lock.end);
        bytes memory data =
            abi.encode(address(stateRootTunnel), address(stateChildTunnel), locked);

        // impersonate miner
        vm.selectFork(polygonFork);
        vm.startPrank(address(0x0000000000000000000000000000000000001001));
        FxChild(FxChildMatic).onStateReceive(0, data);

        // check values on polygon are the right ones
        assertEq(stateChildTunnel.getAmount(hiIQHolder), lock.amount);
        assertEq(stateChildTunnel.getEnd(hiIQHolder), lock.end);
    }
}
