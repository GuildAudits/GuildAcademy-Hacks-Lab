## TITLE
Exploit of PDZ protocol via price manipulation due to bug in reward process.

## ROOT CAUSE
The root cause is a bug in calculating the reward (deserved variable in the contract), as the getAmountsOut function could be easily manipulated. This was the window for the attacker to exploit the contract .

```solidity

function burnToHolder(uint256 amount, address _invitation) external {
        require(amount >= 0, "TeaFactory: insufficient funds");

        address sender = _msgSender();
        if (Invitation[sender] == address(0) && _invitation != address(0) && _invitation != sender) {
            Invitation[sender] = _invitation;
            InvitationList[_invitation].add(sender);
        }
        if (!userList.contains(sender)) {
            userList.add(sender);
        }
        address[] memory path = new address[](2);
        path[0] = address(_burnToken);
        path[1] = uniswapRouter.WETH();
        uint256 deserved = 0;
        deserved = uniswapRouter.getAmountsOut(amount, path)[path.length - 1];
        _burnToken.burnToholder(sender, amount, deserved);
        _BurnTokenToDead(sender, amount);
        burnFeeRewards(sender, deserved);
    }

    ```

