import { HardhatUserConfig } from "hardhat/types/config"
import "hardhat/config"
import "@nomicfoundation/hardhat-toolbox"
import * as dotenv from "dotenv"
import "hardhat-deploy"
import "hardhat-gas-reporter"
import "hardhat-deploy-ethers"
dotenv.config()

const SEPOLIA_PRIVATE_KEY = process.env.SEPOLIA_PRIVATE_KEY || ""
const SEPOLIA_URL = process.env.SEPOLIA_URL || ""
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY || ""
const COIN_MARKET_API_KEY = process.env.COIN_MARKET_API_KEY || ""

/** @type import('hardhat/config').HardhatUserConfig */
const config: HardhatUserConfig = {
    solidity: "0.8.19",
    networks: {
        hardhat: {
            chainId: 31337,
        },
        sepolia: {
            url: SEPOLIA_URL,
            accounts: [SEPOLIA_PRIVATE_KEY],
            chainId: 11155111,
        },
    },
    etherscan: {
        apiKey: {
            sepolia: ETHERSCAN_API_KEY,
        },
    },
    gasReporter: {
        enabled: true,
        coinmarketcap: COIN_MARKET_API_KEY,
        currency: "USD",
        noColors: true,
        outputFile: "gas-reporter.csv",
    },
    namedAccounts: {
        deployer: {
            default: 0,
        },
    },
}

export default config
