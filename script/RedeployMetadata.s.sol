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

contract RedeployMetadata is Script {
    using Strings for uint256;
    address chartsContract = 0xb679683E562b183161d5f3F93c6fA1d3115c4D30;

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

        // Deploy MetadataBadges
        metadataBadges = new MetadataBadges();

        // Deploy MetadataPatterns
        metadataPatterns = new MetadataPatterns();

        // Deploy MetadataImplementation
        metadataImplementation = new MetadataImplementation(address(metadataBadges), address(metadataPatterns));

        // Deploy ValueGenerator
        valueGenerator = new ValueGenerator();

        // Deploy MetadataRenderer with MetadataImplementation address
        renderer = new MetadataRenderer(chartsContract, address(metadataImplementation), address(valueGenerator));

        // Initialize the legendary metadata
        renderer.initializeLegendaryMetadata();

        console.log("MetadataRenderer deployed at:", address(renderer));
        console.log("MetadataImplementation deployed at:", address(metadataImplementation));
        console.log("ValueGenerator deployed at:", address(valueGenerator));
        console.log("Don't forget to set the MetadataRenderer in the ChartsERC721SeaDrop contract");
    }
}
