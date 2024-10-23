// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract NFTStaking is Ownable {
  IERC721 public nftCollection;
  IERC20 public rewardToken; // Token ERC-20 para recompensas
  uint256 public rewardRate; // Tasa de recompensas

  struct Staker {
    uint256[] stakedTokens;
    uint256 rewardDebt;
    uint256 lastStakeTime;
  }

  mapping(address => Staker) public stakers;
  mapping(uint256 => address) public tokenOwners;

  // Constructor con llamado explícito a Ownable
  constructor(address _nftCollection, address _rewardToken, uint256 _rewardRate) Ownable(msg.sender) {
    nftCollection = IERC721(_nftCollection);
    rewardToken = IERC20(_rewardToken);
    rewardRate = _rewardRate;
  }

  function stake(uint256 tokenId) external {
    require(nftCollection.ownerOf(tokenId) == msg.sender, 'Not the owner');
    nftCollection.transferFrom(msg.sender, address(this), tokenId);

    stakers[msg.sender].stakedTokens.push(tokenId);
    stakers[msg.sender].lastStakeTime = block.timestamp;
    tokenOwners[tokenId] = msg.sender;
  }

  function unstake(uint256 tokenId) external {
    require(tokenOwners[tokenId] == msg.sender, 'Not the owner');
    nftCollection.transferFrom(address(this), msg.sender, tokenId);

    claimRewards();
    // Eliminar el token de la lista de stakedTokens
    removeTokenFromStaker(msg.sender, tokenId);
  }

  function claimRewards() public {
    Staker storage staker = stakers[msg.sender];
    uint256 stakedTime = block.timestamp - staker.lastStakeTime;
    uint256 reward = stakedTime * rewardRate * staker.stakedTokens.length;

    // Transferir las recompensas al staker
    rewardToken.transfer(msg.sender, reward);

    // Actualizar el tiempo del último stake y la deuda de recompensas
    staker.rewardDebt += reward;
    staker.lastStakeTime = block.timestamp;
  }

  function removeTokenFromStaker(address staker, uint256 tokenId) internal {
    // Lógica para eliminar el token de los stakedTokens del usuario
    uint256[] storage tokens = stakers[staker].stakedTokens;
    for (uint256 i = 0; i < tokens.length; i++) {
      if (tokens[i] == tokenId) {
        tokens[i] = tokens[tokens.length - 1];
        tokens.pop();
        break;
      }
    }
  }
}
