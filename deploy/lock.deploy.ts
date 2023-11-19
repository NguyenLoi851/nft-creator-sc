import { HardhatRuntimeEnvironment} from 'hardhat/types'
import { DeployFunction } from 'hardhat-deploy/types'

const deployContract: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
    const { deployments, getNamedAccounts} = hre
    const { deploy } = deployments
    const { deployer } = await getNamedAccounts()
    console.log("Hello")
    await deploy('Lock', {
        from: deployer,
        args: [17000000000000],
        log: true,
        deterministicDeployment: false,
        // proxy: {
        //     proxyContract: 'OpenZeppelinTransparentProxy'
        // }
    })
}

deployContract.tags = ['LOCK']

export default deployContract