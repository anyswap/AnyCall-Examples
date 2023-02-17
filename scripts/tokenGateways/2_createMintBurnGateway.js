const hre = require("hardhat");

/**
 * Make sure this token implements the interface IMintBurn and
 * ready to grant the gateway mint/burn permission.
 */
const token = "";

const factory = {
    "bscTestnet": "0xf95b8E5ea5cAb6Aea20E90f2D123368349953254",
    "goerli": "0xEd62F792C54A7e794d156C4cdd4667a3bAe25aDE"
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