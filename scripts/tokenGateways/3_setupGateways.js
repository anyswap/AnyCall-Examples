const hre = require("hardhat");

const gateways = {
    "bsctestnet": "0xd773541FBe87faCb7b8109f8f63699C6a99EB5e4",
    "goerli": "0x74002519aADd159dED775A29dF75731da86e14f3"
}

const chainids = {
    "bsctestnet": 97,
    "goerli": 5
}

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log(`deployer : ${deployer.address}`);

    console.log(`network : ${hre.network.name}`);

    // setup gateway
    console.log("setup gateway");
    var peerchainids = [];
    var peergateways = [];
    for (const name in chainids) {
        if (name !== hre.network.name) {
            peerchainids.push(chainids[name]);
            peergateways.push(gateways[name]);
        }
    }
    console.log(`peer chainids : ${peerchainids}`);
    console.log(`peer gateways : ${peergateways}`);

    let gateway = await ethers.getContractAt("AnyCallApp", gateways[hre.network.name]);
    let tx = await gateway.setClientPeers(peerchainids, peergateways);
    let res = await tx.wait();
    console.log(`res : ${JSON.stringify(res)}`);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});