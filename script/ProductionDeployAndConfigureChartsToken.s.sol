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

contract ProductionDeployAndConfigureChartsToken is Script {
    using Strings for uint256;

    // Addresses
    address seadrop = 0x00005EA00Ac477B1030CE78506496e8C2dE24bf5;
    // TODO: change to the actual creator address
    address creator = 0x49A177C521B8b0710330392b862293716E2237B9;
    address feeRecipient = 0x0000a26b00c1F0DF003000390027140000fAa719;
    // TODO: change to the actual chainlink forwarder address
    address chainlinkForwarder = 0x586E12fa9369D1496870E16933C35a8Ba1292007;

    // Token config
    uint256 maxSupply = 200_000_000;

    // // Drop config
    // uint16 feeBps = 500; // 5%
    // uint80 mintPrice = 0.01 ether;
    // uint16 maxTotalMintableByWallet = 30;

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

        uint80 mintPrice = 0 ether;
        uint16 maxTotalMintableByWallet = 10_000;
        uint16 feeBps = 500;

        // First deploy the NFT contract
        address[] memory allowedSeadrop = new address[](1);
        allowedSeadrop[0] = seadrop;

        // Deploy NFT contract
        token = new ChartsERC721SeaDrop("sakldfjaskldfjasd", "XXXXXX", allowedSeadrop);

        // Deploy MetadataBadges
        metadataBadges = new MetadataBadges();

        // Deploy MetadataPatterns
        metadataPatterns = new MetadataPatterns();

        // Deploy MetadataImplementation
        metadataImplementation = new MetadataImplementation(address(metadataBadges), address(metadataPatterns));

        // Deploy ValueGenerator
        valueGenerator = new ValueGenerator();

        // Set the upkeep address
        valueGenerator.setUpkeepAddress(chainlinkForwarder);

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

        // Mint initial tokens in batches
        uint8 numLegendary = 16;

        ISeaDrop(seadrop).mintPublic{ value: 0 }(address(token), feeRecipient, address(0), numLegendary);

        // mint extra tokens for testing in batches
        for (uint256 i = 0; i < 5; i++) {
            ISeaDrop(seadrop).mintPublic{ value: 0 }(address(token), feeRecipient, address(0), 50);
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
