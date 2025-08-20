# YDT Hack

## Running the Simulation

```bash
forge build
forge test --mt test_Exploit -vvv
```

## Incident Overview

Exploit transaction on BSC:
[https://bscscan.com/tx/0x233b21d0355108593c3f136797aed886ae1d4655384b33d67b1fccee88cdfbc2](https://bscscan.com/tx/0x233b21d0355108593c3f136797aed886ae1d4655384b33d67b1fccee88cdfbc2)

Attacker abused `proxyTransfer()` to move tokens from the Pancake LP and swapped them for stablecoins (\~\$41k).

## Vulnerable Function

![](/YDT/images/proxyTransfer.png)

```solidity
require(
    address(taxModule) == callerModule ||
    address(referralModule) == callerModule ||
    address(deflationModule) == callerModule ||
    address(liquidityModule) == callerModule ||
    address(lpTrackingModule) == callerModule,
    "Only sub-modules allowed"
);
```

**Issue:** The check validates the _argument_ `callerModule`, not `msg.sender`. Anyone can pass a whitelisted module address and gain transfer rights.

## Attack Path

1. **Abuse `proxyTransfer()`** to move LP-held YDT to the attacker, spoofing a module address.
   ![](/YDT/images/call-trace.png)

2. **Sync the LP** so reserves reflect the forced transfer.

3. **Swap YDT → USDT** on PancakeSwap to take profit.
   ![](/YDT/images/fund-flow.png)

## Fund Flow Summary

- **Source:** Pancake LP reserves
- **Bridge:** `proxyTransfer()` with spoofed `callerModule`
- **Exit:** Swap to stablecoin on PancakeSwap (\~\$41k)

## Post-Mortem Notes

- **Root cause:** Arbitrary address to check authorization instead of `msg.sender`.
- **Recommendations:**

  - Avoid proxy-style transfers that accept arbitrary module addresses.
  - Gate privileged paths with `require(msg.sender == module)` and ensure that address is one of the modules and that msg.sender is actually that module.
