# Grazzifi Exploit Simulation

**A comprehensive simulation of the Grazzifi exploit that occurred on August 16, 2025, resulting in approximately $61,000 in bad debt.**

This project demonstrates the vulnerability in the Grizzifi contract, which implements a USDT-based high-yield investment program (HYIP) with a 17-level referral system and team-building milestone rewards program.

## 🚨 Key Information

- **Total Lost**: $61,000 USD
- **Attacker**: [0xe2336b08a43f87a4ac8de7707ab7333ba4dbaf7c](https://bscscan.com/address/0xe2336b08a43f87a4ac8de7707ab7333ba4dbaf7c)
- **Attack Contract**: [0xed35746f389177ecd52a16987b2aac74aa0c1128](https://bscscan.com/address/0xed35746f389177ecd52a16987b2aac74aa0c1128)
- **Vulnerable Contract**: [0x21ab8943380b752306abf4d49c203b011a89266b](https://bscscan.com/address/0x21ab8943380b752306abf4d49c203b011a89266b)
- **Attack Transaction**: [0xdb5296b19693c3c5032abe5c385a4f0cd14e863f3d44f018c1ed318fa20058f7](https://bscscan.com/tx/0xdb5296b19693c3c5032abe5c385a4f0cd14e863f3d44f018c1ed318fa20058f7)

## 📋 Project Overview

The Grizzifi contract is a staking platform that offers multiple investment "plans" with fixed daily returns. The core vulnerability lies in the extremely deep, 17-level referral system and team-building milestone rewards program.

**⚠️ This is for educational purposes only.** The code forks the Binance Smart Chain at block 57482146 to replicate the state before the attack.

## 🏗️ Architecture

- **Test Framework**: Foundry (Forge)
- **Network**: Binance Smart Chain (BSC) fork
- **Block Number**: 57482146
- **Main Token**: BUSD (BEP-20)
- **Vulnerable Contract**: IGrazzifi interface implementation

## 🚀 Setup

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed
- Access to BSC RPC endpoint

### Installation

```bash
# Clone the repository
git clone <your-repo-url>
cd GuildAcademy-Hacks-Lab/Grizzifi_Hack

# Install dependencies
forge install

# Build the project
forge build
```

## 🧪 Testing

### Run the Exploit Simulation

```bash
# Run the main exploit test
forge test --match-test test_exploit -vvv

# Run with higher gas limit if needed
forge test --match-test test_exploit --gas-limit 100000000 -vvv
```

### Test Structure

The `test_exploit()` function simulates the complete attack:

1. **Initial Setup**: Forks BSC at the vulnerable block
2. **Contract Funding**: Attacker funds the attack contract with 5,620 BUSD
3. **Team Creation**: Creates 30 team member contracts
4. **Initialization**: Calls `init()` 5 times to set up referral relationships
5. **Additional Funding**: Transfers 5,020 BUSD for further operations
6. **Mass Contract Creation**: Creates 52+ contracts with plan ID 20
7. **Time Manipulation**: Warps 15 hours to allow rewards accumulation
8. **Exploit Execution**: Calls `withdraw()` to drain the protocol

## 🔍 Key Functions

- `create2()`: Creates 30 team member contracts
- `init()`: Initializes referral relationships
- `create()`: Creates additional contracts based on plan ID
- `withdraw()`: Executes the final exploit

## 📊 Expected Results

After running the exploit simulation, you should see:
- Attacker balance significantly increased
- Grazzifi contract balance drained
- Multiple contract creations and referral relationships established

## 🛠️ Development

### Project Structure

```
├── test/
│   ├── Grazzifi.t.sol          # Main exploit simulation
│   └── interfaces/              # Contract interfaces
├── script/                      # Deployment scripts
└── README.md                    # This file
```

### Adding New Tests

```bash
# Create a new test file
forge test --match-contract YourTestName

# Run specific test function
forge test --match-test test_function_name
```

## 📚 Resources

- [Foundry Book](https://book.getfoundry.sh/)
- [BSC Explorer](https://bscscan.com/)
- [Original Attack Analysis](https://bscscan.com/address/0x21ab8943380b752306abf4d49c203b011a89266b#code)

## ⚠️ Disclaimer

This project is **FOR EDUCATIONAL PURPOSES ONLY**. It demonstrates a real-world vulnerability that was exploited. Do not use this code to attack any live contracts or systems.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
