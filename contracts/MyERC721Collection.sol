// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/utils/Pausable.sol';

contract MyERC721Collection is ERC721, AccessControl, Pausable {
  uint256 private _tokenIdCounter;

  // Define a new role for minting
  bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');

  event TokenMinted(address indexed to, uint256 indexed tokenId);
  event TokenBurned(address indexed owner, uint256 indexed tokenId);

  // Constructor sets up the ERC721 token name, symbol, and default roles
  constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(MINTER_ROLE, msg.sender);
  }

  function setMinterRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
    grantRole(MINTER_ROLE, account);
  }

  // Only accounts with the MINTER_ROLE can mint new tokens
  function mint(address to) external onlyRole(MINTER_ROLE) whenNotPaused {
    _tokenIdCounter++;
    _safeMint(to, _tokenIdCounter);

    emit TokenMinted(to, _tokenIdCounter);
  }

  // Allows burning of tokens by their owner or approved addresses
  function burn(uint256 tokenId) external {
    address owner = ownerOf(tokenId);
    require(_isAuthorized(owner, msg.sender, tokenId), 'Caller is not owner nor approved');

    _burn(tokenId);

    emit TokenBurned(owner, tokenId);
  }

  // Returns the total number of NFTs minted so far
  function totalSupply() public view returns (uint256) {
    return _tokenIdCounter;
  }

  // Pauses all minting functions in case of an emergency
  function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
    _pause();
  }

  // Unpauses the contract and allows minting again
  function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
    _unpause();
  }

  // Override de supportsInterface para incluir los roles de AccessControl
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}
