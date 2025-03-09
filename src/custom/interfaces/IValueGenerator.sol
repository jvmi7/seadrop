// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IValueGenerator {
    function generateValuesFromSeeds(uint256 tokenId, bytes32 tokenSeed) external view returns (uint8[7] memory);

    function updateGenesisTokenSeeds() external;
}
