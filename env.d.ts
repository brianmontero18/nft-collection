// env.d.ts
declare namespace NodeJS {
  interface ProcessEnv {
    SIGNER_PRIVATE_KEY: string;
    ETH_GOERLI_TESTNET_RPC: string;
    ETH_SCAN_API_KEY: string;
    POLYGON_MUMBAI_TESTNET_RPC: string;
    POLYGON_SCAN_API_KEY: string;
    BSC_TESTNET_RPC: string;
    BSC_SCAN_API_KEY: string;
  }
}
