const ethers = require('ethers');
const dotenv = require('dotenv');
dotenv.config();

const contractArtifact = require('../artifacts/contracts/LaunchpadFactory.sol/LaunchpadFactory.json');
const RPC = process.env.SHARDEUM_RPC
const PRIVATE_KEY = process.env.PRIVATE_KEY

const CONTRACT_ADDRESS = "0x373fc47d0092649db1f7e631ef074239f3ccb3c6";

const run = async () => {

    // console.log('RPC and PK',RPC, PRIVATE_KEY)

    const provider = new ethers.providers.JsonRpcProvider(RPC)
    const signer = new ethers.Wallet(PRIVATE_KEY, provider)

    const contract = new ethers.Contract(
        CONTRACT_ADDRESS,
        contractArtifact.abi,
        signer
    )

    const tx = await contract.register_collection(
        "BlueMove",
        "BL",
        10,
        "https://bluemovecdn.s3.ap-northeast-1.amazonaws.com/alpha-dragon",
        500,
        "0x5e47F1691c2139F484204D600695471D45caEA49",
        "0x5e47F1691c2139F484204D600695471D45caEA49",
        false,
        [
            { name: "Public", merkle_root: ethers.constants.HashZero, max_tokens: 5, unit_price: 10000, start_time: 1693366697000, end_time: 1693453097000 }
        ]
    );

    console.log(`Transaction to change the message is ${tx.hash}`);
    await tx.wait();

}

run()