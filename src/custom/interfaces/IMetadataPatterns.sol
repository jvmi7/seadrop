// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IMetadataPatterns {
    function getPattern(uint8[7] memory values) external pure returns (string memory);

    function getTrend(uint8[7] memory values) external pure returns (string memory);
}
