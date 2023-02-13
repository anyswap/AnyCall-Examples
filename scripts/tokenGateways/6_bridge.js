const { mnemonicToEntropy } = require("ethers/lib/utils");
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

    var toChainId = 0;
    for (const name in chainids) {
        if (name !== hre.network.name) {
            toChainId = chainids[name];
        }
    }
    console.log(`toChainId : ${toChainId}`);

    let gateway = await ethers.getContractAt("ERC20Gateway", gateways[hre.network.name]);
    let tx4 = await gateway.Swapout(1000000, deployer.address, toChainId, { value: 20000000000000000n });
    await tx4.wait();
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});