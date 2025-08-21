This is a breakdown of the exploit that happened on June 25th targeting a pre-release leverage contract in the Silo Finance ecosystem. The core lending protocol was never at risk, but a separate experimental contract was exploited, leading to a loss of 224 ETH (~$550k at the time) from the SiloDAO treasury.

No user funds were affected. This was a contained incident, but it's important we're transparent about what happened.

 What Actually Happened?
An attacker found a flaw in an unaudited, pre-release smart contract called LeverageUsingSiloFlashloanWithGeneralSwap. This contract was designed to let users take out leveraged positions using Silo's core markets.

The bug was in how the contract handled input data (swapArgs). The attacker crafted malicious data that tricked the contract into borrowing a large amount of ETH on behalf of the victim's address (which was the SiloDAO treasury) and sending the borrowed funds directly to the attacker's wallet.It was essentially a sophisticated permissions bypass. The attacker never had direct access to the vault, but they manipulated the contract into using the access that the treasury had already granted to it.

A Deeper Look: The Root Cause
Let's get into the weeds. The problem wasn't in Silo's core code. It was in this auxiliary leverage contract.

The vulnerable function looked something like this (simplified):

solidity
function leverage(
    address _silo,
    address _assetToSupply,
    address _assetToBorrow,
    uint256 _supplyAmount,
    uint256 _borrowAmount,
    bytes calldata _swapArgs // <-- This was the problem
) external {
    // ... logic to perform a flash loan and create a position ...
    _executeSwap(_swapArgs); // The malicious data was executed here
}
The _swapArgs parameter was meant to contain encoded data to execute a swap on a DEX like Uniswap. However, the contract didn't properly validate this data before executing it.

The Attack Flow:

The Setup: The SiloDAO treasury (0x60ba...) had previously given this leverage contract a large allowance to borrow WETH on its behalf. This was a standard setup for the contract's intended function.

The Crafty Input: The attacker called the leverage() function but passed in maliciously encoded _swapArgs.

The Trick: Instead of swap instructions, this data encoded a call to the borrow() function of the core Silo protocol. Crucially, it set the parameters to:

Borrower: The victim's address (SiloDAO treasury).

Receiver: The attacker's own address.

Asset: WETH.

Amount: 224 ETH.

The Execution: The vulnerable contract blindly passed this call through. So, when it executed _executeSwap(_swapArgs), it was actually calling Silo.borrow(224 ether, victim, attacker).

The Result: The core Silo protocol checked if the victim had sufficient collateral and allowance. It did. So, it faithfully borrowed the funds and sent them to the attacker. The protocol's solvency checks worked perfectly; the exploit was in abusing the permissions granted to the middle-man contract.

Key Addresses Involved
Attacker Address 1: 0x04377cfaF4b4A44bb84042218cdDa4cEBCf8fd62

Attacker Address 2: 0x03aF609EC30Af68E4881126f692C0AEC150e84e3

Attack Contract: 0x79C5c002410A67Ac7a0cdE2C2217c3f560859c7e

Vulnerable Contract: 0xCbEe4617ABF667830fe3ee7DC8d6f46380829DF9

Victim (SiloDAO): 0x60baf994f44dd10c19c0c47cbfe6048a4ffe4860

Initial Funding TX: The attacker funded their wallet from Tornado Cash: 0xb8567f70d61c070ac298ae9924bacdaac8bdbec8c7d71fa0e5d2fab030ddf035

Response & Lessons Learned
The team responded quickly. You can see their attempt to interact with the attacker's contract in this TX: 0x539ae567fc6ade3cf089c593855855a7522176b8ab48b8613a6a71ce1b67950b.

What we're doing differently now:

Stricter Access Controls: Experimental contracts will have far more limited permissions, especially those interacting with treasury funds.

Robust Input Validation: Any function accepting generic bytes calldata for external calls will have stringent validation and sanity checks before execution. No more blind delegation.

Enhanced Auditing: Pre-release contracts, even those considered "peripheral," will undergo the same rigorous audit and formal verification processes as our core protocol before any treasury funds are ever allocated to them.

Better Communication: We'll be clearer to the community about which parts of the system are fully battle-tested and which are still in an experimental phase.




