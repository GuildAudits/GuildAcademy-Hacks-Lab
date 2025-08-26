# Convergence Finance Exploit Report

## Overview

On **August 1, 2024**, the DeFi protocol **Convergence Finance** was exploited for approximately **$210,000**. The exploit targeted the **CvxRewardDistributor contract**, allowing the attacker to mint **58,718,395 CVG tokens** (the entire portion of tokens dedicated to staking emissions). In addition, about **$2,000 worth of unclaimed Convex rewards** were stolen.

- **Root Cause:** Improper input validation in the claimMultipleStaking() function.
- **Attack Vector:** Passing a malicious contract as a staking contract to the distributor.
- **Impact:** 58,718,395 CVG minted and dumped on Curve pools, draining liquidity worth ~$210,000.

## Vulnerable Contract

- **Implementation (logic) — CvxRewardDistributor (code):**
  https://etherscan.io/address/0x47c69e8c909ce626Af73c955A5e34A20B7c71f19#code

- **Proxy / on-chain distributor (used in exploit):**
  https://etherscan.io/address/0x2b083beaaC310CC5E190B1d2507038CcB03E7606



<details>
<summary>The vulnerable function:</summary>

```solidity
    function claimMultipleStaking(
        ICvxStakingPositionService[] calldata claimContracts,
        address _account,
        uint256 _minCvgCvxAmountOut,
        bool _isConvert,
        uint256 cvxRewardCount
    ) external {
        require(claimContracts.length != 0, "NO_STAKING_SELECTED");

        /// @dev To prevent an other user than position owner claims through swapping and grief the user rewards in cvgCVX
        if (_isConvert) {
            require(msg.sender == _account, "CANT_CONVERT_CVX_FOR_OTHER_USER");
        }
        /// @dev Accumulates amounts of CVG coming from different contracts.
        uint256 _totalCvgClaimable;

        /// @dev Array merging & accumulating rewards coming from different claims.
        ICommonStruct.TokenAmount[] memory _totalCvxClaimable = new ICommonStruct.TokenAmount[](cvxRewardCount);

        /// @dev Iterate over all staking service
        for (uint256 stakingIndex; stakingIndex < claimContracts.length; ) {
            ICvxStakingPositionService cvxStaking = claimContracts[stakingIndex];

            /** @dev Claims Cvg & Cvx
             *       Returns the amount of CVG claimed on the position.
             *       Returns the array of all CVX rewards claimed on the position.
             */
            (uint256 cvgClaimable, ICommonStruct.TokenAmount[] memory _cvxRewards) = cvxStaking.claimCvgCvxMultiple(
                _account
            );
            /// @dev increments the amount to mint at the end of function
            _totalCvgClaimable += cvgClaimable;

            uint256 cvxRewardsLength = _cvxRewards.length;
            /// @dev Iterate over all CVX rewards claimed on the iterated position
            for (uint256 positionRewardIndex; positionRewardIndex < cvxRewardsLength; ) {
                /// @dev Is the claimable amount is 0 on this token
                ///      We bypass the process to save gas
                if (_cvxRewards[positionRewardIndex].amount != 0) {
                    /// @dev Iterate over the final array to merge the iterated CvxRewards in the totalCVXClaimable
                    for (uint256 totalRewardIndex; totalRewardIndex < cvxRewardCount; ) {
                        address iteratedTotalClaimableToken = address(_totalCvxClaimable[totalRewardIndex].token);
                        /// @dev If the token is not already in the totalCVXClaimable.
                        if (iteratedTotalClaimableToken == address(0)) {
                            /// @dev Set token data in the totalClaimable array.
                            _totalCvxClaimable[totalRewardIndex] = ICommonStruct.TokenAmount({
                                token: _cvxRewards[positionRewardIndex].token,
                                amount: _cvxRewards[positionRewardIndex].amount
                            });

                            /// @dev Pass to the next token
                            break;
                        }

                        /// @dev If the token is already in the totalCVXClaimable.
                        if (iteratedTotalClaimableToken == address(_cvxRewards[positionRewardIndex].token)) {
                            /// @dev Increments the claimable amount.
                            _totalCvxClaimable[totalRewardIndex].amount += _cvxRewards[positionRewardIndex].amount;
                            /// @dev Pass to the next token
                            break;
                        }

                        /// @dev If the token is not found in the totalRewards and we are at the end of the array.
                        ///      it means the cvxRewardCount is not properly configured.
                        require(totalRewardIndex != cvxRewardCount - 1, "REWARD_COUNT_TOO_SMALL");

                        unchecked {
                            ++totalRewardIndex;
                        }
                    }
                }

                unchecked {
                    ++positionRewardIndex;
                }
            }

            unchecked {
                ++stakingIndex;
            }
        }

        _withdrawRewards(_account, _totalCvgClaimable, _totalCvxClaimable, _minCvgCvxAmountOut, _isConvert);
    }
```
</details>

