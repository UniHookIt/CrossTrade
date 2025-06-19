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

import "forge-std/Test.sol";
import {CrossTradeHook} from "../src/CrossTradeHook.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import "forge-std/console.sol";

contract CrossTradeHookTest is Test, Deployers {
    CrossTradeHook hook;

    function setUp() public {
        deployFreshManagerAndRouters();
        deployMintAndApprove2Currencies();

        uint160 flags = uint160(Hooks.BEFORE_SWAP_FLAG);
        
        deployCodeTo("CrossTradeHook.sol", abi.encode(manager), address(flags));

        // Deploy our hook
        hook = CrossTradeHook(address(flags));

        (key,) = initPool(
            currency0,
            currency1,
            hook,
            LPFeeLibrary.DYNAMIC_FEE_FLAG, // Set the `DYNAMIC_FEE_FLAG` in place of specifying a fixed fee
            SQRT_PRICE_1_1
        );

        modifyLiquidityRouter.modifyLiquidity(
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

    
}
