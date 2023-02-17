const hre = require("hardhat");

/**
 * This script will deploy a standard mintburnable token and a gateway contract.
 */

const factory = {
    "bscTestnet": "0xf95b8E5ea5cAb6Aea20E90f2D123368349953254",
    "goerli": "0xEd62F792C54A7e794d156C4cdd4667a3bAe25aDE"
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