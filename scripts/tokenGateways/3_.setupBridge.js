const hre = require("hardhat");

const gatewayNetwork = {
    "bscTestnet": {
        "token": "0x18D9EB4cFD92F2fA08071eD3213f41E59bb97a81",
        "gateway": "0x94AD484C50402AE81Dd7CF9FE4905731afB7B159"
    },
    "goerli": {
        "token": "0x0608fe957B955B608FeA8A8d6F8ac8b871926B0E",
        "gateway": "0x5b5341210fe20774c3f24a418de1Feb7d0b9Af9b"
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