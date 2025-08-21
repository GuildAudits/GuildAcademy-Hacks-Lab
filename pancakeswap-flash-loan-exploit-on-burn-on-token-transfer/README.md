

# PancakeSwap Fee-on-Transfer Exploit Replay

This repo contains my Foundry test that simulates a real-world exploit on a PancakeSwap pool involving a malicious fee-on-transfer token.

## Summary

Here, I target a vulnerable ERC20 token (proxy at `0x8087720EeeA59F9F04787065447D52150c09643E`) paired with WBNB on PancakeSwap (`0xdA5C7eA4458Ee9c5484fA00F2B8c933393BAC965`). The attacker contract (`0x798465B25B68206370D99f541e11EEA43288D297`) abuses the token’s fee and burn logic to manipulate the pool’s reserves and extract profit.

### How the Exploit Works

1. **Flash Swap**: I borrow a large amount of the vulnerable token from the PancakeSwap pair using a flash swap.
2. **Repayment**: I repay the borrowed tokens with WBNB, calculated using the AMM’s constant product formula.
3. **Malicious Sell**: I sell the borrowed tokens back to the pool using PancakeSwap’s router with the `swapExactTokensForTokensSupportingFeeOnTransferTokens` function. This triggers the token’s fee-on-transfer logic, which burns tokens and calls `sync()` on the pair, corrupting the pool’s internal reserves.
4. **Profit Extraction**: Because the reserves are manipulated, I receive more WBNB than I should, realizing a profit.

### Key Points

- The profit is made during the sell step, not by draining the pool in a final swap.
- The exploit relies on the token’s custom fee logic, which interacts unsafely with the AMM’s reserve accounting.

## How to Run

1. Set your BSC RPC endpoint in your environment:
	```sh
	export BSC_RPC_URL=https://bnb-mainnet.g.alchemy.com/${KEY}
	```
2. Run the test:
	```sh
	forge test -vvv
	```

## Files

- `pancake-exploit.t.sol`: My main test file that replays the exploit step-by-step.


## Additional Notes

- As of writing, there has been no official post-mortem or public statement from the PancakeSwap team or the WXC project regarding this exploit.
- The exploited PancakeSwap pair contract (`0xdA5C7eA4458Ee9c5484fA00F2B8c933393BAC965`) still holds a balance of WBNB and has not been removed or cleaned up on-chain.

## References

- [Original attacker contract](https://bscscan.com/address/0x798465B25B68206370D99f541e11EEA43288D297)
- [Vulnerable token proxy](https://bscscan.com/address/0x8087720EeeA59F9F04787065447D52150c09643E)
- [PancakeSwap pair](https://bscscan.com/address/0xdA5C7eA4458Ee9c5484fA00F2B8c933393BAC965)
