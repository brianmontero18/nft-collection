// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract NFTMarketplace is Ownable {
  IERC20 public paymentToken;

  struct Listing {
    address seller;
    uint256 price;
    bool isERC721; // Indicador para diferenciar entre ERC721 y ERC1155
  }

  mapping(uint256 => Listing) public listings; // Mapeo de tokenId a Listing
  mapping(uint256 => uint256) public listedAmounts; // Cantidad listada para ERC1155

  constructor(address _paymentToken) Ownable(msg.sender) {
    paymentToken = IERC20(_paymentToken);
  }

  function listItemForSale(
    address nftContract,
    uint256 tokenId,
    uint256 amount, // Usado solo para ERC1155
    uint256 price
  ) external {
    bool isERC721 = IERC165(nftContract).supportsInterface(type(IERC721).interfaceId);

    if (isERC721) {
      IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
    } else {
      require(IERC165(nftContract).supportsInterface(type(IERC1155).interfaceId), 'Not ERC1155 or ERC721');
      IERC1155(nftContract).safeTransferFrom(msg.sender, address(this), tokenId, amount, '');
      listedAmounts[tokenId] = amount;
    }

    listings[tokenId] = Listing(msg.sender, price, isERC721);
  }

  function buyItem(
    address nftContract,
    uint256 tokenId,
    uint256 amount // Usado solo para ERC1155
  ) external {
    Listing memory listing = listings[tokenId];
    require(listing.price > 0, 'Item not for sale');

    // Transferir el pago al vendedor
    paymentToken.transferFrom(msg.sender, listing.seller, listing.price);

    if (listing.isERC721) {
      IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
    } else {
      IERC1155(nftContract).safeTransferFrom(address(this), msg.sender, tokenId, amount, '');
      listedAmounts[tokenId] -= amount;
    }

    // Eliminar la entrada de listados si es ERC721 o si la cantidad de ERC1155 es 0
    if (listing.isERC721 || listedAmounts[tokenId] == 0) {
      delete listings[tokenId];
    }
  }

  // Manejo de safeTransferFrom para ERC1155
  function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns (bytes4) {
    return this.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(
    address,
    address,
    uint256[] calldata,
    uint256[] calldata,
    bytes calldata
  ) external pure returns (bytes4) {
    return this.onERC1155BatchReceived.selector;
  }
}
