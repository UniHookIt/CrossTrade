// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";

import {Deployers} from "@uniswap/v4-core/test/utils/Deployers.sol";
import {PoolSwapTest} from "v4-core/test/PoolSwapTest.sol";
import {MockERC20} from "solmate/src/test/utils/mocks/MockERC20.sol";

import {PoolManager} from "v4-core/PoolManager.sol";
import {SwapParams, ModifyLiquidityParams} from "v4-core/types/PoolOperation.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {LPFeeLibrary} from "v4-core/libraries/LPFeeLibrary.sol";

import {Currency, CurrencyLibrary} from "v4-core/types/Currency.sol";
import {PoolId} from "v4-core/types/PoolId.sol";

import {Hooks} from "v4-core/libraries/Hooks.sol";
import {TickMath} from "v4-core/libraries/TickMath.sol";
import {SqrtPriceMath} from "v4-core/libraries/SqrtPriceMath.sol";
import {LiquidityAmounts} from "@uniswap/v4-core/test/utils/LiquidityAmounts.sol";
import {BalanceDelta} from "v4-core/types/BalanceDelta.sol";

import "forge-std/Test.sol";
import {CrossTradeHook} from "../src/CrossTradeHook.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import "forge-std/console.sol";

contract CrossTradeHookTest is Test, Deployers {
    CrossTradeHook hook;
    MockERC20 usdc;
    address constant NATIVE_ETH = address(0);
    address usdcAddress;

    function setUp() public {
        deployFreshManagerAndRouters();

        usdc = new MockERC20("USDC", "USDC", 6);
        usdcAddress = address(usdc);

        usdc.mint(address(this), 1_000_000 * 10 ** 18);
        usdc.approve(address(swapRouter), type(uint256).max);
        usdc.approve(address(modifyLiquidityRouter), type(uint256).max);

        uint160 flags = uint160(Hooks.BEFORE_SWAP_FLAG);

        deployCodeTo("CrossTradeHook.sol", abi.encode(manager), address(flags));

        // Deploy our hook
        hook = CrossTradeHook(address(flags));

        (key,) = initPool(
            Currency.wrap(NATIVE_ETH),
            Currency.wrap(usdcAddress),
            hook,
            3000, // Set the `DYNAMIC_FEE_FLAG` in place of specifying a fixed fee
            SQRT_PRICE_1_1
        );

        usdc.mint(address(this), 250_000 * 10 ** 6);
        modifyLiquidityRouter.modifyLiquidity{value: 100 ether}(
            key,
            ModifyLiquidityParams({tickLower: -60, tickUpper: 60, liquidityDelta: 100 ether, salt: bytes32(0)}),
            ZERO_BYTES
        );

        vm.txGasPrice(10 gwei);
    }

    function testGetGasPrice() public {
        // Test getCurrentGasPrice returns tx.gasprice
        uint256 gasPrice = hook.getCurrentGasPrice();
        assertEq(gasPrice, 10 gwei, "Gas price should match tx.gasprice");
    }

    function testBeforeSwap_ETHtoUSDC_Profitable() public {
        CrossTradeHook.Arbitrage memory data =
            CrossTradeHook.Arbitrage({tokenPrice: 1000 * 10 ** 18, slippage: 1000, minProfit: 5 * 10 ** 6});
        bytes memory hookData = abi.encode(data);

        SwapParams memory swapParams = SwapParams({zeroForOne: true, amountSpecified: 1 ether, sqrtPriceLimitX96: TickMath.getSqrtPriceAtTick(-120)});

        console.log("USDC balance before swap:", usdc.balanceOf(address(this)));
        console.log("Allowance for swapRouter:", usdc.allowance(address(this), address(swapRouter)));

        BalanceDelta delta = swapRouter.swap{value: 1 ether}(
            key, swapParams, PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false}), hookData
        );
        int128 amount1 = delta.amount1();
        require(amount1 >= 0, "Negative USDC amount");
        // uint256 usdcReceived = uint256(amount1);
        console.log("Received USDC:", amount1);
        assertGt(amount1, int256(data.minProfit));
    }

    function testBeforeSwap_ETHtoUSDC_Unprofitable() public {
        CrossTradeHook.Arbitrage memory data = CrossTradeHook.Arbitrage({
            tokenPrice: 2500 * 10**18,
            slippage: 10000, // 10%
            minProfit: 10000 * 10**6 // 10,000 USDC, too high
        });
        bytes memory hookData = abi.encode(data);

        SwapParams memory swapParams = SwapParams({
            zeroForOne: true,
            amountSpecified: 1 ether,
            sqrtPriceLimitX96: TickMath.getSqrtPriceAtTick(-120)
        });

        vm.expectRevert();
        swapRouter.swap{value: 1 ether}(
            key,
            swapParams,
            PoolSwapTest.TestSettings({takeClaims: false, settleUsingBurn: false}),
            hookData
        );
    }
}
