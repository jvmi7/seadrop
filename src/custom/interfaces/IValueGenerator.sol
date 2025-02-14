// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IValueGenerator {
    function generateValuesFromSeeds(uint256 tokenId) external view returns (uint8[7] memory);
    function updateGenesisTokenSeeds() external;
    function updateElevatedTokenSeed() external;
    function getGenesisTokenSeeds() external view returns (bytes32[7] memory);
    function getElevatedTokenSeed() external view returns (bytes32);
    function testFastForwardReveal() external;
    function setTokenValuesSeed(uint256 tokenId, bytes32 seed) external;
}