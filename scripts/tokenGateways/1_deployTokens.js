const hre = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log(`deployer : ${deployer.address}`);

    console.log(`network : ${hre.network.name}`);

    // deploy token
    console.log("deploy bridge token");
    const Token = await ethers.getContractFactory("BridgeERC20");
    let token = await Token.deploy("Test token", "TT", 6, deployer.address);
    await token.deployed();
    console.log(`token is deployed at ${token.address}`);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});