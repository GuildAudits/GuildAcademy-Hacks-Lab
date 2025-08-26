# Thetanuts Finance Hack Analysis

**Analyst**: ibrahimatix0x01  
**Protocol**: Thetanuts Finance  
**Date**: January 22, 2025  
**Loss**: $125,000  
**Vulnerability**: Arbitrary Call Vulnerability  
**Assignment**: GuildAudits Academy Hacks Lab

## Executive Summary

On January 22, 2025, Thetanuts Finance, a decentralized on-chain options protocol focused on altcoin options, suffered a security breach resulting in approximately $125,000 in losses. The attack exploited an arbitrary call vulnerability within one of the protocol's smart contracts, allowing the attacker to execute unauthorized operations and drain funds.

This repository contains a comprehensive analysis and simulation of the attack, created as part of the GuildAudits Academy Hacks Lab assignment.

## Protocol Overview

### What is Thetanuts Finance?

Thetanuts Finance is a decentralized on-chain options protocol that specializes in altcoin options trading. The protocol allows users to take both long and short positions on various altcoin options through its innovative v3 architecture.

**Key Features:**
- **Basic Vaults**: Sell out-of-the-money (OTM) European cash-settled options to market makers
- **AMM Integration**: Uniswap v3-based liquidity pools for option tokens
- **Lending Market**: Aave v2-inspired lending/borrowing functionality
- **Multi-chain Support**: Operations across multiple blockchain networks
- **Altcoin Focus**: Largest coverage of altcoin options in DeFi

### Protocol Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Thetanuts Finance v3                     │
├─────────────────┬─────────────────┬─────────────────────────┤
│   Basic Vaults  │   AMM Pools     │    Lending Market       │
│                 │                 │                         │
│ • Call Vaults   │ • XYZ-C/XYZ     │ • Supply/Borrow         │
│ • Put Vaults    │ • XYZ-P/USDC    │ • Leveraged Positions   │
│ • LP Tokens     │ • Trading Fees  │ • Liquidations          │
└─────────────────┴─────────────────┴─────────────────────────┘
```

## Project Structure

```
Thetanuts-Finance-Arbitrary-Call/
├── src/
│   ├── ThetanutsHackAnalysis.sol    # Main analysis contract
│   ├── interfaces/
│   │   └── IThetanuts.sol           # Protocol interfaces
│   └── mocks/                       # Mock contracts for testing
├── test/
│   └── ThetanutsHackAnalysis.t.sol  # Test suite
├── script/
│   └── Deploy.s.sol                 # Deployment scripts
├── docs/                            # Additional documentation
├── foundry.toml                     # Foundry configuration
├── .env.example                     # Environment variables template
├── .gitignore                       # Git ignore rules
└── README.md                        # This file
```

## Setup Instructions

### Prerequisites

- Git
- Foundry (latest version)
- Node.js (optional, for additional tools)

### Installation

1. **Install Foundry**:
```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

2. **Clone and setup the project**:
```bash
git clone https://github.com/ibrahimatix0x01/GuildAcademy-Hacks-Lab
cd GuildAcademy-Hacks-Lab/Thetanuts-Finance-Arbitrary-Call
```

3. **Install dependencies**:
```bash
forge install OpenZeppelin/openzeppelin-contracts
forge install foundry-rs/forge-std
```

4. **Set up environment variables**:
```bash
cp .env.example .env
# Edit .env with your API keys (see API Keys section below)
```

5. **Build the project**:
```bash
forge build
```

6. **Run tests**:
```bash
forge test -vvvv
```

### API Keys

You'll need the following API keys in your `.env` file:

