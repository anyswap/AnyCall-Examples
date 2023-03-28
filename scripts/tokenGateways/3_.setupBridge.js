const hre = require("hardhat");

const gatewayNetwork = {
    "bscTestnet": {
        "token": "0x64544969ed7EBf5f083679233325356EbE738930",
        "gateway": "0xb57b236921da1a6511a74a526611cd5eff4810a0"
    },
    "goerli": {
        "token": "0x07865c6e87b9f70255377e024ace6630c1eaa37f",
        "gateway": "0xb57b236921da1a6511a74a526611cd5eff4810a0"
    },
    "moonbase": {
        "token": "0xfffffffe47b78475160da680caef70959e027bee",
        "gateway": "0x37BdC2A41837467d6C5Af9Fd69B7ED2A4B401762"
    },
    "fuji": {
        "token": "0x5425890298aed601595a70ab815c96711a31bc65",
        "gateway": "0xb57b236921da1a6511a74a526611cd5eff4810a0"
    }
}

const chainids = {
    "fuji": 43113,
    "bscTestnet": 97,
    //"ftmTestnet": 4002,
    "goerli": 5,
    "moonbase": 1287
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