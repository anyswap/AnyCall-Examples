const { expect } = require("chai");
const { keccak256, defaultAbiCoder } = require("ethers/lib/utils");

describe("Test bridge factory", function () {
  it("Test bridge factory", async function () {
    /**
     * This script tests bridge factory and gateway contracts.
     * The MintBurnGateway and PoolGateway are deployed on the same testing env
     * with the same underlying token, but represent a cross-chain situation.
     */
    const [owner] = await ethers.getSigners();
    console.log("owner " + owner.address);

    console.log(`chain id : ${hre.network.config.chainId}`);

    // deploy anycall mock
    console.log("\ndeploy anycall mock");
    let AnycallExecutor = await ethers.getContractFactory("AnycallExecutorMock");
    let anycallExecutor = await AnycallExecutor.deploy();
    await anycallExecutor.deployed();
    console.log(`anycallExecutor is deployed at : ${anycallExecutor.address}`);
    let AnyCallProxy = await ethers.getContractFactory("AnyCallProxyMock");
    let anyCallProxy = await AnyCallProxy.deploy(anycallExecutor.address);
    await anyCallProxy.deployed();
    console.log(`anyCallProxy is deployed at : ${anyCallProxy.address}`);

    console.log("\ndeploy gateway factory");
    let CS_BridgeToken = await ethers.getContractFactory("CodeShop_BridgeToken");
    let cs_BridgeToken = await CS_BridgeToken.deploy();
    let CS_MintBurnGateway = await ethers.getContractFactory("CodeShop_MintBurnGateway");
    let cs_MintBurnGateway = await CS_MintBurnGateway.deploy();
    let CS_PoolGateway = await ethers.getContractFactory("CodeShop_PoolGateway");
    let cs_PoolGateway = await CS_PoolGateway.deploy();
    await cs_BridgeToken.deployed();
    console.log(`cs_BridgeToken is deployed at ${cs_BridgeToken.address}`);
    await cs_MintBurnGateway.deployed();
    console.log(`cs_MintBurnGateway is deployed at ${cs_MintBurnGateway.address}`);
    await cs_PoolGateway.deployed();
    console.log(`cs_PoolGateway is deployed at ${cs_PoolGateway.address}`);

    let BridgeFactory = await ethers.getContractFactory("BridgeFactory");
    let bridgeFactory = await BridgeFactory.deploy(anyCallProxy.address, [cs_BridgeToken.address, cs_MintBurnGateway.address, cs_PoolGateway.address], { gasLimit: 1200000 });
    await bridgeFactory.deployed();
    console.log(`bridgeFactory : ${bridgeFactory.address}`);

    // predict contract addresses
    let p_bridgeToken = await bridgeFactory.getBridgeTokenAddress(owner.address, 123);
    console.log(`p_bridgeToken : ${p_bridgeToken}`);
    let p_poolGateway = await bridgeFactory.getPoolGatewayAddress(owner.address, 123);
    console.log(`p_poolGateway : ${p_poolGateway}`);
    let p_mintburnGateway = await bridgeFactory.getMintBurnGatewayAddress(owner.address, 123);
    console.log(`p_mintburnGateway : ${p_mintburnGateway}`);

    // create contracts
    let tx1 = await bridgeFactory.createTokenAndMintBurnGateway("Test token", "TT", 18, owner.address, 123);
    let rc1 = await tx1.wait();
    let events = rc1.events.filter(event => event.event === 'Create');
    [_, tokenAddr] = events[0].args;
    console.log(`tokenAddr : ${tokenAddr}`);
    expect(tokenAddr).to.equal(p_bridgeToken);

    [_, mintburnGatewayAddr] = events[1].args;
    console.log(`mintburnGatewayAddr : ${mintburnGatewayAddr}`);
    expect(mintburnGatewayAddr).to.equal(p_mintburnGateway);

    let tx2 = await bridgeFactory.createPoolGateway(p_bridgeToken, owner.address, 123);
    let rc2 = await tx2.wait();
    let event2 = rc2.events.find(event => event.event === 'Create');
    [_, poolGatewayAddr] = event2.args;
    console.log(`poolGatewayAddr : ${poolGatewayAddr}`);
    expect(poolGatewayAddr).to.equal(p_poolGateway);

    // check contracts
    console.log("\ncheck token setting");
    const token = await hre.ethers.getContractAt("BridgeERC20", tokenAddr);
    expect(await token.name()).to.equal("Test token");
    expect(await token.symbol()).to.equal("TT");
    expect(await token.decimals()).to.equal(18);
    expect(await token.isGateway(mintburnGatewayAddr)).to.equal(true);
    let role_admin = "0x0000000000000000000000000000000000000000000000000000000000000000";
    expect(await token.hasRole(role_admin, owner.address)).to.equal(true);

    console.log("\ncheck pool gateway setting");
    const poolGateway = await hre.ethers.getContractAt("ERC20Gateway_Pool", poolGatewayAddr);
    expect(await poolGateway.admin()).to.equal(owner.address);
    expect(await poolGateway.token()).to.equal(tokenAddr);
    expect(await poolGateway.callProxy()).to.equal(anyCallProxy.address);

    console.log("\ncheck mint-burn gateway setting");
    const mintburnGateway = await hre.ethers.getContractAt("ERC20Gateway_MintBurn", mintburnGatewayAddr);
    expect(await mintburnGateway.admin()).to.equal(owner.address);
    expect(await mintburnGateway.token()).to.equal(tokenAddr);
    expect(await mintburnGateway.callProxy()).to.equal(anyCallProxy.address);

    // setup bridge
    let tx3 = await mintburnGateway.setClientPeers([hre.network.config.chainId], [poolGateway.address]);
    await tx3.wait();
    let tx4 = await poolGateway.setClientPeers([hre.network.config.chainId], [mintburnGateway.address]);
    await tx4.wait();

    // test bridge
    // 1. bridge in through mint-burn gateway
    console.log("\n1. test bridge in through mint-burn gateway")
    // build data (uint amount, uint decimal, address receiver, uint seq)
    let data = ethers.utils.defaultAbiCoder.encode(["uint", "uint", "address", "uint"], [1000000000000000000000n, 18, owner.address, 0]);
    console.log(`data : ${data}`);
    // execute(to, data, from, fromChainID, nonce)
    let tx5 = await anycallExecutor.executeMock(mintburnGateway.address, data, poolGateway.address, hre.network.config.chainId, 0);
    await tx5.wait();
    expect(await token.balanceOf(owner.address)).to.equal(1000000000000000000000n);

    // 2. bridge out through mint-burn gateway
    console.log("\n2. test bridge out through mint-burn gateway")
    let tx6 = await mintburnGateway.Swapout(200000000000000000000n, owner.address, hre.network.config.chainId);
    let rc6 = await tx6.wait();
    let event6 = rc6.events.find(event => event.address === anyCallProxy.address);
    [_, data2, _, _, _] = ethers.utils.defaultAbiCoder.decode(["address", "bytes", "uint", "uint", "bytes"], event6.data);
    console.log(data2);
    // owner balance = 1000 - 200 = 800 TT
    expect(await token.balanceOf(owner.address)).to.equal(800000000000000000000n);

    // 3. deposit to pool gateway
    console.log("\n3. test deposit to pool gateway")
    let tx7 = await token.transfer(poolGateway.address, 400000000000000000000n);
    await tx7.wait();
    // pool balance = 400 TT
    expect(await token.balanceOf(poolGateway.address)).to.equal(400000000000000000000n);
    // owner balance = 800 - 400 = 400 TT
    expect(await token.balanceOf(owner.address)).to.equal(400000000000000000000n);

    // 4. bridge in through pool gateway
    console.log("\n4. test bridge in through pool gateway")
    // bridge in 200 TT
    let tx8 = await anycallExecutor.executeMock(poolGateway.address, data2, mintburnGateway.address, hre.network.config.chainId, 0);
    await tx8.wait();
    // pool balance = 400 - 200 = 200 TT
    expect(await token.balanceOf(poolGateway.address)).to.equal(200000000000000000000n);
    // owner balance = 400 + 200 = 600 TT
    expect(await token.balanceOf(owner.address)).to.equal(600000000000000000000n);

    // 5. bridge out through pool gateway
    let tx9 = await token.approve(poolGateway.address, 100000000000000000000n);
    await tx9.wait();
    let tx10 = await poolGateway.Swapout(100000000000000000000n, owner.address, hre.network.config.chainId);
    let rc10 = await tx10.wait();
    // pool balance = 200 + 100 = 300 TT
    expect(await token.balanceOf(poolGateway.address)).to.equal(300000000000000000000n);
    // owner balance = 600 - 100 = 500 TT
    expect(await token.balanceOf(owner.address)).to.equal(500000000000000000000n);
    let event10 = rc10.events.find(event => event.address === anyCallProxy.address);
    [_, data3, _, _, _] = ethers.utils.defaultAbiCoder.decode(["address", "bytes", "uint", "uint", "bytes"], event10.data);
    console.log(data3);
    expect(data3).to.equal(ethers.utils.defaultAbiCoder.encode(["uint", "uint", "address", "uint"], [100000000000000000000n, 18, owner.address, 1]));

    // test prevent unallowed call
    await expect(
      anycallExecutor.executeMock(mintburnGateway.address, data, owner.address, hre.network.config.chainId, 0)
    ).to.be.revertedWith('AppBase: wrong context');
    await expect(
      anycallExecutor.executeMock(poolGateway.address, data, owner.address, hre.network.config.chainId, 0)
    ).to.be.revertedWith('AppBase: wrong context');
  })
  it("Test nft bridge", async function () {
    const [owner, user1] = await ethers.getSigners();
    console.log("owner " + owner.address);
    console.log("user1 " + user1.address);

    console.log(`chain id : ${hre.network.config.chainId}`);

    // deploy anycall mock
    console.log("\ndeploy anycall mock");
    let AnycallExecutor = await ethers.getContractFactory("AnycallExecutorMock");
    let anycallExecutor = await AnycallExecutor.deploy();
    await anycallExecutor.deployed();
    console.log(`anycallExecutor is deployed at : ${anycallExecutor.address}`);
    let AnyCallProxy = await ethers.getContractFactory("AnyCallProxyMock");
    let anyCallProxy = await AnyCallProxy.deploy(anycallExecutor.address);
    await anyCallProxy.deployed();
    console.log(`anyCallProxy is deployed at : ${anyCallProxy.address}`);

    // 1. create NFT contract
    console.log('\n1. create NFT contract');
    let Test721 = await ethers.getContractFactory("Test721_NFT");
    let nft = await Test721.deploy();
    await nft.initERC721("Test NFT", "TT", owner.address);
    console.log(`nft is deployed at ${nft.address}`);

    // 2. deploy pool gateway
    console.log('\n2. deploy pool gateway');
    let ERC721Gateway_Pool = await ethers.getContractFactory("ERC721Gateway_Pool");
    let poolGateway = await ERC721Gateway_Pool.deploy();
    await poolGateway.initERC20Gateway(anyCallProxy.address, nft.address, owner.address);
    console.log(`poolGateway is deployed at ${poolGateway.address}`);

    // 3. deploy mint-burn gateway
    console.log('\n3. deploy mint-burn gateway');
    let ERC721Gateway_MintBurn = await ethers.getContractFactory("ERC721Gateway_MintBurn");
    let mintburnGateway = await ERC721Gateway_MintBurn.deploy();
    await mintburnGateway.initERC20Gateway(anyCallProxy.address, nft.address, owner.address);
    console.log(`mintburnGateway is deployed at ${poolGateway.address}`);

    // 4. set NFT, set mint-burn gateway
    console.log('\n4. set NFT, set mint-burn gateway');
    await nft.setGateway(mintburnGateway.address);
    expect(await nft.isGateway(mintburnGateway.address)).to.equal(true);
    await nft.revokeGateway(mintburnGateway.address);
    expect(await nft.isGateway(mintburnGateway.address)).to.equal(false);
    await nft.setGateway(mintburnGateway.address);
    expect(await nft.isGateway(mintburnGateway.address)).to.equal(true);

    // 5. set peer
    console.log('\n5. set peer');
    await mintburnGateway.setClientPeers([hre.network.config.chainId], [poolGateway.address]);
    await poolGateway.setClientPeers([hre.network.config.chainId], [mintburnGateway.address]);

    // 6. mint nft
    console.log('\n6. mint nft');
    await nft.grantRole(keccak256(ethers.utils.toUtf8Bytes('role_minter')), owner.address);
    await nft.mint(owner.address, 1);
    await nft.revokeRole(keccak256(ethers.utils.toUtf8Bytes('role_minter')), owner.address);
    expect(await nft.ownerOf(1)).to.equal(owner.address);

    // 7. bridging
    console.log('\n7. bridging');
    await nft.connect(owner).approve(poolGateway.address, 1);
    let tx1 = await poolGateway.connect(owner).Swapout(1, user1.address, hre.network.config.chainId);
    let rc1 = await tx1.wait();
    expect(await nft.ownerOf(1)).to.equal(poolGateway.address);

    await nft.grantRole(keccak256(ethers.utils.toUtf8Bytes('role_burner')), owner.address);
    await nft.burn(1);
    await nft.revokeRole(keccak256(ethers.utils.toUtf8Bytes('role_burner')), owner.address);

    let event1 = rc1.events.find(event => event.address === anyCallProxy.address);
    [_, data1, _, _, _] = ethers.utils.defaultAbiCoder.decode(["address", "bytes", "uint", "uint", "bytes"], event1.data);
    console.log(`data1 : ${data1}`);

    await anycallExecutor.executeMock(mintburnGateway.address, data1, poolGateway.address, hre.network.config.chainId, 0);
    expect(await nft.ownerOf(1)).to.equal(user1.address);

    // 8. bridging back
    console.log('\n8. bridging back');
    console.log(`owner of 1 : ${await nft.ownerOf(1)}`);
    let tx2 = await mintburnGateway.connect(user1).Swapout(1, owner.address, hre.network.config.chainId);
    let rc2 = await tx2.wait();

    await nft.grantRole(keccak256(ethers.utils.toUtf8Bytes('role_minter')), owner.address);
    await nft.mint(poolGateway.address, 1);
    await nft.revokeRole(keccak256(ethers.utils.toUtf8Bytes('role_minter')), owner.address);

    let event2 = rc2.events.find(event => event.address === anyCallProxy.address);
    [_, data2, _, _, _] = ethers.utils.defaultAbiCoder.decode(["address", "bytes", "uint", "uint", "bytes"], event2.data);
    console.log(`data2 : ${data2}`);

    await anycallExecutor.executeMock(poolGateway.address, data2, mintburnGateway.address, hre.network.config.chainId, 0);
    expect(await nft.ownerOf(1)).to.equal(owner.address);
  })
});
