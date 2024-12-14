// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../types/MetadataTypes.sol";

interface IMetadataGenerator {
    function generateTokenURI(TokenMetadata memory metadata) external pure returns (string memory);
    function generateName(uint256 tokenId) external pure returns (string memory);
    function generateImageURI(uint8[7] memory values, uint8 palette) external pure returns (string memory);
    function generateJSONMetadata(TokenMetadata memory metadata) external pure returns (string memory);
    function generateBasicProperties(TokenMetadata memory metadata) external pure returns (string memory);
    function generateAttributesSection(TokenMetadata memory metadata) external pure returns (string memory);
    function generateValueString(uint8[7] memory values) external pure returns (string memory);
}