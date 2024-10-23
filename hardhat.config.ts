import * as dotenv from 'dotenv';
import { HardhatUserConfig } from 'hardhat/config';
import '@nomicfoundation/hardhat-toolbox';

dotenv.config();

const chainIds = {
  eth_goerli_id: 5,
  polygon_mumbai_id: 80001,
  bsc_testnet_id: 97,
  eth_sepolia_id: 11155111,
};

const {
  SIGNER_PRIVATE_KEY,
  ETH_GOERLI_TESTNET_RPC,
  ETH_SCAN_API_KEY,
  ETH_GOERLI_SCAN_WEB,
  POLYGON_MUMBAI_TESTNET_RPC,
  POLYGON_SCAN_API_KEY,
  POLYGON_MUMBAI_SCAN_WEB,
  BSC_TESTNET_RPC,
  BSC_SCAN_API_KEY,
  BSC_TESTNET_SCAN_WEB,
  ETH_SEPOLIA_TESTNET_RPC,
} = process.env;

const config: HardhatUserConfig = {
  solidity: {
    version: '0.8.27',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    ethereum_goerli_testnet: {
      url: ETH_GOERLI_TESTNET_RPC,
      chainId: chainIds.eth_goerli_id,
      accounts: SIGNER_PRIVATE_KEY !== undefined ? [SIGNER_PRIVATE_KEY] : [],
    },
    polygon_mumbai_testnet: {
      url: POLYGON_MUMBAI_TESTNET_RPC,
      chainId: chainIds.polygon_mumbai_id,
      accounts: SIGNER_PRIVATE_KEY !== undefined ? [SIGNER_PRIVATE_KEY] : [],
    },
    binance_bsc_testnet: {
      url: BSC_TESTNET_RPC,
      chainId: chainIds.bsc_testnet_id,
      accounts: SIGNER_PRIVATE_KEY !== undefined ? [SIGNER_PRIVATE_KEY] : [],
    },
    ethereum_sepolia_testnet: {
      url: ETH_SEPOLIA_TESTNET_RPC,
      chainId: chainIds.eth_sepolia_id,
      accounts: SIGNER_PRIVATE_KEY !== undefined ? [SIGNER_PRIVATE_KEY] : [],
    },
  },
  etherscan: {
    apiKey: {
      goerli: ETH_SCAN_API_KEY,
      polygonMumbai: POLYGON_SCAN_API_KEY,
      bscTestnet: BSC_SCAN_API_KEY,
      sepolia: ETH_SCAN_API_KEY,
    },
  },
  mocha: {
    timeout: 0,
  },
  sourcify: {
    enabled: false,
  },
};

export default config;
