# Across Bridge JavaScript Implementation

A comprehensive JavaScript implementation for bridging tokens across different blockchain networks using the Across Protocol's intent-based bridging system.

## Table of Contents
- [Overview](#overview)
- [How Across Protocol Works](#how-across-protocol-works)
- [Architecture & Flow](#architecture--flow)
- [Installation & Setup](#installation--setup)
- [Usage Examples](#usage-examples)
- [API Reference](#api-reference)
- [Error Handling](#error-handling)
- [Contributing](#contributing)

## Overview

This implementation provides a complete interface for the Across Protocol, supporting both mainnet and testnet environments. It handles token validation, balance checks, fee estimation, token approvals, and intent-based bridge execution across multiple EVM-compatible chains.

### Supported Chains
- **Ethereum** (Chain ID: 1)
- **Polygon** (Chain ID: 137)
- **Arbitrum** (Chain ID: 42161)
- **Optimism** (Chain ID: 10)
- **Base** (Chain ID: 8453)
- **Sepolia Testnet** (Chain ID: 11155111)
- **Base Sepolia** (Chain ID: 84532)

### Supported Tokens
- **ETH** (Native Ethereum)
- **WETH** (Wrapped Ethereum)
- **USDC** (USD Coin)
- **USDT** (Tether)
- **DAI** (Dai Stablecoin)

## How Across Protocol Works

### 1. Intent-Based Bridging Overview

Across Protocol uses an **intent-based bridging system** that differs from traditional lock-and-mint mechanisms:

```
User Intent → Fee Estimation → Intent Submission → Relayer Fulfillment → Settlement
```

### 2. Detailed Flow

#### **Step 1: Fee Estimation & Route Discovery**
- User specifies desired bridge parameters (token, amount, origin/destination chains)
- System queries Across API for **suggested fees** including:
  - **LP Fee**: Liquidity provider fee for using the protocol
  - **Relay Fee**: Fee paid to relayers for fulfilling the intent
  - **Gas Fee**: Estimated gas costs for execution

#### **Step 2: Intent Creation & Submission**
- An **intent order** is created containing:
  - Input token and amount
  - Output token and expected amount (after fees)
  - Destination chain and recipient
  - Timing parameters (fill deadline, exclusivity period)
  - Optional message data
- Intent is submitted to the **Origin Settler Contract** on the source chain
- Tokens are locked/escrowed in the Origin Settler

#### **Step 3: Relayer Network**
- **Relayers** monitor pending intents across all supported chains
- They compete to fulfill intents by:
  - Providing instant liquidity on the destination chain
  - Earning relay fees for their service
  - Taking on the risk of cross-chain settlement

#### **Step 4: Intent Fulfillment**
- Winning relayer executes the intent on destination chain
- Recipient receives tokens almost instantly
- System generates proof of fulfillment

#### **Step 5: Settlement via Spoke Pool**
- **Spoke Pool contracts** handle the final settlement
- Original tokens are released to the relayer
- The `depositV3` function in Spoke Pool contracts manages:
  - Token deposits and withdrawals
  - Fee collection and distribution
  - Cross-chain message passing
  - Dispute resolution mechanisms

### 3. Key Contracts Architecture

```
Origin Chain:              Destination Chain:
┌─────────────────┐       ┌─────────────────┐
│ Origin Settler  │       │ Spoke Pool      │
│ - Accept intents│       │ - Handle fills  │
│ - Lock tokens   │◄─────►│ - Settle claims │
│ - Verify proofs │       │ - Manage liquidity│
└─────────────────┘       └─────────────────┘
         │                           │
         └─────── Relayer Network ───┘
```

## Architecture & Flow

### Function Relationship Diagram

```
executeDynamicBridge()
    │
    ├── validateTokenSupport()
    │   └── getTokenConfig()
    │       └── getChainName()
    │
    ├── checkBalances() [via dryRun]
    │   └── getTokenConfig()
    │
    ├── performPreFlightChecks()
    │   ├── generateIntentOrderData()
    │   └── Gas estimation
    │
    ├── getSuggestedFees()
    │
    └── executeBridge()
        ├── getSuggestedFees()
        ├── approveTokenIfNeeded()
        ├── generateIntentOrderData()
        └── Origin Settler execution
```

### Why Pre-flight Checks and Dry Runs?

#### **Pre-flight Checks (`performPreFlightChecks`)**
- **Risk Mitigation**: Validates transaction feasibility before spending gas
- **Balance Verification**: Ensures sufficient token and ETH balances
- **Contract Verification**: Confirms Origin Settler contract exists and is accessible
- **Gas Estimation**: Provides realistic gas cost estimates to prevent failed transactions
- **Early Error Detection**: Catches configuration issues before expensive operations

#### **Dry Run (`dryRun`)**
- **Cost Transparency**: Shows exact fees and output amounts before execution
- **User Confirmation**: Allows users to review transaction details
- **Debugging**: Helps identify issues in a safe environment
- **Optimization**: Enables parameter tuning without real transactions

## Installation & Setup

```bash
npm install ethers axios
```

### Configuration Requirements

Create a `config.js` file with:

```javascript
const { ethers } = require('ethers');

const CONFIG = {
    MAINNET_API: 'https://across.to/api',
    TESTNET_API: 'https://testnet.across.to/api',
    
    // Chain IDs
    CHAINS: {
      ETHEREUM: 1,
      SEPOLIA: 11155111,
      POLYGON: 137,
      ARBITRUM: 42161,
      OPTIMISM: 10,
      BASE: 8453,
      BASE_SEPOLIA: 84532
    },
    
    // Enhanced token configuration with better chain mapping
    TOKENS: {
      // Native ETH (uses zero address when bridging)
      ETH: {
        ETHEREUM: ethers.ZeroAddress,
        SEPOLIA: ethers.ZeroAddress,
        BASE_SEPOLIA: ethers.ZeroAddress,
        BASE: ethers.ZeroAddress,
        ARBITRUM: ethers.ZeroAddress,
        OPTIMISM: ethers.ZeroAddress,
        POLYGON: ethers.ZeroAddress,
        decimals: 18,
        symbol: 'ETH'
      },
      
      // WETH addresses
      WETH: {
        ETHEREUM: '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2',
        SEPOLIA: '0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14',
        BASE_SEPOLIA: '0x4200000000000000000000000000000000000006',
        BASE: '0x4200000000000000000000000000000000000006',
        ARBITRUM: '0x82aF49447D8a07e3bd95BD0d56f35241523fBab1',
        OPTIMISM: '0x4200000000000000000000000000000000000006',
        POLYGON: '0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619',
        decimals: 18,
        symbol: 'WETH'
      },
      
      // USDC addresses by chain
      USDC: {
        ETHEREUM: '0xA0b86a33E6441986C3c6E4D8f9B0d5e3e2b5C9B4',
        SEPOLIA: '0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238',
        BASE_SEPOLIA: '0x036CbD53842c5426634e7929541eC2318f3dCF7e',
        BASE: '0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913',
        POLYGON: '0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174',
        ARBITRUM: '0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8',
        OPTIMISM: '0x7F5c764cBc14f9669B88837ca1490cCa17c31607',
        decimals: 6,
        symbol: 'USDC'
      },
      
      // USDT addresses
      USDT: {
        ETHEREUM: '0xdAC17F958D2ee523a2206206994597C13D831ec7',
        SEPOLIA: '0x7169D38820dfd117C3FA1f22a697dBA58d90BA06',
        POLYGON: '0xc2132D05D31c914a87C6611C10748AEb04B58e8F',
        ARBITRUM: '0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9',
        OPTIMISM: '0x94b008aA00579c1307B0EF2c499aD98a8ce58e58',
        decimals: 6,
        symbol: 'USDT'
      },
      
      // DAI addresses
      DAI: {
        ETHEREUM: '0x6B175474E89094C44Da98b954EedeAC495271d0F',
        SEPOLIA: '0xFF34B3d4Aee8ddCd6F9AFFFB6Fe49bD371b8a357',
        POLYGON: '0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063',
        ARBITRUM: '0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1',
        OPTIMISM: '0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1',
        BASE: '0x50c5725949A6F0c72E6C4a641F24049A917DB0Cb',
        decimals: 18,
        symbol: 'DAI'
      }
    },
    
    // Across SpokePool contract addresses
    SPOKE_POOLS: {
      1: '0x5c7BCd6E7De5423a257D81B442095A1a6ced35C5',
      11155111: '0x5ef6C01E11889d86803e0B23e3cB3F9E9d97B662',
      84532: '0x82B564983aE7274c86695917BBf8C99ECb6F0F8F',
      137: '0x9295ee1d8C5b022Be115A2AD3c30C72E34e7F096',
      42161: '0xe35e9842fceaCA96570B734083f4a58e8F7C5f2A',
      10: '0x6f26Bf09B1C792e3228e5467807a900A503c0281',
      8453: '0x09aea4b2242abC8bb4BB78D537A67a245A7bEC64'
    },
    
    // SpokePool ABI - minimal interface needed for bridging
    SPOKE_POOL_ABI: [
      'function depositV3(address depositor, address recipient, address inputToken, address outputToken, uint256 inputAmount, uint256 outputAmount, uint256 destinationChainId, address exclusiveRelayer, uint32 quoteTimestamp, uint32 fillDeadline, uint32 exclusivityDeadline, bytes calldata message) payable',
      'function fillV3Relay(tuple(address depositor, address recipient, address exclusiveRelayer, address inputToken, address outputToken, uint256 inputAmount, uint256 outputAmount, uint256 originChainId, uint32 depositId, uint32 fillDeadline, uint32 exclusivityDeadline, bytes message) relayData, uint256 repaymentChainId)'
    ],
  
    ORIGIN_SETTLERS: {
      1: '0x41a6fa8d160fe2d2d2fd2b227f4ce160eb88709d', // Ethereum (lowercase)
      11155111: '0x41a6fa8d160fe2d2d2fd2b227f4ce160eb88709d', // Sepolia (lowercase)
      8453: '0x41a6fa8d160fe2d2d2fd2b227f4ce160eb88709d', // Base (lowercase)
      84532: '0x41a6fa8d160fe2d2d2fd2b227f4ce160eb88709d', // Base Sepolia (lowercase)
      137: '0x41a6fa8d160fe2d2d2fd2b227f4ce160eb88709d', // Polygon (lowercase)
      42161: '0x41a6fa8d160fe2d2d2fd2b227f4ce160eb88709d', // Arbitrum (lowercase)
      10: '0x41a6fa8d160fe2d2d2fd2b227f4ce160eb88709d', // Optimism (lowercase)
    },
    
    ORIGIN_SETTLER_ABI: [
      'function executeOrder(tuple(bytes32 orderDataType, bytes orderData) order) payable',
      'function multicall(bytes[] calldata data) payable returns (bytes[] memory results)'
    ],
    
    ORDER_DATA_TYPE_HASH: '0x5c54fefb766ed428c96be865b4fef0f0e87cf42b6cd5e0e19d5c7b43ba7fe326'
  };

  module.exports = {CONFIG}
```

## Usage Examples

### Basic Bridge Operation

```javascript
const { AcrossBridge } = require('./across-bridge');

// Initialize bridge
const bridge = new AcrossBridge(privateKey, false); // false = mainnet

// Initialize providers
await bridge.initializeProviders({
  1: 'https://eth-mainnet.alchemyapi.io/v2/YOUR-KEY',
  137: 'https://polygon-mainnet.alchemyapi.io/v2/YOUR-KEY'
});

// Execute bridge
const result = await bridge.executeDynamicBridge({
  tokenSymbol: 'USDC',
  originChainId: 1,      // Ethereum
  destinationChainId: 137, // Polygon
  amount: ethers.parseUnits('100', 6), // 100 USDC
  recipient: '0x...',
  message: '0x'
});
```

### Dry Run Before Execution

```javascript
// Test transaction without spending gas
const dryRunResult = await bridge.dryRun({
  tokenSymbol: 'ETH',
  originChainId: 1,
  destinationChainId: 42161,
  amount: ethers.parseEther('0.1'),
  recipient: '0x...'
});

if (dryRunResult.canProceed) {
  console.log(`Output: ${dryRunResult.outputAmount}`);
  console.log(`Total fees: ${dryRunResult.fees.totalFees}`);
  
  // Proceed with actual bridge
  const result = await bridge.executeDynamicBridge({...});
}
```

### Balance and Token Validation

```javascript
// Check if token is supported
try {
  const validation = await bridge.validateTokenSupport('USDC', 1, 137);
  console.log('Token supported:', validation);
} catch (error) {
  console.log('Token not supported:', error.message);
}

// Check balances
const balanceInfo = await bridge.checkBalances('USDC', amount, chainId);
console.log(`Available: ${balanceInfo.tokenBalance}`);
```

## API Reference

### Constructor

#### `new AcrossBridge(privateKey, useTestnet)`

**Parameters:**
- `privateKey` (string): Ethereum private key for signing transactions
- `useTestnet` (boolean): Whether to use testnet endpoints (default: true)

**Example:**
```javascript
const bridge = new AcrossBridge('0x...', true);
```

---

### Core Methods

#### `initializeProviders(rpcUrls)`

Initializes blockchain providers and wallets for specified chains.

**Parameters:**
- `rpcUrls` (object): Mapping of chain IDs to RPC URLs

**Returns:** `Promise<void>`

**Example:**
```javascript
await bridge.initializeProviders({
  1: 'https://mainnet.infura.io/v3/YOUR-KEY',
  137: 'https://polygon-rpc.com'
});
```

---

#### `executeDynamicBridge(params)`

Main bridging function that handles the complete flow from validation to execution.

**Parameters:**
- `params` (object):
  - `tokenSymbol` (string): Token symbol to bridge ('ETH', 'USDC', etc.)
  - `originChainId` (number): Source blockchain chain ID
  - `destinationChainId` (number): Target blockchain chain ID
  - `amount` (BigInt): Amount to bridge in token's smallest unit
  - `recipient` (string): Destination wallet address
  - `message` (string, optional): Additional data (default: '0x')

**Returns:** `Promise<BridgeResult>`

**BridgeResult Object:**
```typescript
{
  success: boolean;
  transactionHash: string;
  blockNumber: number;
  gasUsed: string;
  inputAmount: string;
  outputAmount: string;
  fees: {
    lpFee: string;
    relayFee: string;
    totalFees: string;
  };
  originChainId: number;
  destinationChainId: number;
  recipient: string;
  intentOrder: object;
  tokenSymbol: string;
  tokenConfig: object;
}
```

**Example:**
```javascript
const result = await bridge.executeDynamicBridge({
  tokenSymbol: 'USDC',
  originChainId: 1,
  destinationChainId: 137,
  amount: ethers.parseUnits('100', 6),
  recipient: '0x742d35Cc6634C0532925a3b8D6c8d13f6AF29482'
});
```

---

#### `dryRun(params)`

Simulates a bridge transaction without executing it, providing cost estimates and validation.

**Parameters:**
- `params` (object): Same as `executeDynamicBridge` but with additional:
  - All parameters from `executeDynamicBridge`

**Returns:** `Promise<DryRunResult>`

**DryRunResult Object:**
```typescript
{
  canProceed: boolean;
  tokenSymbol: string;
  tokenConfig: object;
  inputAmount: string;
  outputAmount: string;
  fees: {
    lpFee: string;
    relayFee: string;
    gasCost: BigInt;
  };
  balanceInfo: {
    ethBalance: BigInt;
    tokenBalance: BigInt;
  };
  gasEstimate: {
    gasLimit: BigInt;
    estimatedCost: BigInt;
    gasPrice: BigInt;
  };
  error?: string; // Only present if canProceed is false
}
```

**Example:**
```javascript
const dryRun = await bridge.dryRun({
  tokenSymbol: 'ETH',
  originChainId: 1,
  destinationChainId: 42161,
  amount: ethers.parseEther('0.1'),
  recipient: '0x742d35Cc6634C0532925a3b8D6c8d13f6AF29482'
});

console.log(`Can proceed: ${dryRun.canProceed}`);
console.log(`Output amount: ${dryRun.outputAmount}`);
console.log(`Total fees: ${dryRun.fees.lpFee + dryRun.fees.relayFee}`);
```

---

### Utility Methods

#### `validateTokenSupport(tokenSymbol, originChainId, destinationChainId)`

Validates that a token is supported on both specified chains.

**Parameters:**
- `tokenSymbol` (string): Token symbol to validate
- `originChainId` (number): Source chain ID
- `destinationChainId` (number): Destination chain ID

**Returns:** `Promise<TokenValidation>`

**TokenValidation Object:**
```typescript
{
  inputToken: string;  // Token address on origin chain
  outputToken: string; // Token address on destination chain
  inputConfig: {
    address: string;
    decimals: number;
    symbol: string;
    isNative: boolean;
  };
  outputConfig: {
    address: string;
    decimals: number;
    symbol: string;
    isNative: boolean;
  };
}
```

**Example:**
```javascript
try {
  const validation = await bridge.validateTokenSupport('USDC', 1, 137);
  console.log('Input token address:', validation.inputToken);
  console.log('Output token address:', validation.outputToken);
} catch (error) {
  console.error('Token not supported:', error.message);
}
```

---

#### `checkBalances(tokenSymbol, amount, chainId)`

Checks ETH and token balances on specified chain.

**Parameters:**
- `tokenSymbol` (string): Token symbol to check
- `amount` (BigInt): Amount needed for the transaction
- `chainId` (number): Chain ID to check balances on

**Returns:** `Promise<BalanceInfo>`

**BalanceInfo Object:**
```typescript
{
  ethBalance: BigInt;
  tokenBalance: BigInt;
  tokenConfig: {
    address: string;
    decimals: number;
    symbol: string;
    isNative: boolean;
  };
  hasEnoughTokens: boolean;
}
```

**Example:**
```javascript
const balanceInfo = await bridge.checkBalances('USDC', ethers.parseUnits('100', 6), 1);
console.log(`USDC Balance: ${ethers.formatUnits(balanceInfo.tokenBalance, 6)}`);
console.log(`ETH Balance: ${ethers.formatEther(balanceInfo.ethBalance)}`);
console.log(`Sufficient balance: ${balanceInfo.hasEnoughTokens}`);
```

---

#### `getSuggestedFees(params)`

Retrieves fee estimates from the Across API.

**Parameters:**
- `params` (object):
  - `inputToken` (string): Input token address
  - `outputToken` (string): Output token address
  - `originChainId` (number): Source chain ID
  - `destinationChainId` (number): Destination chain ID
  - `amount` (string): Amount to bridge
  - `recipient` (string): Recipient address
  - `timestamp` (number, optional): Unix timestamp

**Returns:** `Promise<FeeData>`

**Example:**
```javascript
const fees = await bridge.getSuggestedFees({
  inputToken: '0xA0b86a33E6417c90e2d04b4DB7bF6c9c6e5e8b12',
  outputToken: '0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174',
  originChainId: 1,
  destinationChainId: 137,
  amount: ethers.parseUnits('100', 6).toString(),
  recipient: '0x742d35Cc6634C0532925a3b8D6c8d13f6AF29482'
});
```

---

### Internal Methods

#### `getChainName(chainId)`

Converts chain ID to human-readable chain name.

**Parameters:**
- `chainId` (number): Blockchain chain ID

**Returns:** `string` - Chain name or undefined

---

#### `getTokenConfig(tokenSymbol, chainId)`

Retrieves token configuration for a specific chain.

**Parameters:**
- `tokenSymbol` (string): Token symbol
- `chainId` (number): Chain ID

**Returns:** `TokenConfig` object

---

#### `approveTokenIfNeeded(tokenAddress, spenderAddress, amount, chainId)`

Handles ERC20 token approval if needed.

**Parameters:**
- `tokenAddress` (string): Token contract address
- `spenderAddress` (string): Spender contract address
- `amount` (BigInt): Amount to approve
- `chainId` (number): Chain ID

**Returns:** `Promise<TransactionReceipt | null>`

---

#### `generateIntentOrderData(params)`

Creates the intent order data structure for the Origin Settler contract.

**Parameters:**
- `params` (object): Order parameters including tokens, amounts, timing, etc.

**Returns:** `IntentOrder` object

---

#### `performPreFlightChecks(bridgeParams)`

Performs comprehensive validation before bridge execution.

**Parameters:**
- `bridgeParams` (object): Bridge parameters

**Returns:** `Promise<PreFlightResult>`

---

#### `executeBridge(bridgeParams)`

Low-level bridge execution function.

**Parameters:**
- `bridgeParams` (object): Complete bridge parameters

**Returns:** `Promise<BridgeResult>`

---

#### `handleBridgeError(error)`

Provides detailed error analysis and troubleshooting suggestions.

**Parameters:**
- `error` (Error): The error object to analyze

**Returns:** `void` (prints analysis to console)

## Error Handling

The implementation provides comprehensive error handling with specific guidance:

### Common Error Types

1. **Insufficient Balance Errors**
   - Token balance too low
   - Insufficient ETH for gas
   - Solutions: Check balances, reduce amount, add funds

2. **Token Support Errors**
   - Unsupported token on chain
   - Token not in configuration
   - Solutions: Use supported tokens, check chain support

3. **Gas Estimation Errors**
   - Network congestion
   - RPC issues
   - Solutions: Retry, use different RPC, increase gas

4. **Approval Errors**
   - Failed token approval
   - Insufficient gas for approval
   - Solutions: Ensure ETH balance, retry approval

5. **Fee Estimation Errors**
   - API connectivity issues
   - Invalid parameters
   - Solutions: Check network, verify parameters

### Error Handling Example

```javascript
try {
  const result = await bridge.executeDynamicBridge(params);
  console.log('Bridge successful:', result);
} catch (error) {
  // Detailed error analysis with solutions
  bridge.handleBridgeError(error);
  
  // Custom error handling
  if (error.message.includes('Insufficient')) {
    console.log('Please add more funds to your wallet');
  }
}
```

## Best Practices

### 1. Always Use Dry Run First
```javascript
const dryRun = await bridge.dryRun(params);
if (dryRun.canProceed) {
  const result = await bridge.executeDynamicBridge(params);
}
```

### 2. Monitor Transaction Status
```javascript
const result = await bridge.executeDynamicBridge(params);
console.log(`Transaction: ${result.transactionHash}`);
console.log(`Block: ${result.blockNumber}`);
```

### 3. Handle Network Issues
```javascript
// Implement retry logic for network issues
const maxRetries = 3;
let attempt = 0;

while (attempt < maxRetries) {
  try {
    const result = await bridge.executeDynamicBridge(params);
    break;
  } catch (error) {
    attempt++;
    if (attempt >= maxRetries) throw error;
    await new Promise(resolve => setTimeout(resolve, 1000 * attempt));
  }
}
```

### 4. Validate Inputs
```javascript
// Always validate before execution
if (!ethers.isAddress(recipient)) {
  throw new Error('Invalid recipient address');
}

if (amount <= 0) {
  throw new Error('Amount must be greater than 0');
}
```

## Security Considerations

1. **Private Key Management**: Never hardcode private keys. Use environment variables or secure key management systems.

2. **Amount Validation**: Always validate amounts to prevent overflow/underflow issues.

3. **Address Validation**: Verify all addresses are valid Ethereum addresses.

4. **Network Validation**: Ensure you're connecting to the correct networks.

5. **Fee Monitoring**: Monitor fees to detect unusual spikes that might indicate issues.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Update documentation
5. Submit a pull request

## License

MIT License - see LICENSE file for details.

## Support

For issues and questions:
- Create an issue on GitHub
- Check Across Protocol documentation
- Join the Across Protocol Discord community

---

*This implementation is for educational and development purposes. Always test thoroughly on testnets before using with real funds.*