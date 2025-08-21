# Mobius Token Exploit Postmortem

## Overview
On May 11, 2025, the Mobius Token contract on Binance Smart Chain (BSC) was exploited in a complex attack involving a vulnerable proxy contract. The attacker used a small amount of BNB, wrapped it into WBNB, interacted with the Mobius proxy, and then dumped large amounts of $MBU tokens into BUSD through PancakeSwap. The attack resulted in the extraction of millions of MBU tokens, which were swapped for stablecoins and laundered through Tornado Cash.  

---

## Simple Breakdown of the Attack
The Mobius Token exploit was **a proxy misconfiguration and logic flaw** that allowed the attacker to inflate token balances and dump them into liquidity pools. Here’s the flow:

1. **Initial Funding**: The attacker funded their address through Tornado Cash for anonymity.  

2. **Setup**: 
   - Deposited a tiny amount of WBNB (~0.001 ETH worth) into the vulnerable Mobius proxy contract.  
   - This step tricked the proxy into minting or crediting an abnormally large number of MBU tokens (due to a logic flaw).  

3. **Token Dump**:  
   - The attacker approved PancakeSwap’s router for unlimited MBU tokens.  
   - Executed a swap of ~30,000,000 MBU for BUSD via `swapExactTokensForTokensSupportingFeeOnTransferTokens`.  

4. **Profit Extraction**:  
   - The attacker transferred the obtained BUSD stablecoins back to their externally owned account (EOA).  
   - Extra calls to another contract (BlockRazor) helped disguise transactions or pay MEV execution fees.  

---

## Contract Addresses
- Exploit Transaction: `https://bscscan.com/tx/0x2a65254b41b42f39331a0bcc9f893518d6b106e80d9a476b8ca3816325f4a150`
- Attacker: `https://bscscan.com/address/0xb32a53af96f7735d47f4b76c525bd5eb02b42600`
- Attacker’s Contract: `https://bscscan.com/address/0x631adff068d484ce531fb519cda4042805521641`

- wBNB: `0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c`
- PancakeSwap router: `0x10ED43C718714eb63d5aA57B78B54704E256024E`
- BUSD: `0x55d398326f99059fF775485246999027B3197955`
- MBU Token: `0x0dFb6Ac3A8Ea88d058bE219066931dB2BeE9A581`
- Mobius (Vulnerable) proxy contract: `0x95e92B09b89cF31Fa9F1Eca4109A85F88EB08531`

---

## Attack Analysis

### Root Cause
The **Mobius proxy contract** (`0x95e92B09b89cF31Fa9F1Eca4109A85F88EB08531`) contained **broken accounting logic**. 
When the user deposited WBNB, the contract called `getBNBPriceInUSDT()` to get the value of the deposited tokens. The flaw in this calculation consists of returning the amount with decimals `(x * 10**18)` and then performing the same multiplication again, resulting in the caller being minted `10*18` more MBU tokens that expected.
By depositing WBNB, the attacker manipulated the contract’s internal balance tracking, receiving far more MBU tokens than intended.  

This flaw essentially allowed the attacker to mint tokens at a massive discount.  

---

### Attack Flow
1. **Preparation**:  
   - Attacker funded through Tornado Cash.  
   - Wrapped a small amount of BNB into WBNB.  

2. **Proxy Abuse**:  
   - Called `deposit(wbnb, 0.001 ether)` on the vulnerable proxy.  
   - Received a disproportionately large credit of MBU tokens due to flawed logic.  

3. **Token Dump**:  
   - Approved PancakeSwap router.  
   - Swapped inflated supply of MBU → BUSD.  

4. **Payout**:  
   - Attacker contract transferred stolen BUSD back to attacker’s wallet.  
   - Extra call to “BlockRazor” contract served as a transaction obfuscation step.  

5. **Exit**:  
   - Funds siphoned into Tornado Cash for laundering.  

---
### Reproduction steps:

   The test can be run using:
`forge test --match-test test_Exploit -vvv`

---

1. **Fork Setup**:
    The test forks Binance Smart Chain Mainnet (BSC) just before block 49,470,430 using the state as it was right before the exploit occured on-chain.

