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
    const testDaiToken = await deploy("DaiToken", {
        from: deployer,
        args: [INITIAL_SUPPLY],
        log: true,
        // we need to wait if on a live network so we can verify properly
        // waitConfirmations: network.config.blockConfirmations || 1,
    })
    log(`TestDaiToken deployed at ${testDaiToken.address}`)

    if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
        await verify("contracts/TestDai.sol:DaiToken", testDaiToken.address, [INITIAL_SUPPLY])
    }
}
module.exports.tags = ["daiToken"]

0x878f446c1c5ca9988b6dff7f38b89363cf1dc71d
