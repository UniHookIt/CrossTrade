// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseHook} from "v4-periphery/src/utils/BaseHook.sol";
import {ERC1155} from "solmate/src/tokens/ERC1155.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "@uniswap/v4-core/src/types/BeforeSwapDelta.sol";
import {Currency} from "v4-core/types/Currency.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {PoolId} from "v4-core/types/PoolId.sol";
import {BalanceDelta} from "v4-core/types/BalanceDelta.sol";
import {SwapParams, ModifyLiquidityParams} from "v4-core/types/PoolOperation.sol";

import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";

import {Hooks} from "v4-core/libraries/Hooks.sol";

contract CrossTradeHook is BaseHook {
    constructor(IPoolManager _manager) BaseHook(_manager) {}

    struct Arbitrage {
        uint256 tokenPrice;
        uint256 slippage;
        uint256 minProfit;
    }

    error InvalidHookData();
    error UnprofitableSwap();
    error InsufficientProfit();

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterAddLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: true,
            afterSwap: false,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    // Monitor token prices across chains here to check for profitable arbitrage oppurtunities
    // If profitable trade is detected initiate a bridge to the target chain
    // Execute the swap on the destination chain for maximizing arbitrage oppurtunities

    function getCurrentGasPrice() public view returns (uint256 gasPrice) {
        gasPrice = uint256(tx.gasprice);
    }

    function _beforeSwap(address sender, PoolKey calldata key, SwapParams calldata params, bytes calldata HookData)
        internal
        override
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        // Custom implementation goes here
        if (HookData.length == 0) revert InvalidHookData();
        Arbitrage memory data = abi.decode(HookData, (Arbitrage));

        if (data.tokenPrice == 0 || data.slippage == 0 || data.minProfit == 0) revert InvalidHookData();

        uint256 amountIn = uint256(params.amountSpecified > 0 ? params.amountSpecified : -params.amountSpecified);
        uint256 fee = key.fee;
        uint256 amountOut;

        if (params.zeroForOne) {
            amountOut = (amountIn * data.tokenPrice * (1000000 - fee)) / (1e18 * 1000000);
        } else {
            // USDC -> ETH: amountIn is USDC (6 decimals), amountOut is ETH (18 decimals)
            amountOut = (amountIn * 1e18 * (1000000 - fee)) / (data.tokenPrice * 1000000);
            // Convert ETH to USDC for profit calc
            amountOut = (amountOut * data.tokenPrice) / 1e18;
        }

        amountOut = amountOut * (10000 - data.slippage) / 10000;

        uint256 estimatedPrice =
            params.zeroForOne ? (amountOut * 1e18) / amountIn : (amountIn * 1e18) / (amountOut * 1e12);

        uint256 requiredPrice = (data.tokenPrice * (1000000 - fee)) / 1000000;
        if (estimatedPrice > requiredPrice) {
            revert UnprofitableSwap();
        }

        uint256 gasPriceWei = getCurrentGasPrice();
        uint256 gasUnits = 100000;
        uint256 gasCostEth = gasPriceWei * gasUnits;
        uint256 gasCostUsdc = (gasCostEth * data.tokenPrice) / 1e18;

        uint256 profitUsdc = amountOut > amountIn ? amountOut - amountIn : 0;
        profitUsdc = profitUsdc > gasCostUsdc ? profitUsdc - gasCostUsdc : 0;

        bool isProfitable = profitUsdc >= data.minProfit;

        if (!isProfitable) revert InsufficientProfit();

        return (this.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }
}
