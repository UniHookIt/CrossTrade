# CrossTrade-1

A cross-chain arbitrage and bridging toolkit, featuring:

- **crosstrade-hook**: Solidity hooks for Uniswap v4 pools to enable cross-chain arbitrage logic.
- **across-scripting**: JavaScript/Node.js scripts for intent-based bridging using the Across Protocol.

---

## Table of Contents

- [Project Structure](#project-structure)
- [crosstrade-hook](#crosstrade-hook)
  - [Overview](#overview)
  - [Key Contracts](#key-contracts)
  - [Testing](#testing)
  - [How It Works](#how-it-works)
  - [Development](#development)
- [across-scripting](#across-scripting)
  - [Overview](#overview-1)
  - [Architecture & Flow](#architecture--flow)
  - [Setup](#setup)
  - [Usage](#usage)
  - [API Reference](#api-reference)
  - [Error Handling](#error-handling)
- [Best Practices](#best-practices)
- [Security Considerations](#security-considerations)
- [License](#license)

---

## Project Structure

```
CrossTrade-1/
├── .gitmodules
├── README.md
├── across-scripting/
│   ├── .env.example
│   ├── .gitignore
│   ├── index.js
│   ├── oracle_impl.js
│   ├── package.json
│   ├── README.md
│   └── scripts/
│       └── across-bridge.js
├── crosstrade-hook/
│   ├── .gitignore
│   ├── foundry.toml
│   ├── LICENSE
│   ├── remappings.txt
│   ├── .github/
│   │   └── workflows/
│   │       └── test.yml
│   ├── lib/
│   │   ├── forge-std/
│   │   └── v4-periphery/
│   ├── script/
│   │   └── generatePayload.ts
│   ├── src/
│   │   └── CrossTradeHook.sol
│   └── test/
│       └── CrossTrade.t.sol
```

---

## crosstrade-hook

### Overview

Solidity smart contracts implementing Uniswap v4 hooks for cross-chain arbitrage.  
The main contract, [`CrossTradeHook`](crosstrade-hook/src/CrossTradeHook.sol), enables custom logic before swaps, including profit checks and gas cost estimation, to ensure only profitable arbitrage trades are executed.

### Key Contracts

- [`CrossTradeHook`](crosstrade-hook/src/CrossTradeHook.sol):  
  Implements the Uniswap v4 hook interface. Checks for arbitrage profitability before allowing swaps, using parameters such as token price, slippage, and minimum profit.  
  - **Key features:**
    - Validates hook data for each swap.
    - Estimates output amount and profit after fees and slippage.
    - Rejects unprofitable swaps with custom errors.
    - Exposes `getCurrentGasPrice()` for gas cost estimation.

- [`CrossTradeHookTest`](crosstrade-hook/test/CrossTrade.t.sol):  
  Foundry test suite for the hook, simulating both profitable and unprofitable arbitrage scenarios.  
  - **Tests include:**
    - Gas price reporting.
    - Profitable ETH→USDC swap.
    - Rejection of unprofitable swaps.

### Testing

To run tests:

```sh
cd crosstrade-hook
forge test -vvv
```

### How It Works

- **Arbitrage Struct:**  
  The hook expects encoded data with `tokenPrice`, `slippage`, and `minProfit` for each swap.
- **Profitability Check:**  
  Before a swap, the hook:
  1. Decodes the arbitrage parameters.
  2. Calculates the expected output after fees and slippage.
  3. Estimates gas cost in USDC.
  4. Ensures the profit (after gas) meets or exceeds `minProfit`.
  5. Reverts the swap if not profitable.

- **Integration:**  
  Deploy the hook and configure your Uniswap v4 pool to use it.  
  Pass the encoded arbitrage parameters as hook data for each swap.

- **Customization:**  
  You can extend the hook to fetch live prices, integrate with off-chain oracles, or trigger cross-chain bridging.

### Development

- **Solidity Version:** 0.8.26
- **Testing:** Foundry (`forge`)
- **Dependencies:**  
  - Uniswap v4 core and periphery (as submodules)
  - Solmate for ERC20 mocks

---

## across-scripting

### Overview

Node.js scripts for intent-based bridging using the Across Protocol.  
Includes a robust bridge class, price oracle integration, and dynamic bridging logic.

- **Key files:**
  - [`scripts/across-bridge.js`](across-scripting/scripts/across-bridge.js):  
    Main bridge logic, including token validation, fee estimation, approvals, and intent-based bridging.
  - [`oracle_impl.js`](across-scripting/oracle_impl.js):  
    Fetches cross-chain price data (e.g., from Chainlink) to inform arbitrage and bridging decisions.
  - [`index.js`](across-scripting/index.js):  
    Example entrypoint for dynamic bridging, integrating price oracle and bridge logic.

### Architecture & Flow

#### Intent-Based Bridging

1. **Fee Estimation:**  
   Queries Across API for LP and relay fees.
2. **Intent Creation:**  
   Encodes an order with token, amount, destination, deadlines, and message.
3. **Submission:**  
   Sends the intent to the Origin Settler contract on the source chain.
4. **Relayer Fulfillment:**  
   Relayers compete to fulfill the intent on the destination chain.
5. **Settlement:**  
   Spoke Pool contracts handle final settlement and fee distribution.

#### Function Relationship Diagram

```
executeDynamicBridge()
    │
    ├── validateTokenSupport()
    ├── checkBalances()
    ├── performPreFlightChecks()
    ├── getSuggestedFees()
    └── executeBridge()
```

### Setup

1. **Install dependencies:**

   ```sh
   cd across-scripting
   npm install
   ```

2. **Configure environment variables:**

   Copy `.env.example` to `.env` and fill in your private key, wallet address, and RPC endpoints.

   ```sh
   cp .env.example .env
   ```

   Example `.env`:

   ```
   PRIVATE_KEY=your_private_key
   USER_WALLET_ADDRESS=your_wallet_address
   ETHEREUM_SEPOLIA_RPC=https://...
   BASE_RPC=https://...
   # ...other RPCs
   ```

### Usage

- **Dynamic Bridge Example:**

  Run the main script to perform a dry run and, if possible, execute a bridge based on oracle price data:

  ```sh
  node index.js
  ```

  This will:
  - Fetch cross-chain prices.
  - Suggest a bridge route.
  - Simulate the bridge (dry run).
  - Execute the bridge if profitable.

- **Custom Bridge:**

  Use the exported `simpleBridge` function in your own scripts:

  ```js
  const { simpleBridge } = require('./index');
  await simpleBridge('USDC', 84532, 11155111, ethers.parseUnits('10', 6), '0xYourAddress');
  ```

### API Reference

See [across-scripting/README.md](across-scripting/README.md) for a full API reference, including:

- `AcrossBridge` class methods:
  - `initializeProviders(rpcUrls)`
  - `validateTokenSupport(tokenSymbol, originChainId, destinationChainId)`
  - `checkBalances(tokenSymbol, amount, chainId)`
  - `dryRun(params)`
  - `executeDynamicBridge(params)`
  - `monitorBridge(transactionHash, originChainId, destinationChainId)`
  - `getBridgeHistory(address, chainId, limit)`
  - `handleBridgeError(error)`
  - ...and more.

### Error Handling

The bridge scripts provide detailed error messages and troubleshooting suggestions for:

- Insufficient balances
- Unsupported tokens or chains
- Gas estimation failures
- Token approval issues
- Fee estimation/API errors

---

## Best Practices

- **Always run a dry run** before executing a bridge to estimate fees and check for errors.
- **Monitor transaction status** using `monitorBridge`.
- **Validate all addresses and amounts** before execution.
- **Keep your private key secure** and never commit it to version control.
- **Test on testnets** before using mainnet.

---

## Security Considerations

- **Private Key Management:**  
  Use environment variables or secure vaults for private keys.
- **Amount Validation:**  
  Always validate bridge amounts to prevent errors.
- **Address Validation:**  
  Ensure all addresses are valid and checksummed.
- **Network Validation:**  
  Use reliable RPC endpoints and verify chain IDs.
- **Fee Monitoring:**  
  Monitor for unusual fee spikes or API changes.

---

## License

MIT License. See [crosstrade-hook/LICENSE](crosstrade-hook/LICENSE).

---

*For detailed scripting API, see [across-scripting/README.md](across-scripting/README.md).  
For contract details, see [`crosstrade-hook/src`](crosstrade-hook/src).  
For testing information, see [`crosstrade-hook/test`](crosstrade-hook/test).*
