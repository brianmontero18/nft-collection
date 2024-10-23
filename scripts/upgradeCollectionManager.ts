import { ethers } from 'hardhat';

async function main() {
  // Deploy new version of logic contract for CollectionManager
  const CollectionManagerLogicV2 = await ethers.getContractFactory('CollectionManagerV2');
  const collectionManagerLogicV2 = await CollectionManagerLogicV2.deploy();
  await collectionManagerLogicV2.deployed();
  console.log('CollectionManager logic V2 deployed at:', collectionManagerLogicV2.address);

  // Get the ProxyAdmin contract
  const proxyAdmin = await ethers.getContractAt('ProxyAdmin', 'PROXY_ADMIN_ADDRESS_HERE');

  // Upgrade the proxy for CollectionManager
  await proxyAdmin.upgrade('COLLECTION_MANAGER_PROXY_ADDRESS_HERE', collectionManagerLogicV2.address);
  console.log('CollectionManager Proxy upgraded to new logic contract');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
