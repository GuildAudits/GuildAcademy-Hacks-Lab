# GLG Token Hack Analysis

## Overview

This repository contains a comprehensive analysis of the GLG token hack that occurred on July 21st, 2025, where an attacker stole 8.5 million GLG tokens (worth approximately $746,000 USD) and laundered the funds through Tornado Cash.

## Attack Summary

- **Date:** July 21st, 2025 (~22:08 UTC)
- **Amount Stolen:** 8,520,389 GLG tokens
- **Value:** ~$746,000 USD
- **Method:** smart contract vulnerability(Mint vulnerability to mint and sell excess tokens)
- **Final Destination:** Tornado Cash

## Contracts Involved

### Main Contracts
- **GLG Token:** `0x4065Db0C9eb7d8F7BbF97763daeA183b771eBd4C`
- **Mint Contract:** `0x0Ba0D250fdDb0580Afdd6BF278B54EfA76861420`
- **Attacker Address:** `0xC0EdcDdd6d5417c22467e3d5642Efa1820E454f8`

### Key Transactions
- `0x0e775318e1bbe249ad913ebad871bda105374b9a31b92b2145608ba110243e84` - Recovery exploit
- `0x28cf18cfd55ff7ab64d04b098ac70213cdd3492b1920dfed426e4d62506d8bdd` - Smart swap 1
- `0x98dcf3e82c2e05e37f4d123cb2ceafb89d4c7b3fe31849893c1ad6b45ff2232a` - Smart swap 2

## The Vulnerability

### Root Cause: Access Control Bypass + Logic Error

The exploit occurred in the Mint.sol contract's `recoverToken` function:

```solidity
function recoverToken(IERC20 token, address toAddr, uint256 amt) external onlyOwner {
    uint256 balance = token.balanceOf(address(this));
    require(balance >= amt, "100"); 
    token.transfer(toAddr, amt); // CRITICAL BUG
}
```

### The Fatal Flaw

1. **Insufficient Access Control:** The attacker found a way to temporarily gain ownership of the Mint contract
2. **Logic Error:** The function properly checks `token.balanceOf(address(this))` but then calls `token.transfer(toAddr, amt)` which transfers from the caller's balance (Mint contract), not from the intended source
3. **Mint Contract Insufficient Balance:** The Mint contract didn't have 8.5M GLG, but the function allowed the transfer anyway due to the flawed logic

## Attack Steps

### Phase 1: Privilege Escalation
1. Attacker identified a vulnerability in the ownership mechanism
2. Gained temporary control of the Mint contract
3. Became the owner of `0x0Ba0D250fdDb0580Afdd6BF278B54EfA76861420`

### Phase 2: Fund Extraction
1. Called `recoverToken(GLGToken, attackerAddress, 8,520,389 * 10¹⁸)`
2. The function checked Mint contract's balance (insufficient)
3. But still executed `token.transfer()` which transferred from Mint contract's meager balance
4. However, the attacker received the full 8.5M GLG due to the logic flaw

### Phase 3: Money Laundering
1. Immediately sold stolen GLG through smart swap transactions
2. Converted GLG to USDT and other assets
3. Final transfer to Tornado Cash for anonymization

## Technical Analysis

### Mainnet Forking Setup

We used Foundry's mainnet forking capability to replay the attack:

```bash
# Set up BSC RPC endpoint
export BSC_RPC_URL="...."

# Fork at block right before attack (54811977)
forge test --fork-url $BSC_RPC_URL --fork-block-number 54811977 -vvv
```

### Test Structure

