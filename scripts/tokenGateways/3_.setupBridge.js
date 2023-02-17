const hre = require("hardhat");

const gatewayNetwork = {
    "bscTestnet": {
        "token": "",
        "gateway": ""
    },
    "goerli": {
        "token": "",
        "gateway": ""
    }
}

const chainids = {
    "bscTestnet": 97,
    "goerli": 5
}

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log(`deployer : ${deployer.address}`);

    console.log(`network : ${hre.network.name}`);

    console.log("setup gateway");
    var peerchainids = [];
    var peergateways = [];
    for (const name in gatewayNetwork) {
        if (name !== hre.network.name) {
            peerchainids.push(chainids[name]);
            peergateways.push(gatewayNetwork[name]["gateway"]);
        }
    }
    console.log(`peerchainids : ${peerchainids}`);
    console.log(`peergateways : ${peergateways}`);

    let gateway = await ethers.getContractAt("AnyCallApp", gatewayNetwork[hre.network.name]["gateway"]);
    let tx = await gateway.setClientPeers(peerchainids, peergateways);
    await tx.wait();
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});