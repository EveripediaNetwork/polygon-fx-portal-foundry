// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {FxBaseChildTunnel} from "fx-portal/tunnel/FxBaseChildTunnel.sol";

/**
 * @title FxStateChildTunnel
 */
contract FxStateChildTunnel is FxBaseChildTunnel {
    struct LockedBalance {
        int128 amount;
        uint256 end;
    }

    mapping(address => LockedBalance) locked;

    constructor(address _fxChild) FxBaseChildTunnel(_fxChild) {}

    function _processMessageFromRoot(
        uint256 stateId,
        address sender,
        bytes memory data
    )
        internal
        override
        validateSender(sender)
    {
        (address account, int128 amount, uint256 end) =
            abi.decode(data, (address, int128, uint256));
        locked[account] = LockedBalance(amount, end);
    }

    function getAmount(address account) public view returns (int128) {
        return locked[account].amount;
    }

    function getEnd(address account) public view returns (uint256) {
        return locked[account].end;
    }

    function sendMessageToRoot(bytes memory message) public {}
}
