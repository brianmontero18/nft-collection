import { ethers } from 'hardhat';

async function main() {
  const [deployer] = await ethers.getSigners();

  // Deploy the logic contract for CollectionManager
  const CollectionManagerLogic = await ethers.getContractFactory('CollectionManager');
  const collectionManagerLogic = await CollectionManagerLogic.deploy();
  await collectionManagerLogic.deployed();
  console.log('CollectionManager logic deployed at:', collectionManagerLogic.address);

  // Deploy ProxyAdmin (if you haven't already deployed one)
  const ProxyAdmin = await ethers.getContractFactory('ProxyAdmin');
  const proxyAdmin = await ProxyAdmin.deploy();
  await proxyAdmin.deployed();
  console.log('ProxyAdmin deployed at:', proxyAdmin.address);

  // Deploy the Proxy for CollectionManager
  const ProxyCollectionManager = await ethers.getContractFactory('TransparentUpgradeableProxy');
  const dataCollectionManager = collectionManagerLogic.interface.encodeFunctionData('initialize', [
    'ERC721_ADDRESS', // Replace with the deployed ERC721 contract address
    'ERC1155_ADDRESS', // Replace with the deployed ERC1155 contract address
    deployer.address, // Admin address
  ]);

  const proxyCollectionManager = await ProxyCollectionManager.deploy(
    collectionManagerLogic.address,
    proxyAdmin.address,
    dataCollectionManager
  );
  await proxyCollectionManager.deployed();
  console.log('CollectionManager Proxy deployed at:', proxyCollectionManager.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
// import "hardhat/console.sol";
