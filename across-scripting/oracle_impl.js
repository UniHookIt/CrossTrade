require('dotenv').config();
const { ethers } = require('ethers');

const abi = [
  'function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)',
];

// Chainlink ETH/USD Feed addresses
const feeds = {
  sepolia: {
    rpc: process.env.ETHEREUM_SEPOLIA_RPC,
    address: '0x694AA1769357215DE4FAC081bf1f309aDC325306', // ETH/USD Sepolia
  },
  base: {
    rpc: process.env.BASE_RPC,
    address: '0x4aDC67696bA383F43DD60A9e78F2C97Fbbfc7cb1', // ETH/USD Base
  },
  optimism: {
    rpc: process.env.OPTIMISM_RPC,
    address: '0x61Ec26aA57019C486B10502285c5A3D4A4750AD7', // ETH/USD Optimism
  },
  arbitrum: {
    rpc: process.env.ARBITRUM_RPC,
    address: '0xd30e2101a97dcbAeBCBC04F14C3f624E67A35165', // ETH/USD Arbitrum
  },
};

const config = {
  sepolia: 11155111,
  arbitrum: 421614,
  optimism: 11155420,
  base: 84532, // Added Base chain ID
};

async function fetchPrice(name, rpc, address) {
  const provider = new ethers.JsonRpcProvider(rpc); // Ethers v5.8
  const contract = new ethers.Contract(address, abi, provider);
  const [, price] = await contract.latestRoundData();
  return {
    name,
    price: Number(price) / 1e8, // Adjust for 8 decimals
  };
}

async function fetchAndLog() {
  try {
    // Fetch prices for all chains
    const entries = await Promise.all(
      Object.entries(feeds).map(async ([chain, { rpc, address }]) => {
        const price = await fetchPrice(chain, rpc, address);
        return [chain, price];
      })
    );

    // Create price map
    const priceMap = Object.fromEntries(entries);

    // Find chain with lowest ETH price
    // Note: Your code has a bug where it finds the *highest* price due to `current.price > min.price`
    const chainToBuyLow = Object.values(priceMap).reduce((min, current) =>
      current.price > min.price ? current : min,
      Object.values(priceMap)[0] // Initialize with first entry
    );

    // Log results
    console.log('All chains and token prices:', priceMap);
    console.log('Sell Highest here:', chainToBuyLow);

    // Generate bridge parameters
    for (const key in config) {
      if (key === chainToBuyLow.name) {
        const data = {
          tokenSymbol: 'USDC',
          originChainId: 84532, // Base Sepolia
          destinationChainId: config[key],
          amount: ethers.parseUnits('8', 6).toString(), // 10 USDC
          recipient: '0xb725e575b82b57c73f81E51808Af1b2e8c4387bB',
        };
        console.log('The bridge details:', data);
        return data;
      }
    }

    console.warn('No matching chain found for bridging.');
    return null;
  } catch (error) {
    console.error('Error in fetchAndLog:', error.message);
    throw error;
  }
}
// const data = await fetchAndLog()
// console.log(data)

fetchAndLog()


// Export the function
module.exports = { fetchAndLog };