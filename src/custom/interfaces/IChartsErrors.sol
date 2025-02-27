// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IChartsErrors {
    // @notice Authentication errors
    error NotTokenOwner(address caller, uint256 tokenId, address owner);
    error TokenDoesNotExist(uint256 tokenId);

    // @notice Input validation errors
    error InvalidAddress(address addr);
    error InvalidTokenInput(uint256[] tokenIds);
    error InvalidPalette(uint8 palette);

    // @notice State validation errors
    error TokenError(uint256 tokenId);
    error ConversionError(uint8 fromPalette, uint8 toPalette);
    error ElevationError(uint256 elevateTokenId, uint256 burnTokenId);

    // @notice Thrown when trying to elevate tokens that are approved for transfer
    error TokenApprovedForTransfer(uint256 tokenId);

    // @notice Thrown when a contract is not set
    error ContractNotSet(string contractName);

    // @notice Thrown when elevation is disabled
    error ElevationDisabled();
}
