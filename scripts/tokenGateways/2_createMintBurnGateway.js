const hre = require("hardhat");

/**
 * Make sure this token implements the interface IMintBurn and
 * ready to grant the gateway mint/burn permission.
 */
const token = "";

const factory = {
    "bscTestnet": "0xfB3bcb54ab305B9e8C512ADF6bBaE63f048CFA7F",
    "goerli": "0xe536b782b6e3F0931F5BF0De2A35474556482965"
}

const salt = 1;

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log(`deployer : ${deployer.address}`);

    console.log(`network : ${hre.network.name}`);

    console.log("deploy mintburn gateway");
    let bridgeFactory = await hre.ethers.getContractAt("BridgeFactory", factory[hre.network.name]);

    let tx = await bridgeFactory.createMintBurnGateway(token, deployer.address, salt);
    let rc = await tx.wait();
    let event = rc.events.find(event => event.event === 'Create');
    [_, gateway] = event.args;
    console.log(`gateway address : ${gateway}`);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});