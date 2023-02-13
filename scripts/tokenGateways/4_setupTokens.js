const hre = require("hardhat");

const tokens = {
    "bsctestnet": "0x858441d954241Fe6CBb857d910717fAa06255a66",
    "goerli": "0x4D4A3544e9f58FdCf0F52cd6d6FBc43dFC5488Ac"
}

const gateways = {
    "bsctestnet": "0xd773541FBe87faCb7b8109f8f63699C6a99EB5e4",
    "goerli": "0x74002519aADd159dED775A29dF75731da86e14f3"
}

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log(`deployer : ${deployer.address}`);

    console.log(`network : ${hre.network.name}`);

    // setup gateway
    console.log("setup token");

    let token = await ethers.getContractAt("BridgeERC20", tokens[hre.network.name]);

    let tx = await token.setGateway(gateways[hre.network.name]);
    let res = await tx.wait();
    console.log(`res : ${JSON.stringify(res)}`);

    let role_minter = "0xac0b6f70df63c6aca41ad1d0c8992138ae940862ca66bd1b43b4508f720a0807";
    let role_burner = "0xab4c8b1524bd6f9a5d544fd60fc1fd3ff04cf0605be184362ae123728d19cf93";
    let res1 = await token.hasRole(role_minter, gateways[hre.network.name]);
    console.log(`has minter role : ${res1}`);
    let res2 = await token.hasRole(role_burner, gateways[hre.network.name]);
    console.log(`has burner role : ${res2}`);

}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});