// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "../MetadataRenderer.sol";
import "../interfaces/IValueGenerator.sol";
import "../libraries/Constants.sol";
// Mock contract for ValueGenerator
// contract MockValueGenerator is IValueGenerator {
//     uint256 private currentIteration = 1;
//     mapping(uint256 => uint8[7]) private tokenValues;
//     bytes32[7] private randomSeeds;
//     mapping(uint256 => bytes32) private tokenValuesSeeds;
//     bytes32 private elevatedTokenSeed;

//     // Add missing interface implementations
//     function updateGenesisTokenSeeds() external {
//         // Mock implementation - doesn't need to do anything for tests
//     }

//     function updateElevatedTokenSeed() external {
//         // Mock implementation - doesn't need to do anything for tests
//     }

//     function getGenesisTokenSeeds() external view returns (bytes32[7] memory) {
//         return randomSeeds;
//     }

//     function getElevatedTokenSeed() external view returns (bytes32) {
//         return elevatedTokenSeed;
//     }

//     function updateRandomSeeds() external {
//         // Mock implementation - doesn't need to do anything for tests
//     }

//     function getRandomSeeds() external view returns (bytes32[7] memory) {
//         return randomSeeds;
//     }

//     function updateStateOnElevate(uint256 tokenId, bytes32 seed) external {
//         tokenValuesSeeds[tokenId] = seed;
//     }

//     function generateValuesFromSeeds(uint256 tokenId) external view returns (uint8[7] memory) {
//         return tokenValues[tokenId];
//     }

//     function fastForwardReveal() external {
//         // Mock implementation - doesn't need to do anything for tests
//     }

//     // Helper functions for testing
//     function setMockValues(uint256 tokenId, uint8[7] memory values) external {
//         tokenValues[tokenId] = values;
//     }

//     function setMockGenesisTokenSeeds(bytes32[7] memory seeds) external {
//         randomSeeds = seeds;
//     }

//     function incrementIteration() external {
//         currentIteration++;
//     }
// }

