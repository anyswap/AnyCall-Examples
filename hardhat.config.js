require("@nomicfoundation/hardhat-toolbox");
require('dotenv').config();
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");
require('hardhat-abi-exporter');

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.17",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    hardhat: {
    },
    bscTestnet: {
      url: process.env.BSCTESTNET_RPC_PROVIDER,
      accounts: [process.env.PRIVATE_KEY]
    },
    goerli: {
      url: process.env.GOERLI_RPC_PROVIDER,
      accounts: [process.env.PRIVATE_KEY]
    }
  },
  etherscan: {
    apiKey: {
      eth: process.env.ETHERSCAN_API_KEY,
      bsc: process.env.BSCSCAN_API_KEY
    }
  },
  abiExporter: [
    {
      path: './abi/json',
      format: "json",
    },
    {
      path: './abi/minimal',
      format: "minimal",
    },
    {
      path: './abi/fullName',
      format: "fullName",
    },
  ]
};
