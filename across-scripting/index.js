require('dotenv').config();
const { ethers } = require('ethers');
const { AcrossBridge, CONFIG } = require('./scripts/across-bridge');
const { fetchAndLog } = require('./oracle_impl');

const PRIVATE_KEY = process.env.PRIVATE_KEY;
const USER_WALLET_ADDRESS = process.env.USER_WALLET_ADDRESS;

async function dynamicBridgeExample() {
  if (!PRIVATE_KEY) {
    throw new Error('Please set PRIVATE_KEY environment variable');
  }

  if (!USER_WALLET_ADDRESS) {
    throw new Error('Please set USER_WALLET_ADDRESS environment variable');
  }

  // Initialize bridge (set to true for testnet)
  const bridge = new AcrossBridge(PRIVATE_KEY, true);

  // RPC URLs for testnets - replace with your preferred providers
  const rpcUrls = {
    11155111: process.env.ETHEREUM_SEPOLIA_RPC,
    80001: process.env.POLYGON_RPC,
    84532: process.env.BASE_RPC,
    42161: process.env.ARBITRUM_RPC,
    10: process.env.OPTIMISM_RPC
  };

  await bridge.initializeProviders(rpcUrls);

  try {
    console.log('🔍 Starting dynamic bridge ...');
    
    // EXAMPLE 1: Bridge USDC from Base Sepolia to Sepolia
    console.log('\n📋 EXAMPLE 1: Bridge USDC from Base Sepolia to Sepolia');
    
    // const usdcBridgeParams = {
    //   tokenSymbol: 'USDC',
    //   originChainId: 84532, // Base Sepolia
    //   destinationChainId: 11155111, // Sepolia
    //   amount: (8 * 1e6).toString(), // 10 USDC (6 decimals)
    //   recipient: USER_WALLET_ADDRESS 
    // };

    const usdcBridgeParams = await fetchAndLog();
    console.log("return data", usdcBridgeParams)

    console.log('🧪 Running USDC bridge dry run...');
    const usdcDryRun = await bridge.dryRun(usdcBridgeParams);
    
    if (usdcDryRun.canProceed) {
      console.log('✅ USDC bridge can proceed!');
      console.log(`💰 You need ${ethers.formatUnits(usdcDryRun.fees.gasCost, 18)} ETH for gas`);
      
      const usdcResult = await bridge.executeDynamicBridge(usdcBridgeParams);
      console.log('🎉 USDC Bridge result:', usdcResult);
    } else {
      console.log('❌ USDC bridge cannot proceed:', usdcDryRun.error);
    }


  } catch (error) {
    console.error('💥 Dynamic bridge example failed:', error.message);
    
    // Enhanced error handling
    bridge.handleBridgeError(error);
  }
}

// Alternative: Simple bridge function that accepts any token
async function simpleBridge(tokenSymbol, fromChain, toChain, amount, recipient) {
  const PRIVATE_KEY = process.env.PRIVATE_KEY;
  const bridge = new AcrossBridge(PRIVATE_KEY, true);

  const rpcUrls = {
    11155111: process.env.ETHEREUM_SEPOLIA_RPC,
    84532: process.env.BASE_RPC
  };

  await bridge.initializeProviders(rpcUrls);

  const params = {
    tokenSymbol,
    originChainId: fromChain,
    destinationChainId: toChain,
    amount,
    recipient
  };

  console.log(`🌉 Bridging ${ethers.formatUnits(amount, 18)} ${tokenSymbol} from chain ${fromChain} to ${toChain}`);
  
  const result = await bridge.executeDynamicBridge(params);
  return result;
}

// Export functions
module.exports = {
  dynamicBridgeExample,
  simpleBridge
};


if (require.main === module) {
  dynamicBridgeExample().catch(console.error);
}