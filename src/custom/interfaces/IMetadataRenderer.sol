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

    event TokenElevated(
        bytes32 indexed seed,
        uint256 indexed elevateTokenId,
        uint256 indexed burnTokenId,
        uint8[7] elevateValues,
        uint8 elevatePalette,
        uint8[7] burnValues,
        uint8 burnPalette,
        uint8[7] newValues,
        uint8 newPalette
    );

    /**********************************/
    /*            Functions           */
    /**********************************/

    /// @notice Gets the palette of a token
    function tokenPalettes(uint256 tokenId) external view returns (uint8);

    /// @notice Gets the seed of a token
    function tokenSeeds(uint256 tokenId) external view returns (bytes32);

    /// @notice Gets the NFT contract address
    function nftContract() external view returns (address);

    /// @notice Gets the value generator contract
    function valueGenerator() external view returns (IValueGenerator);

    /// @notice Sets the initial metadata for a newly minted token
    function initializeTokenMetadata(uint256 tokenId) external;

    /// @notice Sets a token as an elevated token with a specific palette
    function elevate(uint256 elevateTokenId, uint256 burnTokenId) external;

    /// @notice Sets the address of the MetadataImplementation contract
    function setMetadataImplementation(address _metadataImplementation) external;

    /// @notice Sets the address of the ValueGenerator contract
    function setValueGenerator(address _valueGenerator) external;

    /// @notice Sets the animation URL
    function setAnimationUrl(string memory _animationUrl) external;

    /// @notice Generates the complete token URI for a given token
    function getTokenURI(uint256 tokenId) external view returns (string memory);
}
