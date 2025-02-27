// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { TokenMetadata } from "../types/MetadataTypes.sol";

interface IMetadataBadges {
    function generateBadges(TokenMetadata memory metadata) external view returns (string memory);
}
