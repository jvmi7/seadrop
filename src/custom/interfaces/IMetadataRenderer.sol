// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { TokenMetadata } from "../types/MetadataTypes.sol";
import { IValueGenerator } from "./IValueGenerator.sol";

/**
 * @title IMetadataRenderer
 * @notice Interface for the MetadataRenderer contract
 */
interface IMetadataRenderer {
    /**********************************/
    /*              Events            */
    /**********************************/
    event MetadataUpdated(uint256 indexed tokenId);

    /**********************************/
    /*            Functions           */
    /**********************************/
    /// @notice Gets the NFT contract address
    function nftContract() external view returns (address);

    /// @notice Gets the value generator contract
    function valueGenerator() external view returns (IValueGenerator);

    /// @notice Gets the palette of a token
    function getTokenPalette(uint256 tokenId) external view returns (uint8);

    /// @notice Checks if a token is marked as elevated
    function getIsElevatedToken(uint256 tokenId) external view returns (bool);

    /// @notice Sets the initial metadata for a newly minted token
    function setInitialMetadata(uint256 tokenId) external;

    /// @notice Sets a token as an elevated token with a specific palette
    function setElevatedToken(uint256 tokenId, uint8 palette, bytes32 seed) external;

    /// @notice Generates the complete token URI for a given token
    function generateTokenURI(uint256 tokenId) external view returns (string memory);
}