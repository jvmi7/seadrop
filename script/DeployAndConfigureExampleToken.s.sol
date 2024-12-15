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

        // trade in 4 tokens for a new palette
        uint256[] memory tokenIds = new uint256[](4);
        tokenIds[0] = 1;
        tokenIds[1] = 9;
        tokenIds[2] = 13;
        tokenIds[3] = 14;
        token.convertTokens(tokenIds, 4);

        vm.stopBroadcast();
    }
}