- **Alchemy API Key**: Get from [alchemy.com](https://alchemy.com) (free tier available)
- **Etherscan API Key**: Get from [etherscan.io/apis](https://etherscan.io/apis) (free)

Update your `.env` file:
```bash
ALCHEMY_API_KEY=your_alchemy_api_key_here
ETHERSCAN_API_KEY=your_etherscan_api_key_here
RPC_URL=https://eth-mainnet.alchemyapi.io/v2/${ALCHEMY_API_KEY}
```

## Vulnerability Analysis

### Arbitrary Call Vulnerability

An arbitrary call vulnerability occurs when a smart contract allows external callers to specify:
1. Target contract address
2. Function signature/calldata  
3. Value to send (ETH)

Without proper validation or access controls, this creates a critical security risk.

### Known Information

| Detail | Value |
|--------|-------|
| **Date** | January 22, 2025 |
| **Loss Amount** | $125,000 USD |
| **Vulnerability Type** | Arbitrary call in smart contract method |
| **NUTS Token Address** | `0x23f3D4625AEF6f0b84d50dB1d53516e6015c0c9B` |
| **Detection** | CertiK Alert |
| **Reference** | [CertiK Alert Tweet](https://x.com/CertikAlert/status/1881941856264855973) |

## Research Progress

### Completed ✅
- [x] Basic project setup and Foundry configuration
- [x] Protocol architecture research and documentation
- [x] NUTS token contract identification
- [x] Security audit history research
- [x] Initial vulnerability analysis framework
- [x] Test suite setup

### In Progress 🔄
- [ ] Exploit transaction hash identification
- [ ] Vulnerable contract address discovery
- [ ] Attacker address and transaction analysis
- [ ] Attack vector reconstruction

### Pending ⏳
- [ ] Exploit simulation implementation
- [ ] Fund flow analysis
- [ ] Post-mortem protocol response documentation
- [ ] Prevention measures analysis
- [ ] Final report and article preparation

## Usage

### Running Analysis

```bash
# Run the main exploit simulation (once implemented)
forge test --match-test testThetanutsArbitraryCallExploit -vvvv

# Run contract discovery research
forge test --match-test testContractDiscovery -vvvv

# Run protocol analysis
forge test --match-test testProtocolAnalysis -vvvv

# Run all tests
forge test -vvvv
```

### Simulation with Mainnet Fork

```bash
# Run tests against mainnet fork
forge test --fork-url $RPC_URL --fork-block-number 21596000 -vvvv
```

## Research Methodology

### Phase 1: Information Gathering
1. **Transaction Analysis**: Identify the exploit transaction hash
2. **Contract Mapping**: Locate all involved smart contracts
3. **Attack Vector Analysis**: Understand the specific vulnerability
4. **Fund Flow Tracking**: Map how funds were extracted

### Phase 2: Simulation Development
1. **Environment Setup**: Configure Foundry for accurate simulation
2. **Contract Recreation**: Mock or interface with actual contracts
3. **Attack Implementation**: Code the exact exploit steps
4. **Verification**: Ensure simulation matches real attack

### Phase 3: Analysis and Documentation
1. **Root Cause Analysis**: Identify why the vulnerability existed
2. **Impact Assessment**: Calculate exact losses and affected parties
3. **Response Analysis**: Document protocol and community response
4. **Prevention Measures**: Recommend security improvements

## Technical Implementation

### Main Analysis Contract

The core analysis is implemented in `src/ThetanutsHackAnalysis.sol`, which includes:

- **Setup Functions**: Fork configuration and environment setup
- **Research Functions**: Contract discovery and protocol analysis
- **Exploit Simulation**: Step-by-step attack recreation
- **Verification Functions**: Confirm exploit success and impact

### Key Features

- **Mainnet Forking**: Accurate simulation using historical blockchain state
- **Comprehensive Logging**: Detailed console output for analysis
- **Modular Design**: Separate functions for each phase of analysis
- **Test Coverage**: Complete test suite for verification

## Security Considerations

### Pre-Hack Security Measures

Thetanuts Finance had several security measures in place:
- **Multiple Audits**: Peckshield, Zokyo, Akira Tech, X41 D-Sec
- **100% Collateralized Vaults**: Reduced insolvency risk
- **Battle-tested Infrastructure**: Based on Aave v2 and Uniswap v3
- **Established Track Record**: 2+ years of operation

### Post-Hack Implications

The exploit highlights the importance of:
- **Input Validation**: Strict validation of all external inputs
- **Access Controls**: Proper permission management
- **Monitoring Systems**: Real-time attack detection
- **Emergency Procedures**: Quick response mechanisms

## Contributing

This project is part of the GuildAudits Academy assignment. However, suggestions and improvements are welcome:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## Educational Purpose

This analysis is created for educational purposes to:
- Understand common DeFi vulnerabilities
- Learn proper security analysis techniques
- Improve smart contract security practices
- Share knowledge with the DeFi community

## References

### Primary Sources
- [CertiK Alert](https://x.com/CertikAlert/status/1881941856264855973) - Initial vulnerability report
- [Thetanuts Finance Documentation](https://docs.thetanuts.finance/) - Protocol documentation
- [NUTS Token Contract](https://etherscan.io/token/0x23f3d4625aef6f0b84d50db1d53516e6015c0c9b) - Token details

### Educational Resources
- [DeFiHackLabs](https://github.com/SunWeb3Sec/DeFiHackLabs) - DeFi hack simulations
- [Smart Contract Security Best Practices](https://consensys.github.io/smart-contract-best-practices/)
- [Foundry Documentation](https://book.getfoundry.sh/) - Testing framework

### Community Resources
- [Rekt.news](https://rekt.news/) - DeFi incident database
- [GuildAudits Academy](https://github.com/GuildAudits/GuildAcademy-Hacks-Lab) - Original assignment repository

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Disclaimer

This analysis is for educational purposes only. The simulation aims to understand the vulnerability and improve smart contract security practices. This work is not affiliated with Thetanuts Finance and does not constitute financial or security advice.

---

**Status**: 🚧 Research Phase Active  
**Last Updated**: August 20, 2025  
**Next Update**: After exploit transaction identification

**Contact**: ibrahimatix0x01 - GuildAudits Academy Participant