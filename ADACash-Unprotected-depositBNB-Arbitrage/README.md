# BSC Flash Loan Exploit Simulation - $108K EarnHub Attack

## Overview

This repository simulates the $108K flash loan exploit that occurred on BSC (Binance Smart Chain) against an unverified contract `0x2d70d62deb1cb9918ff6be7bb5d173e8cd4ad854`. The attack leveraged a critical vulnerability in the `depositBNB()` function to manipulate balance calculations and drain ADACash rewards.

## Attack Summary

- **Target Contract**: `0x2d70d62deb1cb9918ff6be7bb5d173e8cd4ad854` (unverified)
- **Attack Amount**: 226 BNB (~$108K at time of attack)
- **Exploit Type**: Balance manipulation + Flash loan + Sandwich attack
- **Root Cause**: Vulnerable `depositBNB()` function using `address(this).balance` instead of `msg.value`
- **Associated Protocol**: EarnHub BSC (rug-pulled in late 2021/early 2022)

## Vulnerability Details

### Critical Flaw: Balance Manipulation

The vulnerable contract's `depositBNB()` function contained a critical flaw:

```solidity
function depositBNB() external payable {
    uint256 amount = address(this).balance; // ❌ VULNERABLE: Should use msg.value
    
    deposits[msg.sender] += amount;
    totalDeposited += amount;
    
    // Calculate rewards based on manipulated amount
    uint256 reward = calculateReward(amount);
    rewards[msg.sender] += reward;
}
```

### Attack Vector

1. **Flash Loan**: Attacker borrows 226 BNB from PancakeSwap
2. **Balance Manipulation**: Sends BNB directly to vulnerable contract
3. **Exploit Call**: Calls `depositBNB()` with minimal amount (0.1 BNB)
4. **Reward Calculation**: Contract records full balance (226.1 BNB) instead of 0.1 BNB
5. **Profit Extraction**: Withdraws inflated deposit amount + claims massive rewards
6. **Loan Repayment**: Repays flash loan with fees
7. **Sandwich Trading**: Profits from ADACash token swaps

## Technical Analysis

### Exploit Flow

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   PancakeSwap   │───▶│   Attacker EOA   │───▶│  Vulnerable     │
│   (Flash Loan)  │    │   Flash Loan     │    │  Contract       │
│   226 BNB       │    │   Execution      │    │  Balance        │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌──────────────────┐
                       │   Manipulation   │
                       │   0.1 BNB sent   │
                       │   226.1 BNB      │
                       │   recorded       │
                       └──────────────────┘
                                │
                                ▼
                       ┌──────────────────┐
                       │   Profit         │
                       │   225.9 BNB      │
                       │   +1.8M ADACash  │
                       └──────────────────┘
```

### Multiplication Factor

- **Input**: 0.1 BNB
- **Recorded**: 226.1 BNB  
- **Multiplication Factor**: 2,261x
- **Reward Multiplier**: 1,800,000 ADACash tokens

## Repository Structure

```
GuildAcademy-Hacks-Lab/
├── src/
│   ├── vulnerable/
│   │   ├── VulnerableDepositBNB.sol    # Simulated vulnerable contract
│   │   └── ADACashMock.sol             # Mock reward token
│   ├── exploits/
│   │   └── FlashLoanExploiter.sol      # Flash loan exploit contract
│   └── interfaces/
│       ├── IPancakePair.sol
│       ├── IPancakeRouter.sol
│       └── IERC20.sol
├── test/
│   ├── FlashLoanExploit.t.sol          # Main exploit simulation
│   └── SandwichAttack.t.sol            # Sandwich attack mechanics
├── script/
│   ├── Deploy.s.sol                    # Deployment script
│   └── Exploit.s.sol                   # Exploit execution script
└── README.md                           # This file
```

## Running the Simulation

### Prerequisites

1. **Foundry Installation**:
   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

2. **Environment Setup**:
   ```bash
   cp .env.example .env
   # Add BSC RPC URL to .env file
   ```

### Test Execution

1. **Basic Vulnerability Test**:
   ```bash
   forge test --match-test testDepositBNBVulnerability -vvv
   ```

2. **Flash Loan Exploit Simulation**:
   ```bash
   forge test --match-test testFlashLoanExploit -vvv
   ```

3. **Real PancakeSwap Integration**:
   ```bash
   forge test --match-test testRealPancakeSwapFlashLoan -vvv
   ```

4. **Full Test Suite**:
   ```bash
   forge test -vvv
   ```

### Expected Output

```
=== BSC Flash Loan Exploit Simulation ===
Attacker initial balance: 10
Vulnerable contract ADACash: 900000

