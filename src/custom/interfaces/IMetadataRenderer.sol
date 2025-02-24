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
    event TokenElevated(uint256 elevateTokenId, uint8 newPalette, uint8 newTier, bytes32 newSeed);

    /**********************************/
    /*            Functions           */
    /**********************************/
    /// @notice Gets the NFT contract address
    function nftContract() external view returns (address);

    /// @notice Gets the value generator contract
    function valueGenerator() external view returns (IValueGenerator);

    /// @notice Gets the palette of a token
    function getTokenPalette(uint256 tokenId) external view returns (uint8);

    /// @notice Gets the seed of a token
    function getTokenSeed(uint256 tokenId) external view returns (bytes32);

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
    function generateTokenURI(uint256 tokenId) external view returns (string memory);
}