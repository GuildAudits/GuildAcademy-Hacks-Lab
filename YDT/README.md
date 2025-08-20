# YDT Hack

## Running the Hack Simulation

```bash
forge build
forge test --mt test_Exploit -vvv
```

## Explanation

The Tx where the hack occurred: https://bscscan.com/tx/0x233b21d0355108593c3f136797aed886ae1d4655384b33d67b1fccee88cdfbc2

The `proxyTransfer()` function looks something like this:
![](/YDT/images/proxyTransfer.png)

We can see a require check that allows a super-admin like access to the proxyTransfer contract

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

These checks ensures that if the callerModule is one of tax, referral, deflation, liquidity or lpTracking, it allows the transfer of tokens.

But in reality, the check really does not do anything, because it does not check if the `msg.sender` is actually one of those modules. So the attacker passed in arbitrary address which was the address of `taxModule`, to bypass the security check and transfer the tokens to him.

And then he swapped the received tokens in exchange for USDT on PancakeSwap to take away approx ~41,000 USD in profit.

We can see the funds flow in the image below, which summarizes the attack path as described before:
![](/YDT/images/fund-flow.png)

In Sentio, We can see the steps that the attacker used to carry out the attack.

You can refer to this Tx on Sentio [**here**](https://app.sentio.xyz/tx/56/0x233b21d0355108593c3f136797aed886ae1d4655384b33d67b1fccee88cdfbc2?nav=s)
![](/YDT/images/call-trace.png)
