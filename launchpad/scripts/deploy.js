const hre = require("hardhat");

const main = async ()=>{
    // const [owner, superCoder] = await hre.ethers.getSigners();
    const ContractFactory = await hre.ethers.getContractFactory("LaunchpadFactory");
    const contract = await ContractFactory.deploy();
    await contract.deployed();
    console.log("contract depolyed to : ", contract.address)

}

const runMain = async ()=>{
    try {
        await main()
        process.exit(0);
    } catch (error) {
        console.log("error: ",error)
        process.exit(1)
    }
}

runMain();