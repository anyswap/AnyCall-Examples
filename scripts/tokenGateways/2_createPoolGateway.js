const hre = require("hardhat");

const token = "";

const factory = {
    "bscTestnet": "0xB6E4041A7bC74f48C42FF2AEF6D7D961DDAC9551",
    "goerli": "0xB6E4041A7bC74f48C42FF2AEF6D7D961DDAC9551",
    "ftmTestnet": "0xB6E4041A7bC74f48C42FF2AEF6D7D961DDAC9551"
}

const salt = 1;

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log(`deployer : ${deployer.address}`);

    console.log(`network : ${hre.network.name}`);

    console.log("deploy pool gateway");
    let bridgeFactory = await hre.ethers.getContractAt("BridgeFactory", factory[hre.network.name]);

    let tx = await bridgeFactory.createPoolGateway(token, deployer.address, salt);
    let rc = await tx.wait();
    let event = rc.events.find(event => event.event === 'Create');
    [_, gateway] = event.args;
    console.log(`gateway address : ${gateway}`);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});