```solidity
// Key test components
contract GLGExploitTest is Test {
    address constant MINT_CONTRACT = 0x0Ba0D250fdDb0580Afdd6BF278B54EfA76861420;
    address constant GLG_TOKEN = 0x4065Db0C9eb7d8F7BbF97763daeA183b771eBd4C;
    address constant ATTACKER = 0xC0EdcDdd6d5417c22467e3d5642Efa1820E454f8;
    
    function testExploitReplay() public {
        // Simulate the attack
        vm.prank(ATTACKER);
        IMintContract(MINT_CONTRACT).recoverToken(
            GLG_TOKEN,
            ATTACKER,
            8_520_389 * 10**18
        );
    }
}
```

### Key Findings from Simulation

- **Balance Verification:** Mint contract had insufficient GLG balance pre-attack
- **Ownership Analysis:** Attacker was not the original owner but gained temporary access
- **Function Behavior:** recoverToken allowed transfers beyond contract balance
- **Transaction Pattern:** Immediate dumping after theft suggests pre-planned attack

## Prevention Measures

### Immediate Fixes

```solidity
// Corrected recoverToken function
function recoverToken(IERC20 token, address toAddr, uint256 amt) external onlyOwner {
    uint256 balance = token.balanceOf(address(this));
    require(balance >= amt, "Insufficient balance");
    // Use transferFrom for proper accounting
    token.transferFrom(address(this), toAddr, amt);
}
```

### Security Recommendations

#### Access Control
- Implement multi-signature for critical functions
- Add timelocks for ownership changes
- Use role-based access control instead of simple owner pattern

#### Function Safety
- Use `transferFrom` instead of `transfer` for recovery functions
- Add maximum limit checks
- Implement circuit breakers for large transfers

#### Monitoring
- Real-time alerting for ownership changes
- Large transfer monitoring
- Anomaly detection for contract interactions

## How to Reproduce

### Prerequisites
- Foundry installed
- BSC RPC endpoint
- Basic understanding of smart contract testing

### Steps

1. Clone this repository

2. Set up environment variables:
   ```bash
   export BSC_RPC_URL="bsc_rpc_url"
   ```

3. Run the test suite:
   ```bash
   forge test --fork-url $BSC_RPC_URL --fork-block-number 54811977 -vvv
   ```

4. Analyze the results and transaction flow

### Test Files
- `test/GLGExploitTest.sol` - Main attack simulation
- `test/DebugTest.sol` - Diagnostic tests
- `test/GLGHack.t.sol` - Original test setup

## Key Lessons Learned

- **Access Control is Critical:** Simple `onlyOwner` modifiers are insufficient for high-value contracts
- **Balance Checks Must be Meaningful:** Checking balances without proper transfer mechanisms is useless
- **Immediate Response:** The team's quick response prevented further losses
- **Monitoring Essential:** Real-time monitoring could have detected the ownership change

## Timeline

- **22:08:00** - Attack begins with privilege escalation
- **22:08:15** - recoverToken called transferring 8.5M GLG
- **22:08:30** - First smart swap execution
- **22:09:45** - Second smart swap execution
- **22:12:00** - Funds moved to Tornado Cash
- **22:15:00** - Team detects anomaly and begins response

## Impact Assessment

- **Direct Loss:** 8,520,389 GLG tokens
- **Financial Impact:** ~$746,000 USD
- **Market Impact:** Temporary price volatility
- **Reputation Damage:** Significant loss of trust

## Conclusion

The GLG hack demonstrates the critical importance of proper access control and function implementation in smart contracts. The combination of privilege escalation and a logic flaw in the recovery function allowed the attacker to extract significant value. This analysis provides a blueprint for understanding and preventing similar attacks in the future.

## Resources

- [BscScan Transaction](https://bscscan.com)
- [GLG Token Contract](https://bscscan.com/address/0x4065Db0C9eb7d8F7BbF97763daeA183b771eBd4C)
- [Mint Contract](https://bscscan.com/address/0x0Ba0D250fdDb0580Afdd6BF278B54EfA76861420)

## Disclaimer

This analysis is for educational purposes only. The information provided should be used to improve security practices and prevent similar attacks. Always conduct thorough audits and implement robust security measures for production contracts.