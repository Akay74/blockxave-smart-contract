import { run } from "hardhat"

export const verify = async function (contractAddress: string, args: string[]): Promise<void> {
    try {
        await run("verify:verify", {
            address: contractAddress,
            constructorArguments: args,
            contract: "contracts/BlockXafeToken.sol:BlockXafeToken",
        })
    } catch (err: any) {
        if (err.message.toLowerCase().includes("already verified")) {
            console.log("Already verified")
        } else {
            console.log(err.message)
        }
    }
}
