const hre = require("hardhat");

/**
 * Make sure this token implements the interface IMintBurn and
 * ready to grant the gateway mint/burn permission.
 */
const token = "0xfffffffe47b78475160da680caef70959e027bee";

const factory = {
    "bscTestnet": "0x69383b872E99A7155C0841C8b1Af1058406cb246",
    "goerli": "0x69383b872E99A7155C0841C8b1Af1058406cb246",
    "ftmTestnet": "0x69383b872E99A7155C0841C8b1Af1058406cb246",
    "fuji": "0x69383b872E99A7155C0841C8b1Af1058406cb246",
    "moonbase": "0x69383b872E99A7155C0841C8b1Af1058406cb246"
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