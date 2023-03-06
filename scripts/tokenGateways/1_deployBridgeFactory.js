const hre = require("hardhat");

const AnyCallProxy = {
    "bscTestnet": "0xcBd52F7E99eeFd9cD281Ea84f3D903906BB677EC",
    "goerli": "0x965f84D915a9eFa2dD81b653e3AE736555d945f4",
    "ftmTestnet": "0xfCea2c562844A7D385a7CB7d5a79cfEE0B673D99"
}

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log(`deployer : ${deployer.address}`);

    console.log(`network : ${hre.network.name}`);
    console.log("deploy bridge factory");
    const CodeShop_BridgeToken = await ethers.getContractFactory("CodeShop_BridgeToken");
    let cs_bridgeToken = await CodeShop_BridgeToken.deploy();
    await cs_bridgeToken.deployed();
    console.log(`cs_bridgeToken : ${cs_bridgeToken.address}`);

    const CodeShop_MintBurnGateway = await ethers.getContractFactory("CodeShop_MintBurnGateway");
    let cs_mintBurnGateway = await CodeShop_MintBurnGateway.deploy();
    await cs_mintBurnGateway.deployed();
    console.log(`cs_mintBurnGateway : ${cs_mintBurnGateway.address}`);

    const CodeShop_PoolGateway = await ethers.getContractFactory("CodeShop_PoolGateway");
    let cs_poolGateway = await CodeShop_PoolGateway.deploy();
    await cs_poolGateway.deployed();
    console.log(`cs_poolGateway : ${cs_poolGateway.address}`);

    const BridgeFactory = await ethers.getContractFactory("BridgeFactory");
    let bridgeFactory = await BridgeFactory.deploy(AnyCallProxy[hre.network.name], [cs_bridgeToken.address, cs_mintBurnGateway.address, cs_poolGateway.address]);
    await bridgeFactory.deployed();
    console.log(`bridgeFactory is deployed at ${bridgeFactory.address}`);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});