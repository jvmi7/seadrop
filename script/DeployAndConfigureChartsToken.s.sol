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

contract DeployAndConfigureChartsToken is Script {
    using Strings for uint256;
    
    // Addresses
    address seadrop = 0x00005EA00Ac477B1030CE78506496e8C2dE24bf5;
    address creator = 0x49A177C521B8b0710330392b862293716E2237B9;
    address feeRecipient = 0x49A177C521B8b0710330392b862293716E2237B9;
    address chainlinkForwarder = 0x586E12fa9369D1496870E16933C35a8Ba1292007;
    
    // Token config
    uint256 maxSupply = 10_000;

    // Drop config
    uint16 feeBps = 500; // 5%
    uint80 mintPrice = 0.0000 ether;
    uint16 maxTotalMintableByWallet = 10_000;

    ChartsERC721SeaDrop token;
    ValueGenerator valueGenerator;
    MetadataRenderer renderer;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // First deploy the NFT contract
        address[] memory allowedSeadrop = new address[](1);
        allowedSeadrop[0] = seadrop;

        // Deploy NFT contract
        token = new ChartsERC721SeaDrop(
            "Example Token",
            "ExTKN",
            allowedSeadrop
        );

        // Deploy ValueGenerator
        valueGenerator = new ValueGenerator();

        valueGenerator.setUpkeepAddress(chainlinkForwarder);



        // Deploy MetadataRenderer
        renderer = new MetadataRenderer(
            address(token),
            address(valueGenerator)
        );

        // Set the MetadataRenderer in the NFT contract
        token.setMetadataRenderer(address(renderer));

        // Set the MetadataRenderer in the ValueGenerator contract
        valueGenerator.setMetadataRenderer(address(renderer));

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
        

        for (uint256 i = 0; i < 10; i++) {  
            // Mint initial tokens
            ISeaDrop(seadrop).mintPublic{ value: mintPrice * 1_000 }(
                address(token),
                feeRecipient,
                address(0),
                1_000 // quantity
            );
        }

        

        // ===== CHROMATIC =====
        uint256 numChromaticPalettes = 12;
        uint256 numPastelPalettes = 2;

        // Convert first 24 tokens into 6 chromatic palettes (4 tokens each)
        for (uint256 i = 0; i < numChromaticPalettes; i++) {
            uint256[] memory tokenIds = new uint256[](4);
            for (uint256 j = 0; j < 4; j++) {
                tokenIds[j] = (i * 4) + j + 1;
            }
            token.convertTokens(tokenIds, 4);
        }

        // // ===== PASTEL =====
        // for (uint256 i = 0; i < numPastelPalettes; i++) {
        //     uint256[] memory tokenIds = new uint256[](3);
        //     for (uint256 j = 0; j < 3; j++) {
        //         tokenIds[j] = (i * 3) + j + 1 + numChromaticPalettes + maxSupply;
        //     }
        //     token.convertTokens(tokenIds, 5);
        // }

        // ===== GREYSCALE =====

        // // trade in 4 tokens for a new palette
        // uint256[] memory tokenIds8 = new uint256[](2);
        // tokenIds8[0] = 10_007;
        // tokenIds8[1] = 10_008;
        // token.convertTokens(tokenIds8, 6);

        // vm.stopBroadcast();

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
