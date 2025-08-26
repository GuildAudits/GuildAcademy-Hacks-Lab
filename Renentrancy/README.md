# GMX Cross-Contract Reentrancy Exploit Simulation

Minimal implementation demonstrating the GMX cross-contract reentrancy vulnerability that resulted in an ~$89M exploit on Arbitrum.

## Project Structure

```
├── src/
│   ├── ReentrancyAttacker.sol    # Main exploit contract  
│   └── IGMXInterfaces.sol        # GMX protocol interfaces
├── test/
│   └── GMXExploitForked.t.sol    # Mainnet fork test
└── foundry.toml                  # Foundry configuration
```

## The Vulnerability

Cross-contract reentrancy between GMX's OrderBook and Vault contracts:

1. **Setup**: Get $10M USDC, buy GLP at $1.45
2. **Reentrancy**: Call `OrderBook.executeDecreaseOrder()` → triggers fallback  
3. **Manipulation**: During reentrancy, call `Vault.increasePosition()` with manipulated BTC price
4. **Inflation**: Massive short losses inflate GLP price from $1.45 to $27.30
5. **Profit**: Redeem GLP at inflated price for ~$89M profit

### Core attack details

The core of this attack exploits two GMX v1 design behaviors:

- Leverage is enabled during Keeper execution.
- Short entries update the global average short price and size, but short exits do not update the global average in the same way.

By combining those behaviors with a reentrancy window the attacker was able to:

1. Create massive short entries while leverage was permitted during keeper execution.
2. Manipulate the global short average price and aggregate short size by inflating entries without symmetric exits updating the averages.
3. Produce a transient distortion in GLP NAV (per‑share value) while holding GLP.
4. Redeem GLP at the inflated NAV and extract profit.

This combination of Keeper‑time leverage and asymmetric short accounting is the essential root cause behind the exploit.

### Security recommendations 

SlowMist and other audit teams suggested practical mitigations that are reflected in this repo's post‑mortem guidance:

