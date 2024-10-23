import { loadFixture } from '@nomicfoundation/hardhat-toolbox/network-helpers';
import { expect } from 'chai';
import hre from 'hardhat';

describe('CollectionManager', function () {
  async function deployCollectionManagerFixture() {
    const [admin, user1, user2] = await hre.ethers.getSigners();

    const MyERC721Collection = await hre.ethers.getContractFactory('MyERC721Collection');
    const MyERC1155Collection = await hre.ethers.getContractFactory('MyERC1155Collection');
    const NFTStaking = await hre.ethers.getContractFactory('NFTStaking');
    const NFTMarketplace = await hre.ethers.getContractFactory('NFTMarketplace');

    const erc721 = await MyERC721Collection.deploy('MyERC721', 'M721');
    const erc1155 = await MyERC1155Collection.deploy('https://metadata.uri/');
    const staking = await NFTStaking.deploy();
    const marketplace = await NFTMarketplace.deploy();

    const CollectionManager = await hre.ethers.getContractFactory('CollectionManager');
    const collectionManager = await CollectionManager.deploy();
    await collectionManager.initialize(
      erc721.getAddress(),
      erc1155.getAddress(),
      staking.getAddress(),
      marketplace.getAddress(),
      admin.getAddress()
    );

    await erc721.mint(user1.getAddress()); // Minting tokenId 1
    await erc721.mint(user2.getAddress()); // Minting tokenId 2
    await erc1155.mint(user1.getAddress(), 1, 100, ''); // Minting 100 units of tokenId 1
    await erc1155.mint(user2.getAddress(), 2, 200, ''); // Minting 200 units of tokenId 2

    return { collectionManager, erc721, erc1155, staking, marketplace, admin, user1, user2 };
  }

  it('Should swap ERC721 tokens between users', async function () {
    const { collectionManager, erc721, user1, user2 } = await loadFixture(deployCollectionManagerFixture);

    await erc721.connect(user1).approve(collectionManager.getAddress(), 1); // Approve tokenId 1
    await erc721.connect(user2).approve(collectionManager.getAddress(), 2); // Approve tokenId 2

    const tx = await collectionManager.connect(user1).swapERC721(user1.getAddress(), 1, user2.getAddress(), 2);
    await expect(tx)
      .to.emit(collectionManager, 'TokensSwapped')
      .withArgs(user1.getAddress(), 1, user2.getAddress(), 2, 1);

    // Validate ownership after swap
    expect(await erc721.ownerOf(1)).to.equal(user2.getAddress());
    expect(await erc721.ownerOf(2)).to.equal(user1.getAddress());
  });

  it('Should swap ERC1155 tokens between users', async function () {
    const { collectionManager, erc1155, user1, user2 } = await loadFixture(deployCollectionManagerFixture);

    await erc1155.connect(user1).setApprovalForAll(collectionManager.getAddress(), true); // Approve all for user1
    await erc1155.connect(user2).setApprovalForAll(collectionManager.getAddress(), true); // Approve all for user2

    const tx = await collectionManager
      .connect(user1)
      .swapERC1155(user1.getAddress(), 1, 50, user2.getAddress(), 2, 100);
    await expect(tx)
      .to.emit(collectionManager, 'TokensSwapped')
      .withArgs(user1.getAddress(), 1, user2.getAddress(), 2, 100);

    // Validate balances after swap
    expect(await erc1155.balanceOf(user1.getAddress(), 1)).to.equal(50);
    expect(await erc1155.balanceOf(user2.getAddress(), 1)).to.equal(50);
    expect(await erc1155.balanceOf(user1.getAddress(), 2)).to.equal(100);
    expect(await erc1155.balanceOf(user2.getAddress(), 2)).to.equal(100);
  });

  it('Should swap between ERC721 and ERC1155 tokens', async function () {
    const { collectionManager, erc721, erc1155, user1, user2 } = await loadFixture(deployCollectionManagerFixture);

    await erc721.connect(user1).approve(collectionManager.getAddress(), 1); // Approve tokenId 1 for ERC721
    await erc1155.connect(user2).setApprovalForAll(collectionManager.getAddress(), true); // Approve all for ERC1155

    const tx = await collectionManager
      .connect(user1)
      .swapERC721AndERC1155(user1.getAddress(), 1, user2.getAddress(), 2, 100);
    await expect(tx)
      .to.emit(collectionManager, 'TokensSwapped')
      .withArgs(user1.getAddress(), 1, user2.getAddress(), 2, 100);

    // Validate balances and ownership after swap
    expect(await erc721.ownerOf(1)).to.equal(user2.getAddress());
    expect(await erc1155.balanceOf(user1.getAddress(), 2)).to.equal(100);
  });

  it('Should allow staking of an NFT', async function () {
    const { collectionManager, staking, erc721, user1 } = await loadFixture(deployCollectionManagerFixture);

    await erc721.connect(user1).approve(collectionManager.getAddress(), 1);
    const tx = await collectionManager.connect(user1).stakeNFT(erc721.getAddress(), 1);

    await expect(tx).to.emit(staking, 'Staked').withArgs(erc721.getAddress(), 1);
  });

  it('Should list an NFT for sale in the marketplace', async function () {
    const { collectionManager, marketplace, erc721, user1 } = await loadFixture(deployCollectionManagerFixture);

    await erc721.connect(user1).approve(collectionManager.getAddress(), 1);
    const tx = await collectionManager
      .connect(user1)
      .listForSale(erc721.getAddress(), 1, hre.ethers.parseEther('10'), 1);

    await expect(tx)
      .to.emit(marketplace, 'ItemListed')
      .withArgs(erc721.getAddress(), 1, 1, hre.ethers.parseEther('10'));
  });
});
