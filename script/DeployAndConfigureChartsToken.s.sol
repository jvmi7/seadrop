// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import { ChartsERC721SeaDrop } from "../src/custom/ChartsERC721SeaDrop.sol";
import { MetadataRenderer } from "../src/custom/MetadataRenderer.sol";
import { ValueGenerator } from "../src/custom/ValueGenerator.sol";
import { ISeaDrop } from "../src/interfaces/ISeaDrop.sol";
import { PublicDrop } from "../src/lib/SeaDropStructs.sol";
import { Strings } from "openzeppelin-contracts/utils/Strings.sol";
import { Constants } from "../src/custom/libraries/Constants.sol";
import { MetadataImplementation } from "../src/custom/MetadataImplementation.sol";
import { MetadataBadges } from "../src/custom/MetadataBadges.sol";
import { MetadataPatterns } from "../src/custom/MetadataPatterns.sol";

contract DeployAndConfigureChartsToken is Script {
    using Strings for uint256;

    // Addresses
    address seadrop = 0x00005EA00Ac477B1030CE78506496e8C2dE24bf5;
    address creator = 0x49A177C521B8b0710330392b862293716E2237B9;
    address feeRecipient = 0x0000a26b00c1F0DF003000390027140000fAa719;
    address chainlinkForwarder = 0x586E12fa9369D1496870E16933C35a8Ba1292007;

    // Token config
    uint256 maxSupply = 200_000_000;

    // Drop config
    uint16 feeBps = 500; // 5%
    uint80 mintPrice = 0.0000 ether;
    uint16 maxTotalMintableByWallet = 24;

    ChartsERC721SeaDrop token;
    ValueGenerator valueGenerator;
    MetadataRenderer renderer;
    MetadataImplementation metadataImplementation;
    MetadataBadges metadataBadges;
    MetadataPatterns metadataPatterns;

    uint256[] elevatedTokenIds; // Array to store elevated token IDs
    uint256[] rareTokenIds;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // First deploy the NFT contract
        address[] memory allowedSeadrop = new address[](1);
        allowedSeadrop[0] = seadrop;

        // Deploy NFT contract
        token = new ChartsERC721SeaDrop("asdfsd", "CXJKS", allowedSeadrop);

        // Deploy MetadataBadges
        metadataBadges = new MetadataBadges();

        // Deploy MetadataPatterns
        metadataPatterns = new MetadataPatterns();

        // Deploy ValueGenerator
        valueGenerator = new ValueGenerator();

        // Set the upkeep address
        valueGenerator.setUpkeepAddress(chainlinkForwarder);

        // Deploy MetadataImplementation
        metadataImplementation = new MetadataImplementation(address(metadataBadges), address(metadataPatterns));

        // Deploy MetadataRenderer with MetadataImplementation address
        renderer = new MetadataRenderer(address(token), address(metadataImplementation), address(valueGenerator));

        // Set the MetadataRenderer in the NFT contract
        token.setMetadataRenderer(address(renderer));

        // Configure the token
        token.setMaxSupply(maxSupply);

        // Configure the drop parameters
        token.updateCreatorPayoutAddress(seadrop, creator);
        token.updateAllowedFeeRecipient(seadrop, feeRecipient, true);
        token.updatePublicDrop(
            seadrop,
            PublicDrop(
                mintPrice,
                uint48(block.timestamp), // start time
                uint48(block.timestamp) + 1000, // end time
                maxTotalMintableByWallet,
                feeBps,
                true
            )
        );

        // Enable elevation
        token.setElevationStatus(true);

        // Mint initial tokens in batches
        uint256 batchSize = 100; // Adjust the batch size as needed
        uint256 totalTokensToMint = 5_000;
        uint256 numBatches = totalTokensToMint / batchSize;

        for (uint256 j = 0; j < numBatches; j++) {
            ISeaDrop(seadrop).mintPublic{ value: mintPrice * batchSize }(
                address(token),
                feeRecipient,
                address(0),
                batchSize // quantity
            );
        }

        // transfer nfts with token ids 20-25 to an address
        for (uint256 i = 20; i <= 25; i++) {
            token.transferFrom(creator, 0xf52c69161f6f22A2A6A0DF110E3F40C2a5a0a702, i);
        }

        // ===== RARE =====
        uint256 numRarePalettes = 100;
        uint256 offset = 100;

        // Convert first 24 tokens into 6 chromatic palettes (4 tokens each)
        for (uint256 i = offset; i < numRarePalettes + offset; i += 2) {
            uint256[] memory tokenIds = new uint256[](2);
            tokenIds[0] = i;
            tokenIds[1] = i + 1;
            token.elevate(tokenIds[0], tokenIds[1]);

            // Store the first tokenId in the elevatedTokenIds array
            elevatedTokenIds.push(tokenIds[0]);
        }

        // Elevate the first 100 tokens from the elevatedTokenIds array
        for (uint256 i = 0; i < 20 && i < elevatedTokenIds.length; i += 2) {
            uint256 elevateTokenId = elevatedTokenIds[i];
            uint256 burnTokenId = elevatedTokenIds[i + 1];
            token.elevate(elevateTokenId, burnTokenId);

            rareTokenIds.push(elevateTokenId);
        }

        for (uint256 i = 0; i < 4 && i < rareTokenIds.length; i += 2) {
            uint256 elevateTokenId = rareTokenIds[i];
            uint256 burnTokenId = rareTokenIds[i + 1];
            token.elevate(elevateTokenId, burnTokenId);
        }

        // Print all deployed contract addresses
        console.log("=== Deployed Contract Addresses ===");
        console.log("NFT Token:", address(token));
        console.log("ValueGenerator:", address(valueGenerator));
        console.log("MetadataRenderer:", address(renderer));
        console.log("=== Configuration Addresses ===");
        console.log("SeaDrop:", seadrop);
        console.log("Creator:", creator);
        console.log("Fee Recipient:", feeRecipient);
    }
}
