const hre = require("hardhat");

const gatewayNetwork = {
    "bscTestnet": {
        "token": "0x8C68ad9e912cE8E86D7c95DBAc90E4c79d8c017E",
        "gateway": "0xe2927dbabfdDeAB984CF2dd1ce14346E5c590F14"
    },
    "goerli": {
        "token": "0x8C68ad9e912cE8E86D7c95DBAc90E4c79d8c017E",
        "gateway": "0xC839DDd78F4E31227fF3FeebBcdBDd08f59727c4"
    },
    "ftmTestnet": {
        "token": "0x8C68ad9e912cE8E86D7c95DBAc90E4c79d8c017E",
        "gateway": "0xe2927dbabfdDeAB984CF2dd1ce14346E5c590F14"
    }
}

const chainids = {
    "bscTestnet": 97,
    "ftmTestnet": 4002,
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