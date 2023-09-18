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
    const savingsContract = await deploy("Savings", {
        from: deployer,
        args: ["general", "0x6B175474E89094C44Da98b954EedeAC495271d0F"],
        log: true,
        // we need to wait if on a live network so we can verify properly
        // waitConfirmations: network.config.blockConfirmations || 1,
    })
    log(`savingsContract deployed at ${savingsContract.address}`)

    // if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
    //     await verify(blockXafeToken.address, [INITIAL_SUPPLY])
    // }
}

module.exports.tags = ["all", "saving"]

// 0x1f02Dc93d0533a27f5E8AB55d2F98aDb6f464551
