const hre = require("hardhat");

/**
 * Make sure this token implements the interface IMintBurn and
 * ready to grant the gateway mint/burn permission.
 */
const token = "";

const factory = {
    "bscTestnet": "0xB071D067dc09a0550786c69080919dCc24704Efd",
    "goerli": "0xB071D067dc09a0550786c69080919dCc24704Efd",
    "ftmTestnet": "0xB071D067dc09a0550786c69080919dCc24704Efd",
    "fuji": "0xB071D067dc09a0550786c69080919dCc24704Efd"
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