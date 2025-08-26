**Case Study: RANT Token Liquidity Burn Exploit on PancakeSwap**

**Overview**  
This case study examines a critical flaw in the RANT token’s transfer logic, enabling a user-triggered liquidity burn exploit on its main PancakeSwap pair. The exploit demonstrates how a seemingly harmless transfer hook can become a high-impact liquidity drain vector, leading to extreme price manipulation and significant profit for the attacker.

**Vulnerability**  
A flaw in the RANT token’s transfer logic allowed anyone to send tokens directly to the contract address, triggering the `_sellBurnLiquidityPairTokens` public function. This function destroyed liquidity proportional to the transfer amount, causing instant and extreme price manipulation (up to x,xxx%).

**Exploit Details**

- **Vulnerable Contract**: Deployed on July 3, 2025  
  Code: [View on Blockscan](https://vscode.blockscan.com/56/0xc321ac21a07b3d593b269acdace69c3762ca2dd0)
- **Liquidity Addition**: 150 WBNB added on July 5, 2025
- **Exploit Transaction**: [View on Blocksec](https://app.blocksec.com/explorer/tx/bsc/0x2d9c1a00cf3d2fda268d0d11794ad2956774b156355e16441d6edb9a448e5a99?line=103)
- **Time from Liquidity Addition to Hack**: 6 hours.
- run `forge test --mt testExploit -vvvvv` to view the logs in the exploit.t.sol test suite.

**Exploit Steps**

1. **Flash Loan**: The attacker borrowed 2,813 WBNB via a flash loan.
2. **Token Swap**: Swapped 2,813 WBNB for ~96.6M RANT, heavily loading the PancakeSwap pool and controlling the token supply.
3. **Pool Balance**: Post-swap, the pool held 10.7M RANT / 3,125 WBNB, causing the RANT price to rise.
4. **Liquidity Burn Trigger**: Transferred 90%+ of the pool’s RANT (~10.7M) to the token contract, activating the burn function and further inflating the price.
5. **Additional Burn**: The remaining RANT was sent to a node for burning.
6. **Pool Imbalance**: The pool was reduced to 1 RANT / 3,125 WBNB, pushing the RANT price to extreme levels (100M+% increase).
7. **Token Forwarding**: The RANT contract transferred the 10.7M RANT to the `rant_center` contract ([View on BSCScan](https://bscscan.com/address/0x9adb8c52f0d845739fd3e035ed230f0d4cba785a)).
8. **Profit Extraction**: The attacker swapped just 3.8M RANT back into the imbalanced pool, draining all 3,125 WBNB.

**Outcome**

- **Profit**: 312 WBNB (~$245,000) after repaying the flash loan.
- **Impact**: The exploit drained the pool’s liquidity, causing catastrophic price manipulation and enabling arbitrage for significant profit.

**Key Insight**  
This exploit highlights the risks of poorly designed transfer hooks in token contracts. The `_sellBurnLiquidityPairTokens` function, intended as a benign feature, became a critical vulnerability when exploited, underscoring the need for rigorous security audits in DeFi protocols.
