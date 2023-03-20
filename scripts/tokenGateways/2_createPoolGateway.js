const hre = require("hardhat");

const token = "0x8C68ad9e912cE8E86D7c95DBAc90E4c79d8c017E";

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