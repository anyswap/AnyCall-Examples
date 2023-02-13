const { mnemonicToEntropy } = require("ethers/lib/utils");
const hre = require("hardhat");

const tokens = {
    "bsctestnet": "0x858441d954241Fe6CBb857d910717fAa06255a66",
    "goerli": "0x4D4A3544e9f58FdCf0F52cd6d6FBc43dFC5488Ac"
}

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log(`deployer : ${deployer.address}`);

    let token = await ethers.getContractAt("BridgeERC20", tokens[hre.network.name]);
    let role_minter = "0xac0b6f70df63c6aca41ad1d0c8992138ae940862ca66bd1b43b4508f720a0807";

    let tx1 = await token.grantRole(role_minter, deployer.address);
    await tx1.wait();

    let tx2 = await token.mint(deployer.address, 100000000);
    await tx2.wait();

    var balance = await token.balanceOf(deployer.address);
    console.log(`balance : ${balance}`);

    let tx3 = await token.revokeRole(role_minter, deployer.address);
    await tx3.wait();
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});