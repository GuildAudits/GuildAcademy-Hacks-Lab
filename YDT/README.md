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

**Issue:** The check validates the _argument_ `callerModule`, not `msg.sender`. Anyone can pass a whitelisted module address and gain transfer rights.

![](/YDT/images/proxyTransfer.png)

The require check only checks the address passed in during function call and fails to check if the actual sender is one of the modules.

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

In Sentio, We can see the steps that the attacker used to carry out the attack. You can refer to this [**Tx on Sentio**](https://app.sentio.xyz/tx/56/0x233b21d0355108593c3f136797aed886ae1d4655384b33d67b1fccee88cdfbc2?nav=s)

## Attack Path

1. **Use `proxyTransfer()`** to move YDT with super-user validation (module validation address in this case) to the attacker's address.
   ![](/YDT/images/call-trace.png)

2. Sync the LP reserves.

3. **Swap YDT → USDT** on PancakeSwap to take profit, as shown by the fund flow section in the image below.
   ![](/YDT/images/fund-flow.png)

## Post-Mortem Notes

- **Root cause:** Arbitrary address to check authorization instead of `msg.sender`.
- **Recommendations:**
  - Avoid proxy-style transfers that accept arbitrary module addresses.
  - Gate privileged paths with `require(msg.sender == module)` and ensure that address is one of the modules and that msg.sender is actually that module.
