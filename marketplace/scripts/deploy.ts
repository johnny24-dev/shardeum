
const hre = require('hardhat');
async function main() {
  const Marketplace = await hre.ethers.getContractFactory("Marketplace");
  console.log("Deploying Marketplace...");
  const marketplace = await hre.upgrades.deployProxy(Marketplace, ["0x41D5cE16F06E672CA55402ccAE993790337e28A4",300], { initializer: 'initialize' }, {
    gas:6000000,
    gasPrice:300
  });
  console.log("Marketplace deployed to:", marketplace.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });


  const abi = [
    `function approve(address to, uint256 tokenId) external`,
    `function getApproved(uint256 tokenId) external view returns (address operator)`
  ]