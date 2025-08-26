# ResupplyFi Vault Attack Analysis

This repository provides an analysis of a critical vulnerability in the Curvelend vault smart contract that allowed an attacker to manipulate the share price and bypass the solvency check, enabling them to borrow up to the vault's full 10M reUSD debt limit with minimal collateral. This document details the attack, its root cause, and recommendations for mitigation.

## Overview

The Curvelend vault is a lending protocol where users deposit collateral (e.g., crvUSD) to borrow assets (reUSD). A solvency check, implemented in the `_isSolvent` function, ensures borrowers maintain a safe loan-to-value (LTV) ratio. However, due to a combination of an empty vault, share price manipulation, and an integer division bug in the Resupply oracle, an attacker was able to bypass this check and borrow 10M reUSD with negligible collateral.

The attack exploited:
- An empty vault with no prior deposits, making share price manipulation feasible.
- A flaw in the Resupply oracle’s `exchangeRate` calculation, which floored to 0 due to EVM integer division.
- The `_isSolvent` function’s reliance on the `exchangeRate`, which, when zero, nullified the LTV check.

## Attack Details

### Step-by-Step Breakdown

1. **Flash Loan**:
   - The attacker took a flash loan of 4,000 USDC from MorphoBlue.
   - They swapped 4,000 USDC for 3.999e21 crvUSD using a Curve pool.

2. **Share Price Manipulation**:
   - The attacker donated 2,000e18 crvUSD to the vault’s controller, increasing the vault’s total assets without minting new shares. This inflated the value of each share.
   - The attacker deposited 2e18 crvUSD into the vault, minting 1 wei (1 * 10^-18) of vault shares.
   - With the vault’s total assets now at 2,000e18 + 2e18 = 2,002e18 crvUSD, the share price became extremely high: 1 wei of shares corresponded to ~2e18 crvUSD, and `convertToAssets(1e18 shares)` returned 2e36 crvUSD.

3. **Oracle Exchange Rate Bug**:
   - The Resupply oracle calculated the price of vault shares using `IERC4626(_vault).convertToAssets(1e18)`, which returned 2e36 crvUSD (the value of 1e18 shares).
   - The `exchangeRate` was computed as:
     ```solidity
     exchangeRate = 1e36 / oracle.getPrices(collateral);
     ```
     - `oracle.getPrices(collateral)` returned 2e36.
     - Thus, `exchangeRate = 1e36 / 2e36 = 0.5`.
     - Due to EVM integer division (which rounds down), `1e36 / 2e36` floored to **0**.

4. **Bypassing the Solvency Check**:
   - The `_isSolvent` function calculated the LTV as:
     ```solidity
     _ltv = ((_borrowerAmount * _exchangeRate * LTV_PRECISION) / EXCHANGE_PRECISION) / _collateralAmount;
     ```
   - With `_exchangeRate = 0`, the numerator became 0, resulting in `_ltv = 0`.
   - Since `_ltv <= _maxLTV` always returned `true`, the attacker was deemed solvent regardless of their actual LTV.

5. **Borrowing and Profiting**:
   - The attacker used the 1 wei of minted shares as collateral in the Resupply protocol.
   - They borrowed 10,000,000 reUSD, the vault’s full debt limit, far exceeding what their collateral should allow.
   - The borrowed reUSD was swapped for 9,300,000 sCrvUSD using another Curve pool.
   - The attacker redeemed sCrvUSD for 9,800,000 crvUSD.
   - Finally, the 9,800,000 crvUSD was swapped back to 9,800,000 USDC, allowing the attacker to repay the 4,000 USDC flash loan and pocket the remaining ~9,796,000 USDC as profit.

### Key Code Vulnerability

The critical vulnerability lies in the `_isSolvent` function and the oracle’s `exchangeRate` calculation:

```solidity
function _isSolvent(address _borrower, uint256 _exchangeRate) internal view returns (bool) {
    ...
    uint256 _ltv = ((_borrowerAmount * _exchangeRate * LTV_PRECISION) / EXCHANGE_PRECISION) / _collateralAmount;
    return _ltv <= _maxLTV;
}