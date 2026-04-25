# Zora Hack Replay

##  Addresses

- **Settler V1.10 (0x Protocol)** – `0x5C9bdC801a600c006c388FC032dCb27355154cC9` (0x: Settler v1.10 contract on Base)
- **ZORA Token** – (the ZORA ERC20 on Base; used in the airdrop)
- **ZoraTokenCommunityClaim** – `0x0000000002ba96C69b95E32CAAB8fc38bAB8B3F8` (Zora’s Base claim contract)
- **Attacker’s Address** – `0xC834496f208f0D2929f7aaFDDa7b0f66Fd616f70` (received the stolen ZORA)
- **0x: Deployer (Zora)** – `0xBEBE537eFb8377629A1dFB1aC5c0568036E32712` (deployed the claim contract)

## Attack Analysis

A flaw in the ZORA community-claim contract allowed an attacker to hijack tokens allocated to 0x’s address. The attacker crafted a call to the 0x Settler (`execute()`) that triggered a `basicSellToPool` action with the ZORA claim contract as the target. Because the claim contract’s internal `_claimTo(address user, address to)` function did not require `msg.sender == user`, the Settler call caused the contract to issue 0x’s allotted ZORA tokens to the attacker’s address instead.

In simpler words, the attacker sent a transaction to Settler’s `execute()`, causing Settler to “sell” ZORA to the claim contract, which in turn executed the hidden `_claimTo(attacker, attacker)`. Thus, ZORA tokens intended for 0x ended up in the attacker's wallet.

## Detailed Breakdown

- **Attacker calls Settler.execute():** The attacker sent a transaction to the 0x Settler V1.10 contract (address `0x5C9bdC801a600c006c388FC032dCb27355154cC9`) invoking the `execute(...)` function. The transaction input data encoded one action: `basicSellToPool`. In this payload, the `sellToken` was set to the ZORA token address, the `pool` was set to the ZoraTokenCommunityClaim contract address, and the `data` field was an ABI-encoded call to `ZoraTokenCommunityClaim._claimTo(attacker, attacker)`.

- **_dispatch and basicSellToPool:** When `execute()` ran, Settler’s internal _dispatch logic routed this action to `basicSellToPool(...)`. In the Settler code, `basicSellToPool` checks that the pool address is allowed, then performs a low-level call.

- **Call forwarded:** At this point, pool was the ZORA claim contract and data was the encoded `_claimTo(attacker, attacker)`. Because the Settler contract does not restrict calling arbitrary contracts, it forwarded the call.

- **Claim contract executes _claimTo:** The low-level call invoked `ZoraTokenCommunityClaim._claimTo(attacker, attacker)`. Inside the claim contract, `_claimTo` authorizes the transfer of the user’s ZORA allocation to the specified address. Because `_claimTo` does not check that `msg.sender` equals the user, it simply processed the claim. As a result, **ZORA tokens were transferred from the claim contract to the attacker’s address**.

## Preventive Measure

The nature of this hack rests on a particular design choice; lack of access control in the claim contract.  
That is to say; this hack was not necessarily the result of a bug, rather it was because the contract allowed anyone to call `_claimTo` on behalf of a claimant.
A proper design choice would have been the implementation of Merkle proofs, and valid signatures. This just goes to show that every design choice must be properly vetted by both developers and security researchers.

## Post Mortem

Because of this project was an airdrop project, no post mortem was/has been done by the Zora team (*as at my time of research*).

*N.B. A script that replays the attack is in the works and this repo will be updated as soon as it is ready*