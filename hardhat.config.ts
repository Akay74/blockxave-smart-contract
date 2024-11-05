import { HardhatUserConfig } from "hardhat/types/config"
import "hardhat/config"
import "@nomicfoundation/hardhat-toolbox"
import "@typechain/hardhat"
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
    solidity: "0.8.26",
    networks: {
        hardhat: {
            chainId: 31337,
        },
    }
}


export default config
