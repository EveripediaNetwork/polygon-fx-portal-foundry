// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {FxBaseRootTunnel} from "fx-portal/tunnel/FxBaseRootTunnel.sol";
import {iHiIQ} from "./utils/iHiIQ.sol";

/**
 * @title FxStateRootTunnel
 */
contract FxStateRootTunnel is FxBaseRootTunnel {
    address immutable hiIQ;

    constructor(address _checkpointManager, address _fxRoot, address _hiIQ)
        FxBaseRootTunnel(_checkpointManager, _fxRoot)
    {
        hiIQ = _hiIQ;
    }

    function _processMessageFromChild(bytes memory data) internal override {}

    function sync(address account) external {
        iHiIQ.LockedBalance memory lock = iHiIQ(hiIQ).locked(account);
        _sendMessageToChild(abi.encode(account, lock.amount, lock.end));
    }
}
