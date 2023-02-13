const hre = require("hardhat");

const AnyCallProxy = {
    "bsctestnet": "0xcBd52F7E99eeFd9cD281Ea84f3D903906BB677EC",
    "goerli": "0x965f84D915a9eFa2dD81b653e3AE736555d945f4"
}

const Token = {
    "bsctestnet": "0x858441d954241Fe6CBb857d910717fAa06255a66",
    "goerli": "0x4D4A3544e9f58FdCf0F52cd6d6FBc43dFC5488Ac"
}

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log(`deployer : ${deployer.address}`);

    console.log(`network : ${hre.network.name}`);

    const anycallproxy = AnyCallProxy[hre.network.name];
    console.log(`anycallproxy : ${anycallproxy}`);

    // deploy gateway
    console.log("deploy gateway");
    const Gateway = await ethers.getContractFactory("ERC20Gateway_MintBurn");
    let gateway = await Gateway.deploy(anycallproxy, Token[hre.network.name], deployer.address);
    await gateway.deployed();
    console.log(`gateway is deployed at ${gateway.address}`);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});