<!-- ![Alt logo](./crosstrade.jpg) -->
<img src="./crosstrade.png" alt="Logo" width="150" height="150">

# CrossTrade 

A dynamic arbitrage hook that leverages Chainlink oracles to find optimal ETH/USDC prices across Ethereum, Optimism, Arbitrum, and Base networks, enabling intelligent cross-chain bridging decisions.

## Overview

CrossTrade combines real-time price data from Chainlink oracles with Across Protocol's bridging infrastructure to help users make informed decisions about where to bridge their assets for maximum efficiency.

## Features

- **Multi-Chain Price Discovery**: Real-time ETH/USD price feeds from Chainlink across 4 major networks
- **Dynamic Arbitrage Detection**: Automatically identifies the chain with the most favorable prices
- **Seamless Bridging**: Integrates with Across Protocol for reliable cross-chain transfers
- **Intent-Based Architecture**: Uses Across's latest intent-based bridging for better UX
- **Comprehensive Monitoring**: Track bridge transactions and provide detailed status updates

## Supported Networks

| Network | Chain ID | Oracle Address |
|---------|----------|----------------|
| Ethereum Sepolia | 11155111 | `0x694AA1769357215DE4FAC081bf1f309aDC325306` |
| Base Sepolia | 84532 | `0x4aDC67696bA383F43DD60A9e78F2C97Fbbfc7cb1` |
| Optimism Sepolia | 11155420 | `0x61Ec26aA57019C486B10502285c5A3D4A4750AD7` |
| Arbitrum Sepolia | 421614 | `0xd30e2101a97dcbAeBCBC04F14C3f624E67A35165` |

## Quick Start

### Installation

```bash
npm install
```

### Environment Setup

Create a `.env` file:

```env
PRIVATE_KEY=your_private_key_here
USER_WALLET_ADDRESS=your_wallet_address_here
ETHEREUM_SEPOLIA_RPC=your_ethereum_sepolia_rpc
BASE_RPC=your_base_rpc
OPTIMISM_RPC=your_optimism_rpc
ARBITRUM_RPC=your_arbitrum_rpc
```

### Basic Usage

```javascript
const { dynamicBridgeExample } = require('./index');

// Run dynamic bridge with oracle-guided decisions
await dynamicBridgeExample();
```

## How It Works

1. **Price Discovery**: Fetches real-time ETH/USD prices from Chainlink oracles across all supported chains
2. **Arbitrage Detection**: Compares prices to identify the chain with the highest ETH value
3. **Bridge Parameters**: Generates optimal bridging parameters based on price analysis
4. **Execution**: Uses Across Protocol's intent-based system to execute the bridge transaction

## Code Structure

### Core Components

- **`oracle_impl.js`**: Chainlink oracle integration for multi-chain price feeds
- **`across-bridge.js`**: Across Protocol bridge implementation with intent-based architecture
- **`index.js`**: Main orchestration logic combining oracle data with bridge execution

### Key Functions

```javascript
// Get optimal bridging parameters based on price analysis
const bridgeParams = await fetchAndLog();

// Execute bridge with dynamic parameters
const result = await bridge.executeDynamicBridge(bridgeParams);

// Monitor transaction status
const status = await bridge.monitorBridge(result.transactionHash, originChain, destChain);
```

## Example Output

```
All chains and token prices: {
  sepolia: { name: 'sepolia', price: 2241.82 },
  base: { name: 'base', price: 2242.15 },
  optimism: { name: 'optimism', price: 2241.95 },
  arbitrum: { name: 'arbitrum', price: 2242.08 }
}
Sell Highest here: { name: 'base', price: 2242.15 }
The bridge details: {
  tokenSymbol: 'USDC',
  originChainId: 84532,
  destinationChainId: 84532,
  amount: '8000000',
  recipient: '0xb725e575b82b57c73f81E51808Af1b2e8c4387bB'
}
```

## Future Roadmap

### Phase 1: Enhanced Price Discovery
- **Multiple Oracle Sources**: Integrate additional price feeds (Uniswap TWAP, Band Protocol)
- **Advanced Arbitrage Logic**: Factor in gas fees and slippage for true profit calculations
- **Real-time Alerts**: Notify users when profitable arbitrage opportunities arise

### Phase 2: Machine Learning Integration
- **Price Prediction Models**: ML algorithms to forecast short-term price movements
- **Risk Assessment**: Automated risk scoring based on historical volatility and market conditions
- **Strategy Optimization**: Learn from successful trades to improve decision-making

### Phase 3: Advanced Features
- **Multi-Asset Support**: Expand beyond ETH/USDC to other trading pairs
- **Automated Execution**: Set-and-forget arbitrage with customizable parameters
- **Portfolio Management**: Track performance and optimize across multiple positions

## Supported Tokens

- **ETH**: Native Ethereum across all chains
- **WETH**: Wrapped Ethereum
- **USDC**: USD Coin (6 decimals)
- **USDT**: Tether USD
- **DAI**: MakerDAO stablecoin

## Safety Features

- **Dry Run Mode**: Test transactions before execution
- **Balance Validation**: Automatic balance checks before bridging
- **Gas Estimation**: Accurate gas cost predictions
- **Error Handling**: Comprehensive error messages with troubleshooting guidance

## API Reference

### Oracle Functions

```javascript
// Fetch prices from all chains
const prices = await fetchAndLog();

// Get specific chain price
const price = await fetchPrice(chainName, rpcUrl, oracleAddress);
```

### Bridge Functions

```javascript
// Initialize bridge
const bridge = new AcrossBridge(privateKey, isTestnet);

// Execute dynamic bridge
const result = await bridge.executeDynamicBridge(params);

// Monitor transaction
const status = await bridge.monitorBridge(txHash, originChain, destChain);
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Disclaimer

This software is provided as-is for educational and research purposes. Always test thoroughly on testnets before using with real funds. Cryptocurrency trading and bridging involve risks including but not limited to loss of funds due to smart contract vulnerabilities, price volatility, and technical failures.

## Support

- **Documentation**: Check inline code comments for detailed explanations
- **Issues**: Report bugs via GitHub Issues
- **Discussions**: Join our community discussions for feature requests and general questions

---

**Built with ❤️ using Chainlink Oracles and Across Protocol**