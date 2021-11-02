// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/**
 * @title ICliq
 * @dev   Contract interface for token contract 
 */
interface IXend {
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function decimals() external view returns (uint8);
  function totalSupply() external view returns (uint256);
  function balanceOf(address) external view returns (uint256);
  function allowance(address, address) external view returns (uint256);
  function transfer(address, uint256) external returns (bool);
  function transferFrom(address, address, uint256) external returns (bool);
}
