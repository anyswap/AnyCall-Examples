const hre = require("hardhat");

const AnyCallProxy = {
    "hardhat": "0x0000000000000000000000000000000000000000",
    "bscTestnet": "0xcBd52F7E99eeFd9cD281Ea84f3D903906BB677EC",
    "goerli": "0x965f84D915a9eFa2dD81b653e3AE736555d945f4",
    "ftmTestnet": "0xfCea2c562844A7D385a7CB7d5a79cfEE0B673D99",
    "fuji": "0x461d52769884ca6235b685ef2040f47d30c94eb5",
    "moonbase": "0x1d7Ca62F6Af49ec66f6680b8606E634E55Ef22C1"
}

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log(`deployer : ${deployer.address}`);

    console.log(`network : ${hre.network.name}`);

    const feeAdmin = "0xfA9dA51631268A30Ec3DDd1CcBf46c65FAD99251";

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

    let CS_SafetyControl = await ethers.getContractFactory("CodeShop_DefaultSafetyControl");
    let cs_SafetyControl = await CS_SafetyControl.deploy();
    await cs_SafetyControl.deployed();
    console.log(`cs_SafetyControl : ${cs_SafetyControl.address}`);

    const BridgeFactory = await ethers.getContractFactory("BridgeFactory");
    console.log(`hre.network.name : ${hre.network.name}`);
    let bridgeFactory = await BridgeFactory.deploy(AnyCallProxy[hre.network.name], [cs_bridgeToken.address, cs_mintBurnGateway.address, cs_poolGateway.address, cs_SafetyControl.address], feeAdmin);
    await bridgeFactory.deployed();
    console.log(`bridgeFactory is deployed at ${bridgeFactory.address}`);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});