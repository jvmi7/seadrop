// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IChartsErrors {
    /// @notice Authentication errors
    error Unauthorized(address caller, string reason);
    error NotTokenOwner(address caller, uint256 tokenId, address owner);

    /// @notice Input validation errors
    error InvalidAddress(address addr, string reason);
    error InvalidTokenInput(uint256[] tokenIds, string reason);
    error InvalidPalette(uint8 palette, string reason);

    /// @notice State validation errors
    error TokenError(uint256 tokenId, string reason);
    error MetadataError(string reason);
    error ConversionError(uint8 fromPalette, uint8 toPalette, string reason);
}