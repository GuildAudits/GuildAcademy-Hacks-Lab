# D3XAI Attack Analysis

## Overview
This repository contains a detailed analysis and reproduction of the D3XAI exploit that occurred on the Binance Smart Chain, resulting in a loss of **190 BNB** (~$190,000 at the time).

## Attack Details

- **Date**: January 2025
- **Total Loss**: 190 BNB
- **Blockchain**: Binance Smart Chain (BSC)
- **Block Number**: 57,780,985
- **Attack Transaction**: [0x26bcefc152d8cd49f4bb13a9f8a6846be887d7075bc81fa07aa8c0019bd6591f](https://bscscan.com/tx/0x26bcefc152d8cd49f4bb13a9f8a6846be887d7075bc81fa07aa8c0019bd6591f)

### Key Addresses
- **Attacker**: `0x4b63c0cf524f71847ea05b59f3077a224d922e8d`
- **Attack Contract**: `0x3b3e1edeb726b52d5de79cf8dd8b84995d9aa27c`
- **Vulnerable Proxy**: `0xb8ad82c4771DAa852DdF00b70Ba4bE57D22eDD99`
- **D3XAT Token**: `0x2Cc8B879E3663d8126fe15daDaaA6Ca8D964BbBE`

## Root Cause
The attack exploited a **price manipulation vulnerability** in a proxy contract's `exchange()` function. The proxy allowed attackers to:
1. Buy D3XAT tokens at artificially low prices
2. Sell the same tokens at higher market prices
3. Profit from the price discrepancy

## Attack Flow

### Step 1: Flash Loan
- Borrowed **20,000,000 USDT** from PancakeSwap V3 pool
- Used flash loan to obtain large capital without upfront investment

### Step 2: Proxy Purchase (Low Price)
- Spent **~24,000 USDT** to buy D3XAT tokens through the vulnerable proxy
- Used 2 proxy buyer contracts to make purchases
- Each purchase bought approximately 9,000 D3XAT tokens at below-market rates

### Step 3: Market Purchase (High Price)  
- Spent **~6,180,000 USDT** to buy D3XAT from PancakeSwap Router
- Used 27 pancake buyer contracts to distribute purchases
- Each purchase bought approximately 9,900 D3XAT tokens at market rates
- This step was likely used to manipulate the token's market price upward

### Step 4: Proxy Sale (High Price)
- Sold D3XAT tokens (from Step 2) back through the proxy at inflated prices
- Gained **~22,500 USDT** profit from this arbitrage
- Made up to 30 sell attempts to maximize extraction

### Step 5: Market Sale
- Sold remaining D3XAT tokens (from Step 3) on PancakeSwap
- Recovered **~6,110,000 USDT**
- Net loss on market operations was minimal due to price manipulation

### Step 6: Repay Flash Loan
- Repaid 20,000,000 USDT + fees to PancakeSwap V3 pool
- Kept the profit from the arbitrage opportunity

## Technical Implementation

### Contract Architecture
The attack used a sophisticated multi-contract setup:

1. **ProxyBuyer Contracts (2x)**: Purchase D3XAT through vulnerable proxy
2. **PancakeBuyer Contracts (27x)**: Purchase D3XAT through PancakeSwap
3. **PancakeSeller Contracts (27x)**: Sell D3XAT through PancakeSwap  
4. **ProxySeller Contract (1x)**: Sell D3XAT through vulnerable proxy

### Key Functions
- `exchange()`: Vulnerable function in proxy contract allowing price manipulation
- `swapExactTokensForTokensSupportingFeeOnTransferTokens()`: PancakeSwap trading function
- `delegatecall()`: Used to execute trades through helper contracts

## Vulnerability Analysis

### Primary Vulnerability
The proxy contract's `exchange()` function likely contained:
- Incorrect price calculation logic
- Lack of slippage protection
- Missing market price validation
- Inadequate liquidity checks

### Attack Vector Classification
- **Type**: Price Manipulation + Arbitrage
- **Method**: Flash Loan + Multi-Contract Coordination  
- **Target**: DeFi Protocol with Custom Exchange Logic
- **Complexity**: High (sophisticated multi-step execution)

## Profit Calculation

```
Initial Capital: 20,000,000 USDT (flash loan)
Proxy Purchase: -24,000 USDT
Market Purchase: -6,180,000 USDT  
Proxy Sale: +22,500 USDT
Market Sale: +6,110,000 USDT
Flash Loan Repayment: -20,000,000 USDT
Estimated Net Profit: ~190 BNB equivalent
```

## Prevention Measures

### For Protocol Developers
1. **Oracle Integration**: Use reliable price oracles (Chainlink, Band Protocol)
2. **Slippage Protection**: Implement maximum slippage limits
3. **Market Validation**: Cross-reference prices with established DEXs
4. **Circuit Breakers**: Halt trading during unusual price movements
5. **Time-Weighted Averages**: Use TWAP for price calculations
6. **Liquidity Checks**: Ensure adequate liquidity before large trades

### For Users
1. **Due Diligence**: Research protocol security before investing
2. **Diversification**: Don't concentrate funds in single protocols
3. **Monitoring**: Watch for unusual price movements
4. **Community**: Stay informed through security-focused communities

## How To Run
- cd d3xai...
- Create an env file.
- Source the env file
```solidity
   forge test --fork-url $BSC_RPC_URL
```
## References
- **Twitter Analysis**: [suplabsyi thread](https://x.com/suplabsyi/status/1956695597546893598)
- **Attack Transaction**: [BSCScan](https://bscscan.com/tx/0x26bcefc152d8cd49f4bb13a9f8a6846be887d7075bc81fa07aa8c0019bd6591f)
- **Attacker Address**: [BSCScan](https://bscscan.com/address/0x4b63c0cf524f71847ea05b59f3077a224d922e8d)

## Disclaimer
This analysis is for educational purposes only. The code demonstrates how the attack was executed to help developers understand and prevent similar vulnerabilities. Do not use this information for malicious purposes.

## License
SPDX-License-Identifier: UNLICENSED