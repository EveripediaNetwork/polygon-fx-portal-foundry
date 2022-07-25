// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import {Test} from "forge-std/Test.sol";

import {FxStateRootTunnel} from "src/FxStateRootTunnel.sol";
import {FxStateChildTunnel} from "src/FxStateChildTunnel.sol";
import {FxChild} from "fx-portal/FxChild.sol";

contract TestFxPortal is Test {

    string constant MAINNET_RPC_URL = "https://mainnet.infura.io/v3/xxx";
    string constant POLYGON_RPC_URL = "https://polygon-mainnet.infura.io/v3/xxx";
    uint constant MAINNET_BLOCK = 15212643;
    uint constant POLYGON_BLOCK = 31126971;

    address constant FxRootEth = 0xfe5e5D361b2ad62c541bAb87C45a0B9B018389a2;
    address constant FxChildMatic = 0x8397259c983751DAf40400790063935a11afa28a;
    address constant checkPointManagerEth = 0x86E4Dc95c7FBdBf52e33D563BbDB00823894C287;

    uint256 mainnetFork;
    uint256 polygonFork;

    FxStateRootTunnel stateRootTunnel;
    FxStateChildTunnel stateChildTunnel;

    function setUp() public {
        mainnetFork = vm.createSelectFork(MAINNET_RPC_URL, MAINNET_BLOCK);
        stateRootTunnel = new FxStateRootTunnel(checkPointManagerEth, FxRootEth);

        polygonFork = vm.createSelectFork(POLYGON_RPC_URL, POLYGON_BLOCK);
        stateChildTunnel = new FxStateChildTunnel(FxChildMatic);
        stateChildTunnel.setFxRootTunnel(address(stateRootTunnel));

        vm.selectFork(mainnetFork);
        stateRootTunnel.setFxChildTunnel(address(stateChildTunnel));
    }

    function testMessageFromEthereum(bytes memory msg) public {
        vm.selectFork(mainnetFork);
        stateRootTunnel.sendMessageToChild(msg);

        bytes memory data = abi.encode(address(stateRootTunnel), address(stateChildTunnel), msg);

        vm.selectFork(polygonFork);
        vm.startPrank(address(0x0000000000000000000000000000000000001001));
        uint currentStateId = stateChildTunnel.latestStateId();
        FxChild(FxChildMatic).onStateReceive(currentStateId + 1, data);
        assertEq(stateChildTunnel.latestStateId(), currentStateId + 1);
        assertEq(stateChildTunnel.latestData(), msg);
    }
}