- Add reentrancy locks to critical functions according to business logic (not just per‑contract nonReentrant that can be bypassed cross‑contract).
- Strictly limit how individual variables (e.g., a single trader's entry) can influence global pricing mechanisms; add caps or smoothing factors.
- Strengthen audits and security testing (forked replay tests, invariant checks, cross‑contract unit tests) to detect sequences that produce transient valuation inconsistencies.

These recommendations complement the protocol hardening actions described in the Post‑mortem & mitigations section.

## Real Contracts (Arbitrum)

- **GMX Vault**: `0x489ee077994B6658eAfA855C308275EAd8097C4A`
- **Position Manager**: `0x75E42e6f01baf1D6022bEa862A28774a9f8a4A0C`  
- **OrderBook**: `0x7D3BD50336f64b7A473C51f54e7f0Bd6771cc355`

## Usage

```bash
forge test --match-test testMainnetExploit \
    --fork-url https://arb-mainnet.g.alchemy.com/v2/YOUR_API_KEY \
    # GMX cross-contract reentrancy — concise walkthrough

    This repository contains an educational reproduction of the GMX cross-contract reentrancy incident that was executed on Arbitrum (historical tx and block references included). The code is a simulator for learning and defensive research — do not use it for malicious activity.

    Contents
    - `src/ReentrancyAttacker.sol` — attacker contract implementing the reentrancy flow (cleaned of test cheatcodes).
    - `src/IGMXInterfaces.sol` — minimal GMX interfaces used to interact with on‑chain contracts.
    - `test/GMXExploitForked.t.sol` — Foundry test that forks Arbitrum and runs the exploit flow with test-provided balances.
    - `test/ReplayTx.t.sol` — Foundry test that replays the historical call by impersonating the original executor.
    - `scripts/replay_tx.py` — (tool) reconstruct and resend the historical signed EIP‑1559 tx to a local fork (used to capture a full internal trace).

    Summary of the vulnerability (one-liner)
    - A callback/reentrant path between GMX's OrderBook/PositionManager and the Vault allowed an attacker to re‑enter protocol logic while internal accounting was mid‑update, producing a temporary NAV/pricing distortion and permitting profitable mint/redeem of GLP.

    Key historical facts
    - Exploit tx: `0x03182d3f0956a91c4e4c8f225bbc7975f9434fab042228c7acdc5ec9a32626ef`
    - Exploit block: `355880237` (Arbitrum)
    - Notable contracts (Arbitrum mainnet):
        - Vault: `0x489ee077994B6658eAfA855C308275EAd8097C4A`
        - PositionManager: `0x75E42e6f01baf1D6022bEa862A28774a9f8a4A0C`
        - OrderBook (attacker): `0x7D3BD50336f64b7A473C51f54e7f0Bd6771cc355`

    What the repo reproduces
    - The attacker sequence in high level:
        1. Acquire GLP (pre‑manipulation) using stable assets.
     2. Trigger OrderBook.executeDecreaseOrder → inside that call the attacker contract's fallback re‑enters and calls Vault/PositionManager to manipulate positions and prices.
     3. The intermediate state yields inflated GLP NAV.
     4. Redeem GLP at inflated NAV for profit.

    Reproduction (quick steps)
    1) Install Foundry and anvil (if not already): https://book.getfoundry.sh/
    2) Run tests on an Arbitrum fork (replace YOUR_API_KEY):

    ```bash
    # run the main forked exploit test (forks at the parent block by default)
    forge test -v \
        --fork-url https://arb-mainnet.g.alchemy.com/v2/YOUR_API_KEY \
        --fork-block-number 355880236
    ```



    Notes about the included tests :
    - `GMXExploitForked.t.sol` forks Arbitrum, funds the attacker contract via Foundry cheatcodes (test side), and drives the `executeCompleteAttack()` flow. It includes try/catch fallbacks for real GMX calls that may revert under forked conditions.
    - `ReplayTx.t.sol` shows how to impersonate the original executor and call `PositionManager.executeDecreaseOrder(attacker, orderIndex, executor)` directly 

   



    Contact / where to look in this repo
    - `src/ReentrancyAttacker.sol` — attack sequence and public entrypoints.
    - `src/IGMXInterfaces.sol` — ABIs & function selectors used to decode traces.
    - `test/` — Foundry tests used to run forked experiments.


    Post‑mortem & mitigations
    -------------------------
    

    - Emergency response
        - Pause or disable affected functionality (order execution, GLP manager flows) to stop ongoing losses.
        - Open an incident channel and alert major stakeholders and infrastructure providers.

    - Immediate hardening
        - Patch the vulnerable call path: remove/guard cross‑contract reentrancy windows and add mutexes or broader reentrancy protection.
        - Disable manager flags or privileged modes that enable the exploited sequence until a safe upgrade is deployed.
        - Add conservative input validation and early reverts for suspicious values.

    - Remediation & verification
        - Deploy audited patches (or upgraded proxies) and run forked replay tests to confirm the exploit no longer reproduces.
        - Improve unit and integration coverage to include cross‑contract invariants and snapshot scenarios.
        - Publish deterministic test vectors where possible to support community verification.

    - Community & operations
        - Engage external auditors and bug bounty programs; publish a public post‑mortem when permissible.
        - Coordinate recovery or compensation where feasible and legally permissible.
        - Improve monitoring and on‑chain alerting to detect similar attack patterns earlier.

    - Long‑term controls
        - Rework NAV/pricing flows to rely on atomic snapshots or two‑phase commits rather than mutable mid‑function reads.
        - Limit synchronous external calls inside critical accounting paths and prefer batched or off‑chain settlement patterns where appropriate.
        - Harden governance controls for critical toggles (e.g., manager mode) behind multi‑party checks.

    