// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { BadgeUtils } from "./libraries/BadgeUtils.sol";
import { MetadataUtils } from "./libraries/MetadataUtils.sol";
import { TokenMetadata } from "./types/MetadataTypes.sol";
import "./interfaces/IMetadataBadges.sol";

/**
 * @title MetadataBadges
 * @notice Handles the generation of badges for the charts collection
 */
contract MetadataBadges is IMetadataBadges {
    function generateBadges(TokenMetadata memory metadata) public pure returns (string memory) {
        string memory badges;

        // High Roller
        if (BadgeUtils.isHighRoller(metadata.values)) {
            badges = string(
                abi.encodePacked(badges, MetadataUtils.formatAttribute("high roller", "everything above 50"))
            );
        }

        // Low Stakes
        if (BadgeUtils.isLowStakes(metadata.values)) {
            badges = string(
                abi.encodePacked(badges, MetadataUtils.formatAttribute("low stakes", "everything below 50"))
            );
        }

        // Rugged
        if (BadgeUtils.isRugged(metadata.values)) {
            badges = string(
                abi.encodePacked(badges, MetadataUtils.formatAttribute("rugged", "got rekt on the last day"))
            );
        }
        // Black Swan
        if (BadgeUtils.isBlackSwan(metadata.values)) {
            badges = string(abi.encodePacked(badges, MetadataUtils.formatAttribute("black swan", "has a huge drop")));
        }

        // Moon
        if (BadgeUtils.isMoon(metadata.values)) {
            badges = string(abi.encodePacked(badges, MetadataUtils.formatAttribute("moon", "has a huge spike")));
        }

        // Comeback
        if (BadgeUtils.isComeback(metadata.values)) {
            badges = string(
                abi.encodePacked(badges, MetadataUtils.formatAttribute("comeback", "went low but ended high"))
            );
        }

        // Rags to Riches
        if (BadgeUtils.isRagsToRiches(metadata.values)) {
            badges = string(
                abi.encodePacked(badges, MetadataUtils.formatAttribute("rags to riches", "started low but ended high"))
            );
        }

        // Fumbled
        if (BadgeUtils.isFumbled(metadata.values)) {
            badges = string(
                abi.encodePacked(badges, MetadataUtils.formatAttribute("fumbled", "started high but ended low"))
            );
        }

        // Spike
        if (BadgeUtils.isSpike(metadata.values)) {
            badges = string(
                abi.encodePacked(
                    badges,
                    MetadataUtils.formatAttribute("spike", "one day is significantly higher than the rest")
                )
            );
        }

        // Symmetrical
        if (BadgeUtils.isSymmetrical(metadata.values, metadata.palette)) {
            badges = string(abi.encodePacked(badges, MetadataUtils.formatAttribute("symmetrical", "a mirror image")));
        }

        return badges;
    }
}
