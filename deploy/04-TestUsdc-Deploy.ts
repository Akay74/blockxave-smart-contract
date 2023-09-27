import { network } from "hardhat"
import { developmentChains, INITIAL_SUPPLY } from "../helper-hardhat-config"
import { verify } from "../utils/verify"
import "hardhat-deploy"
import { HardhatRuntimeEnvironment } from "hardhat/types"

module.exports = async ({
    getNamedAccounts,
    deployments,
}: HardhatRuntimeEnvironment): Promise<void> => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const testUsdcToken = await deploy("UsdcToken", {
        from: deployer,
        args: [INITIAL_SUPPLY],
        log: true,
        // we need to wait if on a live network so we can verify properly
        // waitConfirmations: network.config.blockConfirmations || 1,
    })
    log(`TestUsdcToken deployed at ${testUsdcToken.address}`)

    if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
        await verify("contracts/TestUsdc.sol:UsdcToken", testUsdcToken.address, [INITIAL_SUPPLY])
    }
}
module.exports.tags = ["usdcToken"]

0x6a635201f6f72e7459a12abfedc1494cdde0d5e8
