// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IValueGenerator {
    function generateValuesFromSeeds(uint256 tokenId) external view returns (uint8[7] memory);
    function updateDailySeeds() external;
    function getRandomSeeds() external view returns (bytes32[7] memory);
     //TODO: Remove for testing purposes
    function fastForwardDays() external;
}