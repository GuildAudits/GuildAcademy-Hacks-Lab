# Guild Academy Hacks Lab

This repository contains various smart contract vulnerability analysis and exploit simulations for educational purposes.

## Available Attack Analysis

### [ADACash-Unprotected-depositBNB-Arbitrage](./ADACash-Unprotected-depositBNB-Arbitrage/)

**Protocol**: ADACash  
**Attack Vector**: Unprotected depositBNB + Arbitrage via Sandwich  
**Loss**: $108,000  
**Date**: 2025-02-08  

A sophisticated arbitrage attack that exploited an unprotected `depositBNB()` function in the ADACash protocol. The attacker used sandwich attack techniques to manipulate the contract's balance calculation and drain approximately $108,000 worth of funds.

**Key Vulnerability**: The `depositBNB()` function was unprotected and vulnerable to arbitrage manipulation, allowing attackers to exploit the contract through sandwich attack patterns.

**Files Included**:
- Complete exploit simulation
- Vulnerable contract recreation
- Flash loan attack implementation
- Technical analysis and documentation
- Test cases and deployment scripts

## Getting Started

Each attack analysis folder contains:
- `README.md` - Detailed attack explanation
- `ATTACK_ANALYSIS.md` - Technical deep dive
- `src/` - Smart contract source code
- `test/` - Exploit simulation tests
- `script/` - Deployment and execution scripts

## Prerequisites

- Foundry (for running simulations)
- Solidity knowledge
- Understanding of DeFi protocols

## Educational Purpose

⚠️ **DISCLAIMER**: This repository is for educational purposes only. All exploits are simulations of historical attacks. Do not use this code maliciously or against live contracts.

## Contributing

When adding new attack analyses, please:
1. Create a folder named `{Protocol}-{AttackVector}`
2. Include complete documentation
3. Provide working exploit simulations
4. Follow the existing structure

## License

Educational use only. See individual folders for specific licensing information.
