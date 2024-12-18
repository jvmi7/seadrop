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
    event TokenLocked(uint256 indexed tokenId);

    /**********************************/
    /*            Functions           */
    /**********************************/
    /// @notice Gets the NFT contract address
    function nftContract() external view returns (address);

    /// @notice Gets the value generator contract
    function valueGenerator() external view returns (IValueGenerator);

    /// @notice Gets the palette of a token
    function getTokenPalette(uint256 tokenId) external view returns (uint8);

    /// @notice Checks if a token is marked as special
    function getIsSpecialToken(uint256 tokenId) external view returns (bool);
    
    /// @notice Gets the number of revealed values for a token
    function getRevealedValuesCount(uint256 tokenId) external view returns (uint256);

    /// @notice Sets the initial metadata for a newly minted token
    function setInitialMetadata(uint256 tokenId) external;

    /// @notice Sets a token as a special token with a specific palette
    function setSpecialToken(uint256 tokenId, uint8 palette) external;

    /// @notice Locks a token's values permanently
    function lockTokenValues(uint256 tokenId) external;

    /// @notice Generates the complete token URI for a given token
    function generateTokenURI(uint256 tokenId) external view returns (string memory);
}