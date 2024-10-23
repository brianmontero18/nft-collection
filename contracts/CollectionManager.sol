// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './MyERC721Collection.sol';
import './MyERC1155Collection.sol';
import './NFTMarketplace.sol';
import './NFTStaking.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/utils/Pausable.sol';
import '@openzeppelin/contracts/proxy/utils/Initializable.sol';

contract CollectionManager is AccessControl, Pausable, Initializable {
  // References to ERC721 and ERC1155 contracts
  MyERC721Collection private _erc721;
  MyERC1155Collection private _erc1155;
  NFTStaking public stakingContract;
  NFTMarketplace public marketplaceContract;

  // Define roles
  bytes32 public constant SWAP_ROLE = keccak256('SWAP_ROLE');
  bytes32 public constant PAUSER_ROLE = keccak256('PAUSER_ROLE');

  // Event emitted when tokens are swapped
  event TokensSwapped(
    address indexed from1,
    uint256 indexed tokenId1,
    address indexed from2,
    uint256 tokenId2,
    uint256 amount2
  );

  // Constructor initializes the ERC721 and ERC1155 contract references and sets roles
  function initialize(
    address erc721Address,
    address erc1155Address,
    address stakingAddress,
    address marketplaceAddress,
    address admin
  ) public initializer {
    _erc721 = MyERC721Collection(erc721Address);
    _erc1155 = MyERC1155Collection(erc1155Address);
    stakingContract = NFTStaking(stakingAddress);
    marketplaceContract = NFTMarketplace(marketplaceAddress);
    _grantRole(DEFAULT_ADMIN_ROLE, admin);
    _grantRole(SWAP_ROLE, admin);
    _grantRole(PAUSER_ROLE, admin);
  }

  function swapERC721(
    address from1,
    uint256 tokenId1,
    address from2,
    uint256 tokenId2
  ) external onlyRole(SWAP_ROLE) whenNotPaused {
    require(_erc721.ownerOf(tokenId1) == from1, 'Invalid ERC721 ownership for token1');
    require(_erc721.ownerOf(tokenId2) == from2, 'Invalid ERC721 ownership for token2');

    // Intercambiar ERC721 entre from1 y from2
    _erc721.transferFrom(from1, from2, tokenId1);
    _erc721.transferFrom(from2, from1, tokenId2);

    emit TokensSwapped(from1, tokenId1, from2, tokenId2, 1);
  }

  function swapERC1155(
    address from1,
    uint256 tokenId1,
    uint256 amount1,
    address from2,
    uint256 tokenId2,
    uint256 amount2
  ) external onlyRole(SWAP_ROLE) whenNotPaused {
    require(_erc1155.balanceOf(from1, tokenId1) >= amount1, 'Insufficient ERC1155 balance for token1');
    require(_erc1155.balanceOf(from2, tokenId2) >= amount2, 'Insufficient ERC1155 balance for token2');

    // Intercambiar ERC1155 entre from1 y from2
    _erc1155.safeTransferFrom(from1, from2, tokenId1, amount1, '');
    _erc1155.safeTransferFrom(from2, from1, tokenId2, amount2, '');

    emit TokensSwapped(from1, tokenId1, from2, tokenId2, amount2);
  }

  // Función swapTokens que utiliza _swapNFT para hacer el intercambio directo entre from1 y from2
  function swapERC721AndERC1155(
    address from721,
    uint256 tokenId721,
    address from1155,
    uint256 tokenId1155,
    uint256 amount1155
  ) external onlyRole(SWAP_ROLE) whenNotPaused {
    require(_erc721.ownerOf(tokenId721) == from721, 'Invalid ERC721 ownership');
    require(_erc1155.balanceOf(from1155, tokenId1155) >= amount1155, 'Insufficient ERC1155 balance');

    // Transferir ERC721 de from721 a from1155
    _erc721.transferFrom(from721, from1155, tokenId721);
    // Transferir ERC1155 de from1155 a from721
    _erc1155.safeTransferFrom(from1155, from721, tokenId1155, amount1155, '');

    emit TokensSwapped(from721, tokenId721, from1155, tokenId1155, amount1155);
  }

  function stakeNFT(uint256 tokenId) external {
    stakingContract.stake(tokenId);
  }

  function listForSale(address nftContract, uint256 tokenId, uint256 price, uint256 amount) external {
    marketplaceContract.listItemForSale(nftContract, tokenId, amount, price);
  }

  // Function to pause the contract in case of an emergency
  function pause() external onlyRole(PAUSER_ROLE) {
    _pause();
  }

  // Function to unpause the contract
  function unpause() external onlyRole(PAUSER_ROLE) {
    _unpause();
  }
}
