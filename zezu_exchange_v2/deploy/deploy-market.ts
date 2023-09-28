import { Wallet, utils } from "zksync-web3";
import * as ethers from "ethers";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Deployer } from "@matterlabs/hardhat-zksync-deploy";

// load env file
import dotenv from "dotenv";
dotenv.config();

// load wallet private key from env file
const PRIVATE_KEY = process.env.WALLET_PRIVATE_KEY || "";

if (!PRIVATE_KEY)
  throw "⛔️ Private key not detected! Add it to the .env file!";

// An example of a deploy script that will deploy and call a simple contract.
export default async function (hre: HardhatRuntimeEnvironment) {
  console.log(`Running deploy script for the Marketplace contract`);

  // Initialize the wallet.
  const wallet = new Wallet(PRIVATE_KEY);

  // Create deployer object and load the artifact of the contract you want to deploy.
  const deployer = new Deployer(hre, wallet);
  const contract = await deployer.loadArtifact("Marketplace");

  // Estimate contract deployment fee
  const benefitAddress = `0x41E13C809E6DfB4De936c1180E66b17798B6a91a`;

  const market_contract = await hre.zkUpgrades.deployProxy(deployer.zkWallet, contract, [benefitAddress, 250], { initializer: "initialize" });

  await market_contract.deployed();
  console.log(" deployed to:", market_contract.address);

}
