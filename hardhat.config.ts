import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import 'hardhat-deploy'
import 'dotenv/config'

const KLAYTN_API_KEY = process.env.KLAYTN_API_KEY
const DEPLOYER_PRIVATE_KEY = process.env.DEPLOYER_PRIVATE_KEY

const accounts = [DEPLOYER_PRIVATE_KEY as string]

const config: HardhatUserConfig = {
  solidity: "0.8.20",
  defaultNetwork: 'hardhat',
  networks: {
    localhost: {
      live: false,
      saveDeployments: true,
      tags: ['local'],
      allowUnlimitedContractSize: true,
    },
    hardhat: {
      allowUnlimitedContractSize: true,
      blockGasLimit: 10000000,
      chainId: 31337,
      live: false,
      saveDeployments: true,
      tags: ['test', 'local'],
      // Solidity-coverage overrides gasPrice to 1 which is not compatible with EIP1559
      hardfork: process.env.CODE_COVERAGE ? 'berlin' : 'london',
      forking: {
        enabled: process.env.FORKING === 'true',
        // url: `https://eth-mainnet.alchemyapi.io/v2/${process.env.ALCHEMY_API_KEY}`,
        url: `https://eth-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_KEY_2}`,
        blockNumber: 17428515,
      },
    },
    baobab: {
      url: 'https://klaytn-baobab.blockpi.network/v1/rpc/public',
      accounts,
      chainId: 1001,
      live: true,
      saveDeployments: true,
      tags: ['staging'],
      // forking: {
      //   enabled: process.env.FORKING === 'true',
      //   url: 'https://klaytn-baobab.blockpi.network/v1/rpc/public',
      //   blockNumber: 11829739,
      // },
    },
  },
  namedAccounts: {
    deployer: {
      default: 0,
    }
  },
  etherscan: {
    apiKey: KLAYTN_API_KEY,
  },
};

export default config;
