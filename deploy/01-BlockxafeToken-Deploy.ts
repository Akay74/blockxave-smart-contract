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
    const blockXafeToken = await deploy("BlockXafeToken", {
        from: deployer,
        args: [INITIAL_SUPPLY],
        log: true,
        // we need to wait if on a live network so we can verify properly
        // waitConfirmations: network.config.blockConfirmations || 1,
    })
    log(`BlockXafeToken deployed at ${blockXafeToken.address}`)

    if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
        await verify(blockXafeToken.address, [INITIAL_SUPPLY])
    }
}

module.exports.tags = ["all", "token"]

// 0x1f02Dc93d0533a27f5E8AB55d2F98aDb6f464551
