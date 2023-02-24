const hre = require("hardhat");

const token = "";

const AnyCallProxy = {
    "bscTestnet": "0xcBd52F7E99eeFd9cD281Ea84f3D903906BB677EC",
    "goerli": "0x965f84D915a9eFa2dD81b653e3AE736555d945f4"
}

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log(`deployer : ${deployer.address}`);

    console.log(`network : ${hre.network.name}`);

    let ERC721Gateway_MintBurn = await ethers.getContractFactory("ERC721Gateway_MintBurn");
    let mintburnGateway = await ERC721Gateway_MintBurn.deploy();
    await mintburnGateway.initERC20Gateway(AnyCallProxy[hre.network.name], token, deployer.address);
    console.log(`mintburnGateway is deployed at ${mintburnGateway.address}`);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});