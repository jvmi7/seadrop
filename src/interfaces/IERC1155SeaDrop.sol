// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {
    ISeaDropTokenContractMetadata
} from "./ISeaDropTokenContractMetadata.sol";

import {
    MintParams,
    PublicDrop,
    SignedMintValidationParams
} from "../lib/ERC1155SeaDropStructs.sol";

import { AllowListData, CreatorPayout } from "../lib/SeaDropStructs.sol";

/**
 * @dev A helper interface to get and set parameters for ERC1155SeaDrop.
 *      The token does not expose these methods as part of its external
 *      interface to reduce bloat, but does implement them.
 */
interface IERC1155SeaDrop is ISeaDropTokenContractMetadata {
    function updateAllowedSeaport(address[] calldata allowedSeaport) external;

    function updateAllowedFeeRecipient(
        address feeRecipient,
        bool allowed
    ) external;

    function updateCreatorPayouts(
        CreatorPayout[] calldata creatorPayouts
    ) external;

    function updateDropURI(string calldata dropURI) external;

    function updatePublicDrop(
        PublicDrop calldata publicDrop,
        uint256 index
    ) external;

    function updateAllowList(AllowListData calldata allowListData) external;

    function updateSignedMintValidationParams(
        address signer,
        SignedMintValidationParams memory signedMintValidationParams
    ) external;

    function updatePayer(address payer, bool allowed) external;

    function getMintStats(
        address minter,
        uint256 tokenId
    )
        external
        view
        returns (
            uint256 minterNumMinted,
            uint256 minterNumMintedForTokenId,
            uint256 currentTotalSupply,
            uint256 maxSupply
        );

    function getPublicDrop(
        uint256 index
    ) external view returns (PublicDrop memory);

    function getPublicDropIndexes() external view returns (uint256[] memory);

    function getCreatorPayouts() external view returns (CreatorPayout[] memory);

    function getAllowListMerkleRoot() external view returns (bytes32);

    function getAllowedFeeRecipients() external view returns (address[] memory);

    function getSigners() external view returns (address[] memory);

    function getSignedMintValidationParams(
        address signer
    ) external view returns (SignedMintValidationParams memory);

    function getPayers() external view returns (address[] memory);
}