=== Step 1: Manipulate contract balance ===
Sent 226 BNB to vulnerable contract

=== Step 2: Call depositBNB with small amount ===
Amount sent with depositBNB: 0.1 BNB
Amount recorded by contract: 226 BNB
Manipulation factor: 2261

=== Step 3: Check calculated rewards ===
Rewards calculated: 1800000 ADACash tokens

=== Step 4: Withdraw deposited BNB ===
BNB withdrawn: 226

=== Exploit Results ===
Initial attacker balance: 10
Final attacker balance: 236
Net profit from balance manipulation: 225
ADACash rewards available: 1800000

[SUCCESS] Exploit simulation successful!
```

## Key Vulnerabilities Identified

### 1. Balance Manipulation
- **Issue**: Using `address(this).balance` instead of `msg.value`
- **Impact**: Allows inflated deposit recording
- **Fix**: Use `msg.value` for deposit amount

### 2. No Access Control
- **Issue**: No time locks or deposit limits
- **Impact**: Immediate exploitation possible
- **Fix**: Implement proper access controls

### 3. Immediate Reward Calculation
- **Issue**: Rewards calculated instantly on deposit
- **Impact**: No time for detection/intervention
- **Fix**: Implement time-delayed reward calculations

### 4. No Reentrancy Protection
- **Issue**: External calls without guards
- **Impact**: Potential for reentrancy attacks
- **Fix**: Use ReentrancyGuard or Checks-Effects-Interactions

### 5. Manipulable Reward Formula
- **Issue**: Rewards based on contract balance
- **Impact**: Vulnerable to balance manipulation
- **Fix**: Use verifiable, external price feeds

## Post-Mortem Analysis

### Timeline

- **Late 2021/Early 2022**: EarnHub protocol launched on BSC
- **February 2022**: EarnHub rug-pull incident occurs
- **Block 15259040**: Flash loan exploit executed
- **Community Response**: Warning alerts issued by security firms

### Affected Contracts

1. **Primary Target**: `0x2d70d62deb1cb9918ff6be7bb5d173e8cd4ad854`
2. **Associated Funds**: 
   - `0x2505393295847525577f83a8dfcb2f1a908bfe2`
   - `0x961149853ad31c5640ea8081459fabdd94a2a428`

### Community Response

1. **CertiK Alert**: Real-time security warning issued
2. **DeFi Security**: Community education on flash loan risks
3. **Protocol Analysis**: Detailed vulnerability assessment
4. **Best Practices**: Updated security guidelines published

### Lessons Learned

1. **Always verify contracts** before depositing funds
2. **Unverified contracts** pose extreme risks
3. **Flash loans amplify** existing vulnerabilities
4. **Balance manipulation** is a common attack vector
5. **Immediate rewards** create exploitation windows

## Mitigation Strategies

### For Developers

1. **Use `msg.value`** instead of `address(this).balance`
2. **Implement proper access controls** and time locks
3. **Add reentrancy protection** using OpenZeppelin guards
4. **Verify all contracts** on blockchain explorers
5. **Conduct thorough security audits** before deployment

### For Users

1. **Never deposit** to unverified contracts
2. **Research protocols** thoroughly before participating
3. **Start with small amounts** to test functionality
4. **Monitor transactions** for unusual behavior
5. **Stay updated** on security alerts and advisories

## Further Research

### Related Attacks

1. **Flash Loan Attacks**: [Collection of flash loan exploits](https://github.com/SunWeb3Sec/DeFiHackLabs)
2. **Balance Manipulation**: Similar vulnerabilities in DeFi
3. **Reentrancy Attacks**: Classic smart contract vulnerabilities
4. **Sandwich Attacks**: MEV exploitation techniques

### Security Resources

1. **OpenZeppelin**: Security patterns and libraries
2. **Consensys**: Smart contract security best practices
3. **Trail of Bits**: Security audit methodologies
4. **Immunefi**: Bug bounty programs and security research

## Disclaimer

This simulation is for educational purposes only. Do not use this code for illegal activities. Always conduct security research responsibly and follow responsible disclosure practices.

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

MIT License - see [LICENSE](LICENSE) for details.

---

**⚠️ Educational Purpose Only**: This repository demonstrates security vulnerabilities for educational and research purposes. Do not use for malicious activities.