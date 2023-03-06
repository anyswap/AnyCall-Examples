const hre = require("hardhat");

/**
 * This script will deploy a standard mintburnable token and a gateway contract.
 */

const factory = {
    "bscTestnet": "0xB6E4041A7bC74f48C42FF2AEF6D7D961DDAC9551",
    "goerli": "0xB6E4041A7bC74f48C42FF2AEF6D7D961DDAC9551",
    "ftmTestnet": "0xB6E4041A7bC74f48C42FF2AEF6D7D961DDAC9551"
}

const tokenInfo = {
    "name": "<token name>",
    "symbol": "<token symbol>",
    "decimals": 18
}
const salt = 1;

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log(`deployer : ${deployer.address}`);

    console.log(`network : ${hre.network.name}`);

    console.log("deploy token and mintburn gateway");
    let bridgeFactory = await hre.ethers.getContractAt("BridgeFactory", factory[hre.network.name]);

    let tx = await bridgeFactory.createTokenAndMintBurnGateway(tokenInfo.name, tokenInfo.symbol, tokenInfo.decimals, deployer.address, salt);
    let rc = await tx.wait();

    let events = rc.events.filter(event => event.event === 'Create');
    [_, token] = events[0].args;
    console.log(`token address : ${token}`);

    [_, gateway] = events[1].args;
    console.log(`gateway address : ${gateway}`);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});