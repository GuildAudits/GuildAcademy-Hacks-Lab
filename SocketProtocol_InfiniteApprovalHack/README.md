# 🚨 Socket Protocol Hack PoC (January 2024)

This repository contains a proof-of-concept (PoC) for the **Socket Protocol hack**, where an attacker drained ~$3.3M in tokens due to a vulnerability in the `performAction` function of the Socket Gateway.

---

## 🔎 Context

- **Attacker EOA:** [0x50DF5a2217588772471B84aDBbe4194A2Ed39066](https://etherscan.io/address/0x50DF5a2217588772471B84aDBbe4194A2Ed39066)  
- **Attack Contract:** [0x3a23F943181408EAC424116Af7b7790c94Cb97a5](https://etherscan.io/address/0x3a23F943181408EAC424116Af7b7790c94Cb97a5)  
- **Vulnerable Contract:** [0xcc5fda5e3ca925bd0bb428c8b2669496ee43067e](https://etherscan.io/address/0xcc5fda5e3ca925bd0bb428c8b2669496ee43067e)  
- **Attack Tx:** [0x591d054a9db63f0976e533f447df482bed5f24d7429646570b2108a67e24ce54](https://etherscan.io/tx/0x591d054a9db63f0976e533f447df482bed5f24d7429646570b2108a67e24ce54)  
- **Vulnerable Code (Etherscan):** [performAction](https://etherscan.io/address/0xcc5fda5e3ca925bd0bb428c8b2669496ee43067e#code#F1#L71)  




### 🔍 Inside the Attack

The **Socket Gateway hack** was made possible by a vulnerability in a new module in Socket’s Aggregator system.  
This module’s role was to **swap tokens on the users’ behalf**.

- If a user had granted **infinite approvals** to the Socket Gateway contract, the attacker could drain tokens from the user’s account.  
- Since Socket approvals **default to finite approvals**, only about **200 users** of the protocol were affected.

### ⚠️ Root Cause
- The vulnerable module in the Socket Gateway executed **untrusted user input**.  
- The `swapExtraData` parameter in `performAction` was passed directly into a `call` without validation.  
- This allowed the attacker to **inject a `transferFrom` call** into calldata, draining ERC20 tokens from victims who had granted **infinite approvals**.  
- Approximately **200 users** were affected, with losses totaling **$3.3M**.  

---

### Vulnerability Details
- The new route executed **untrusted user input**.
- When the contract’s `performAction` function was called, the **`swapExtraData` parameter** was not validated before being used in a `call` instruction.
- This allowed the attacker to **inject a malicious `transferFrom` call** into the data.
- As a result, tokens could be drained from wallets with infinite approvals directly into the attacker’s wallet.

---

## 🛠️ How to Run the PoC

This project uses [Foundry](https://book.getfoundry.sh/) for testing.  

### 1. Install Foundry
```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### 2. Install dependencies
```bash
forge install
```

### 3. Build contracts
```bash
forge build

```

### 4. Run the exploit test
```bash
forge test --mt testExploit -vvv
```



