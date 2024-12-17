// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IValueGenerator {
    function generateValuesFromSeeds(uint256 tokenId) external view returns (uint8[7] memory);
    function updateRandomSeeds() external;
    function getRandomSeeds() external view returns (bytes32[7] memory);
    function setTokenMintIteration(uint256 tokenId) external;
    function getCurrentIteration() external view returns (uint256);
    function getTokenMintIteration(uint256 tokenId) external view returns (uint256);
    //TODO: Remove for testing purposes
    function fastForwardDays() external;
}