---

2. **Convert BNB to WBNB**:
    The attack() begins with the attacker calling `IWBNB(payable(wbnb)).deposit{value: 0.001 ether}();`
    This wraps a small portion (0.001 ETH in test terms, 0.001 BNB on the actual fork) into WBNB.

---

3. **Deposit WBNB into Vulnerable Proxy**:
    The attacker approves the VulnerableProxy contract to pull WBNB:
    `IERC20(wbnb).approve(VulnerableProxy, 0.001 ether);`.

    Then deposits into the vulnerable Mobius proxy contract:
    `IVulnerableProxy(VulnerableProxy).deposit(wbnb, 0.001 ether);`

    <b>This deposit is the key step: the proxy mints an excessive (mispriced) amount of Mobius (MBU) tokens back to the attacker.</b>
    The imbalance comes from how the proxy contract calculated shares or issued MBU tokens — a mispricing vulnerability.

---

4. **Prepare to Dump MBU Tokens**:
    Attacker holds inflated MBU and grants the PancakeSwap Router infinite allowance to spend MBU:

    `IERC20(MBU).approve(router, type(uint256).max);`

---

5. **Swap MBU → BUSD**:
    Attacker swaps the MBU tokens on PancakeSwap for BUSD:

    `IPancakeRouter(router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
    30_000_000 ether, 0, path, address(this), block.timestamp); `

    This drains liquidity pools by exchaning the manipulated MBU balance into real stablecoins (BUSD).

---

6. **Transfer Profits**:

    After the swap, the contract transfers all BUSD balance back to the attacker’s EOA:

    `IERC20(BUSD).transfer(msg.sender, IERC20(BUSD).balanceOf(address(this)));`

---

7. **Obfuscate with BlockRazor**:

    At the end of the transaction, the attacker makes an extra call to BlockRazor:

    `BlockRazor.call{value: 0.999 ether}("");`

    This obfuscates on-chain traces. 0.999 BNB Payment is made to pay for the transaction routing via MEV-protected relays.

---

## Damage Assessment
- **Stolen Amount**: ~30 million MBU tokens swapped into BUSD.  
- **Impact**:  
  - PancakeSwap liquidity pools for MBU were drained.  
  - Holders of MBU suffered a sharp price collapse as liquidity was removed.  
  - Estimated losses were **several hundred thousand USD equivalent** at the time.  

---

## Immediate Response
- The Mobius Token team attempted to pause affected contracts.  
- Community alerts spread quickly, flagging the exploit as a proxy misconfiguration/mint logic flaw.  
- Exchanges were notified to blacklist attacker addresses, but funds were already mixed via Tornado Cash.  
- Liquidity for MBU was severely impacted, effectively rendering the token valueless.  

---

## Lessons Learned & Prevention

1. **Root Cause Fixes**:  
   - Audit proxy upgradeability contracts carefully.  
   - Ensure accounting logic (deposits/mints) is properly validated.  

2. **Security Practices**:  
   - Adopt OpenZeppelin audited proxy patterns.  
   - Implement checks-effects-interactions (CEI) ordering to prevent manipulation.  
   - Cap maximum deposits or enforce stricter sanity checks when minting.  

3. **Monitoring & Response**:  
   - Real-time monitoring for unusual minting or swaps.  
   - Faster pause mechanisms on proxy-based contracts.  

4. **Ecosystem Measures**:  
   - Exchanges can set up filters for sudden, disproportionate token inflows.  
   - Projects should maintain active bug bounty programs to catch flaws before exploitation.  

---

## Conclusion
The Mobius exploit highlights how **small proxy misconfigurations** can cascade into **massive token inflation and liquidity drain attacks**.  
Unlike classical reentrancy, this attack abused flawed deposit logic and took advantage of PancakeSwap liquidity to convert inflated tokens into stablecoins.  

Once again, this underscores the importance of:  
- Proxy-safe development practices.  
- Comprehensive auditing.  
- Proactive monitoring for anomalous behavior.  

Resources:
https://x.com/blockaid_/status/1921476644092452922
https://x.com/CertikAlert/status/1921483904483000457