contract MetadataRendererTest is Test {
    // MetadataRenderer public renderer;
    // MockValueGenerator public valueGenerator;
    // address public nftContract;
    // MetadataImplementation public metadataImplementation;

    // function setUp() public {
    //     nftContract = makeAddr("nftContract");
        
    //     // Deploy contracts without pranking first
    //     valueGenerator = new MockValueGenerator();
    //     renderer = new MetadataRenderer(nftContract, address(valueGenerator), address(metadataImplementation));
        
    //     // Now the test contract (address(this)) is the owner
    // }

    // // 1. Basic Initialization Tests
    // function testInitialization() public {
    //     assertEq(address(renderer.nftContract()), nftContract);
    //     assertEq(address(renderer.valueGenerator()), address(valueGenerator));
    // }

    // function testInitialAnimationUrl() public {
    //     // Verify the initial animation URL is set correctly from Constants
    //     assertEq(renderer.getAnimationUrl(), Constants.ANIMATION_URL);
    // }

    // // 2. Core Functionality Tests
    // function testSetInitialMetadata() public {
    //     vm.startPrank(nftContract);
        
    //     // Test different token IDs get different palettes based on modulo
    //     for (uint256 i = 1; i <= Constants.LEGENDARY_CHARTS_COUNT; i++) {
    //         renderer.setInitialMetadata(i);
    //     }
        
    //     for (uint256 i = 1; i <= Constants.LEGENDARY_CHARTS_COUNT; i++) {
    //         assertEq(renderer.getTokenPalette(i), Constants.LEGENDARY);
    //     }

    //     uint256 lastTokenId = Constants.LEGENDARY_CHARTS_COUNT;
        
    //     renderer.setInitialMetadata(lastTokenId + 1);
    //     renderer.setInitialMetadata(lastTokenId + 2);
    //     renderer.setInitialMetadata(lastTokenId + 3);
    //     renderer.setInitialMetadata(lastTokenId + 4);
    //     renderer.setInitialMetadata(lastTokenId + 5);
    //     renderer.setInitialMetadata(lastTokenId + 6);

    //     assertEq(renderer.getTokenPalette(lastTokenId + 1), Constants.GREENS);
    //     assertEq(renderer.getTokenPalette(lastTokenId + 2), Constants.BLUES);
    //     assertEq(renderer.getTokenPalette(lastTokenId + 3), Constants.VIOLETS);
    //     assertEq(renderer.getTokenPalette(lastTokenId + 4), Constants.REDS);
    //     assertEq(renderer.getTokenPalette(lastTokenId + 5), Constants.YELLOWS);
    //     assertEq(renderer.getTokenPalette(lastTokenId + 6), Constants.GREENS);
    //     vm.stopPrank();
    // }

    // function testGenerateTokenURI() public {
    //     vm.startPrank(nftContract);
        
    //     uint8[7] memory mockValues = [1, 2, 3, 4, 5, 6, 7];
    //     valueGenerator.setMockValues(1, mockValues);
    //     renderer.setInitialMetadata(1);
        
    //     string memory uri = renderer.generateTokenURI(1);
    //     assertTrue(bytes(uri).length > 0);
        
    //     vm.stopPrank();
    // }

    // function testGetValuesForLegendaryToken() public {
    //     vm.startPrank(nftContract);
        
    //     // Test with first legendary token
    //     uint256 legendaryTokenId = 1; // Assuming 1-10 are legendary
    //     renderer.setInitialMetadata(legendaryTokenId);
        
    //     string memory uri = renderer.generateTokenURI(legendaryTokenId);
    //     assertTrue(bytes(uri).length > 0);
        
    //     // Values should match LegendaryValues library
    //     assertEq(renderer.getTokenPalette(legendaryTokenId), Constants.LEGENDARY);
        
    //     vm.stopPrank();
    // }

    // function testGetValuesForNonLegendaryToken() public {
    //     vm.startPrank(nftContract);
        
    //     uint256 nonLegendaryTokenId = Constants.LEGENDARY_CHARTS_COUNT + 1;
    //     uint8[7] memory expectedValues = [1, 2, 3, 4, 5, 6, 7];
    //     valueGenerator.setMockValues(nonLegendaryTokenId, expectedValues);
        
    //     renderer.setInitialMetadata(nonLegendaryTokenId);
    //     string memory uri = renderer.generateTokenURI(nonLegendaryTokenId);
    //     assertTrue(bytes(uri).length > 0);
        
    //     vm.stopPrank();
    // }

    // function testPaletteWraparound() public {
    //     vm.startPrank(nftContract);
        
    //     // Test that palette calculation wraps around correctly
    //     uint256 tokenId = Constants.LEGENDARY_CHARTS_COUNT + 5; // Should be YELLOWS
    //     renderer.setInitialMetadata(tokenId);
    //     assertEq(renderer.getTokenPalette(tokenId), Constants.YELLOWS);
        
    //     tokenId = Constants.LEGENDARY_CHARTS_COUNT + 6; // Should wrap to GREENS
    //     renderer.setInitialMetadata(tokenId);
    //     assertEq(renderer.getTokenPalette(tokenId), Constants.GREENS);
        
    //     vm.stopPrank();
    // }

    // // 3. Elevated Token Tests
    // function testSetElevatedToken() public {
    //     vm.startPrank(nftContract);
        
    //     uint8 elevatedPalette = Constants.CHROMATIC; // Assuming CHROMATIC = 4
    //     renderer.setElevatedToken(1, elevatedPalette, bytes32(0));
        
    //     assertTrue(renderer.getIsElevatedToken(1));
    //     assertEq(renderer.getTokenPalette(1), elevatedPalette);
        
    //     vm.stopPrank();
    // }

    // function testSetElevatedTokenInvalidPalette() public {
    //     vm.startPrank(nftContract);
        
    //     uint8 invalidPalette = Constants.REDS; // Below CHROMATIC
    //     vm.expectRevert(MetadataRenderer.InvalidElevatedPalette.selector);
    //     renderer.setElevatedToken(1, invalidPalette, bytes32(0));
        
    //     vm.stopPrank();
    // }

    // function testElevatedTokenValues() public {
    //     vm.startPrank(nftContract);
        
    //     uint256 tokenId = 100;
    //     bytes32 seed = bytes32(uint256(1));
    //     uint8[7] memory expectedValues = [8, 9, 10, 11, 12, 13, 14];
        
    //     valueGenerator.setMockValues(tokenId, expectedValues);
    //     renderer.setElevatedToken(tokenId, Constants.CHROMATIC, seed);
        
    //     // Verify the seed was set
    //     string memory uri = renderer.generateTokenURI(tokenId);
    //     assertTrue(bytes(uri).length > 0);
        
    //     vm.stopPrank();
    // }

    // function testSetElevatedTokenUpperBound() public {
    //     vm.startPrank(nftContract);
        
    //     // Test upper bound of valid elevated palette
    //     renderer.setElevatedToken(1, Constants.GREYSCALE, bytes32(0));
        
    //     // Test above upper bound
    //     vm.expectRevert(MetadataRenderer.InvalidElevatedPalette.selector);
    //     renderer.setElevatedToken(1, Constants.GREYSCALE + 1, bytes32(0));
        
    //     vm.stopPrank();
    // }

    // // 4. Access Control Tests
    // function testOnlyNFTContractModifier() public {
    //     vm.startPrank(address(0xdead));
        
    //     vm.expectRevert(MetadataRenderer.OnlyNFTContract.selector);
    //     renderer.setInitialMetadata(1);
        
    //     vm.expectRevert(MetadataRenderer.OnlyNFTContract.selector);
    //     renderer.setElevatedToken(1, 4, bytes32(0));
        
    //     vm.stopPrank();
    // }

    // // 5. Admin Functionality Tests
    // function testSetAnimationUrl() public {
    //     string memory newUrl = "https://new-animation.url";
        
    //     // Should revert when called by non-owner
    //     vm.prank(address(0xdead));
    //     vm.expectRevert("Ownable: caller is not the owner");
    //     renderer.setAnimationUrl(newUrl);
        
    //     // Should succeed when called by owner (test contract)
    //     renderer.setAnimationUrl(newUrl);
        
    //     // Verify the URL was updated
    //     assertEq(renderer.getAnimationUrl(), newUrl);
    // }

    // function testEmptyAnimationUrl() public {
    //     // Test setting empty animation URL
    //     renderer.setAnimationUrl("");
    //     assertEq(renderer.getAnimationUrl(), "");
    // }

    // function testLongAnimationUrl() public {
    //     // Test setting a very long animation URL
    //     string memory longUrl = "https://example.com/";
    //     for (uint i = 0; i < 10; i++) {
    //         longUrl = string.concat(longUrl, "very/long/path/");
    //     }
        
    //     renderer.setAnimationUrl(longUrl);
    //     assertEq(renderer.getAnimationUrl(), longUrl);
    // }
}