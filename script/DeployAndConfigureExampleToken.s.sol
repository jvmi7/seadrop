// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import { ERC721SeaDropCustom } from "../src/custom/ERC721SeaDropCustom.sol";
import { MetadataRenderer } from "../src/custom/MetadataRenderer.sol";
import { ValueGenerator } from "../src/custom/generators/ValueGenerator.sol";
import { ISeaDrop } from "../src/interfaces/ISeaDrop.sol";
import { PublicDrop } from "../src/lib/SeaDropStructs.sol";
import { Strings } from "openzeppelin-contracts/utils/Strings.sol";
import { MetadataGenerator } from "../src/custom/generators/MetadataGenerator.sol";
import { Constants } from "../src/custom/libraries/Constants.sol";

contract DeployAndConfigureExampleToken is Script {
    using Strings for uint256;
    
    // Addresses
    address seadrop = 0x00005EA00Ac477B1030CE78506496e8C2dE24bf5;
    address creator = 0x49A177C521B8b0710330392b862293716E2237B9;
    address feeRecipient = 0x49A177C521B8b0710330392b862293716E2237B9;

    // Token config
    uint256 maxSupply = 100;

    // Drop config
    uint16 feeBps = 500; // 5%
    uint80 mintPrice = 0.0000 ether;
    uint16 maxTotalMintableByWallet = 100;

    ERC721SeaDropCustom token;
    ValueGenerator valueGenerator;
    MetadataRenderer renderer;
    MetadataGenerator metadataGenerator;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // First deploy the NFT contract
        address[] memory allowedSeadrop = new address[](1);
        allowedSeadrop[0] = seadrop;

        // Deploy NFT contract
        token = new ERC721SeaDropCustom(
            "Example Token",
            "ExTKN",
            allowedSeadrop
        );

        // Deploy ValueGenerator
        valueGenerator = new ValueGenerator();

        // Deploy MetadataGenerator
        metadataGenerator = new MetadataGenerator();

        // Deploy MetadataRenderer
        renderer = new MetadataRenderer(
            address(token),
            address(valueGenerator),
            address(metadataGenerator)
        );

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
        
        // Mint initial tokens
        ISeaDrop(seadrop).mintPublic{ value: mintPrice * 100 }(
            address(token),
            feeRecipient,
            address(0),
            100 // quantity
        );


        valueGenerator.fastForwardDays();

        // ===== CHROMATIC =====

        // trade in 4 tokens for a new palette
        uint256[] memory tokenIds = new uint256[](4);
        tokenIds[0] = 1;
        tokenIds[1] = 2;
        tokenIds[2] = 3;
        tokenIds[3] = 4;
        token.convertTokens(tokenIds, 4);

        // trade in 4 tokens for a new palette
        uint256[] memory tokenIds1 = new uint256[](4);
        tokenIds1[0] = 5;
        tokenIds1[1] = 6;
        tokenIds1[2] = 7;
        tokenIds1[3] = 8;
        token.convertTokens(tokenIds1, 4);

        // trade in 4 tokens for a new palette
        uint256[] memory tokenIds2 = new uint256[](4);
        tokenIds2[0] = 9;
        tokenIds2[1] = 10;
        tokenIds2[2] = 11;
        tokenIds2[3] = 12;
        token.convertTokens(tokenIds2, 4);

        // trade in 4 tokens for a new palette
        uint256[] memory tokenIds3 = new uint256[](4);
        tokenIds3[0] = 13;
        tokenIds3[1] = 14;
        tokenIds3[2] = 15;
        tokenIds3[3] = 16;
        token.convertTokens(tokenIds3, 4);

        // trade in 4 tokens for a new palette
        uint256[] memory tokenIds4 = new uint256[](4);
        tokenIds4[0] = 17;
        tokenIds4[1] = 18;
        tokenIds4[2] = 19;
        tokenIds4[3] = 20;
        token.convertTokens(tokenIds4, 4);

        // trade in 4 tokens for a new palette
        uint256[] memory tokenIds5 = new uint256[](4);
        tokenIds5[0] = 21;
        tokenIds5[1] = 22;
        tokenIds5[2] = 23;
        tokenIds5[3] = 24;
        token.convertTokens(tokenIds5, 4);

        // ===== PASTEL =====

        // trade in 4 tokens for a new palette
        uint256[] memory tokenIds6 = new uint256[](3);
        tokenIds6[0] = 101;
        tokenIds6[1] = 102;
        tokenIds6[2] = 103;
        token.convertTokens(tokenIds6, 5);

        // trade in 4 tokens for a new palette
        uint256[] memory tokenIds7 = new uint256[](3);
        tokenIds7[0] = 104;
        tokenIds7[1] = 105;
        tokenIds7[2] = 106;
        token.convertTokens(tokenIds7, 5);

        // ===== GREYSCALE =====

        // trade in 4 tokens for a new palette
        uint256[] memory tokenIds8 = new uint256[](2);
        tokenIds8[0] = 107;
        tokenIds8[1] = 108;
        token.convertTokens(tokenIds8, 6);

        vm.stopBroadcast();
    }
}