## Root Cause

- The contract does not validate the input `claimContracts`.
- The attacker passed a malicious contract that implemented the function `claimCvgCvxMultiple()` with a forged return value.
- As a result, the attacker could arbitrarily set `cvgClaimable` to any value, effectively minting the full staking emissions supply (58M CVG).


## Exploit Flow

1. **Attacker Setup**
- Funded via Tornado Cash: [0x912c705958f527b08289320c20Ca6c90463AB572](https://etherscan.io/address/0x912c705958f527b08289320c20ca6c90463ab572#internaltx)

2. **Deploy Malicious Contract**
- The contract mimicked the `claimCvgCvxMultiple(address)` signature.
- Returned an inflated `cvgClaimable` value.

3. **Call Vulnerable Function**
- Passed malicious contract as `claimContracts[]`.
- Exploited the lack of validation.

4. **Mint and Dump**
- Minted **58,718,395 CVG**.
- Swapped CVG for WETH and other assets on Curve.
- Final gains: ~$210,000.


## Key Transactions
- **Exploit transaction:** [0x636be30e58acce0629b2bf975b5c3133840cd7d41ffc3b903720c528f01c65d9](https://etherscan.io/tx/0x636be30e58acce0629b2bf975b5c3133840cd7d41ffc3b903720c528f01c65d9)
- **Malicious contract address:** [0x03560A9D7A2c391FB1A087C33650037ae30dE3aA](https://etherscan.io/address/0x03560A9D7A2c391FB1A087C33650037ae30dE3aA)


# Post Mortem Actions

- **Immediate user alert (Aug 1, 2024)** — Convergence posted an urgent warning asking users not to interact with the protocol. [Tweet](https://x.com/Convergence_fi/status/1819032027842113959)
- **Official post-mortem (Aug 2)** — Project founder published a short post-mortem explaining the root cause (missing input validation in claimMultipleStaking) and urging users to withdraw funds; the team paused CVG emissions. [Medium](https://medium.com/@cvg_wireshark/post-mortem-08-01-2024-e80a49d108a0)
- **On-chain contact with exploiter (Aug 6)** — Convergence sent an on-chain message to the attacker attempting to open negotiations and request return of funds (they framed it as a possible white-hat recovery). [Cointelegraph](https://cointelegraph.com/news/convergence-congratulates-attacker-attempts-open-negotiations)
- **Security alerts & community verification** — Third-party firms (PeckShield, QuillAudits) published immediate technical alerts confirming the 58M CVG mint and swaps; their reports were used to triage the incident. [PeckShield](https://x.com/peckshield/status/1819032859283186120) [QuillAudits](https://x.com/QuillAudits_AI/status/1819049207061225601)
- **Fixes & audits** — Convergence engaged auditors and performed security maintenance; later announcements confirmed audited fixes and that staking/cvgCVX functionality was restored after review. [Tweet](https://x.com/Convergence_fi/status/1844710176886026265)


## Short summary: 

Convergence (1) warned users and paused emissions, (2) published a post-mortem with the root cause, (3) attempted direct contact with the exploiter to recover funds, and (4) coordinated with security firms and auditors to fix and re-open affected functionality.