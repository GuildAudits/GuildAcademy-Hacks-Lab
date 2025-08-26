// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/IGMXInterfaces.sol";

contract ReplayTxTest is Test {
    // Addresses from the analyzed tx
    address constant POSITION_MANAGER = 0x75E42e6f01baf1D6022bEa862A28774a9f8a4A0C;
    address constant ATTACKER = 0x7D3BD50336f64b7A473C51f54e7f0Bd6771cc355;
    address constant EXECUTOR = 0xd4266F8F82F7405429EE18559e548979D49160F3; // original tx.from
    string RPC = "https://arb-mainnet.g.alchemy.com/v2/7lkUtQyawPG08mJLej6Th";

    function testReplayExecuteDecreaseOrder() public {
    // Fork at the parent block of the original tx and then call into PositionManager
    // (replaying the call from the original tx's executor in the same state)
    uint256 fork = vm.createFork(RPC, 355880236);
        vm.selectFork(fork);

        // Ensure the accounts are present
        assertTrue(POSITION_MANAGER.code.length > 0, "PositionManager not a contract");
        assertTrue(ATTACKER != address(0), "attacker addr empty");

        // Impersonate the original executor and perform the low-level call using the
        // same selector + params as the historical transaction to better reproduce
        // the exact execution and capture any revert reason.
        vm.prank(EXECUTOR);
        bytes memory payload = abi.encodeWithSelector(
            IPositionManager.executeDecreaseOrder.selector,
            ATTACKER,
            uint256(5),
            payable(EXECUTOR)
        );

        (bool ok, bytes memory data) = POSITION_MANAGER.call(payload);
        if (!ok) {
            // decode revert reason if present
            string memory reason = "<no revert reason>";
            if (data.length >= 68) {
                // slice off selector and abi-decode
                assembly {
                    data := add(data, 0x04)
                }
                reason = abi.decode(data, (string));
            }
            emit log_named_string("executeDecreaseOrder reverted with", reason);
        }

        assertTrue(ok, "executeDecreaseOrder did not succeed on forked state");
    }
}
