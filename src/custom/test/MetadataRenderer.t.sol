// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "../MetadataRenderer.sol";
import "../interfaces/IValueGenerator.sol";

// Mock contract for ValueGenerator
contract MockValueGenerator is IValueGenerator {
    uint256 private currentIteration = 1;
    mapping(uint256 => uint8[7]) private tokenValues;
    bytes32[7] private randomSeeds;
    mapping(uint256 => bytes32) private tokenValuesSeeds;
    bytes32 private elevatedTokenSeed;

    // Add missing interface implementations
    function updateGenesisTokenSeeds() external {
        // Mock implementation - doesn't need to do anything for tests
    }

    function updateElevatedTokenSeed() external {
        // Mock implementation - doesn't need to do anything for tests
    }

    function getGenesisTokenSeeds() external view returns (bytes32[7] memory) {
        return randomSeeds;
    }

    function getElevatedTokenSeed() external view returns (bytes32) {
        return elevatedTokenSeed;
    }

    function updateRandomSeeds() external {
        // Mock implementation - doesn't need to do anything for tests
    }

    function getRandomSeeds() external view returns (bytes32[7] memory) {
        return randomSeeds;
    }

    function setTokenValuesSeed(uint256 tokenId, bytes32 seed) external {
        tokenValuesSeeds[tokenId] = seed;
    }

    function generateValuesFromSeeds(uint256 tokenId) external view returns (uint8[7] memory) {
        return tokenValues[tokenId];
    }

    function testFastForwardReveal() external {
        // Mock implementation - doesn't need to do anything for tests
    }

    // Helper functions for testing
    function setMockValues(uint256 tokenId, uint8[7] memory values) external {
        tokenValues[tokenId] = values;
    }

    function setMockGenesisTokenSeeds(bytes32[7] memory seeds) external {
        randomSeeds = seeds;
    }

    function incrementIteration() external {
        currentIteration++;
    }
}

contract MetadataRendererTest is Test {
    MetadataRenderer public renderer;
    MockValueGenerator public valueGenerator;
    address public nftContract;


    function setUp() public {
        nftContract = makeAddr("nftContract");
        
        // Deploy contracts without pranking first
        valueGenerator = new MockValueGenerator();
        renderer = new MetadataRenderer(nftContract, address(valueGenerator));
        
        // Now the test contract (address(this)) is the owner
    }

    function testInitialization() public {
        assertEq(address(renderer.nftContract()), nftContract);
        assertEq(address(renderer.valueGenerator()), address(valueGenerator));
    }

    function testSetInitialMetadata() public {
        vm.startPrank(nftContract);
        
        // Test different token IDs get different palettes based on modulo
        renderer.setInitialMetadata(0);
        renderer.setInitialMetadata(1);
        renderer.setInitialMetadata(4);
        
        assertEq(renderer.getTokenPalette(0), 0);
        assertEq(renderer.getTokenPalette(1), 1);
        assertEq(renderer.getTokenPalette(4), 0);
        
        vm.stopPrank();
    }

    function testSetElevatedToken() public {
        vm.startPrank(nftContract);
        
        uint8 elevatedPalette = 4; // Assuming CHROMATIC = 4
        renderer.setElevatedToken(1, elevatedPalette, bytes32(0));
        
        assertTrue(renderer.getIsElevatedToken(1));
        assertEq(renderer.getTokenPalette(1), elevatedPalette);
        
        vm.stopPrank();
    }

    function testSetElevatedTokenInvalidPalette() public {
        vm.startPrank(nftContract);
        
        uint8 invalidPalette = 3; // Below CHROMATIC
        vm.expectRevert(MetadataRenderer.InvalidElevatedPalette.selector);
        renderer.setElevatedToken(1, invalidPalette, bytes32(0));
        
        vm.stopPrank();
    }

    function testOnlyNFTContractModifier() public {
        vm.startPrank(address(0xdead));
        
        vm.expectRevert(MetadataRenderer.OnlyNFTContract.selector);
        renderer.setInitialMetadata(1);
        
        vm.expectRevert(MetadataRenderer.OnlyNFTContract.selector);
        renderer.setElevatedToken(1, 4, bytes32(0));
        
        vm.stopPrank();
    }

    function testGenerateTokenURI() public {
        vm.startPrank(nftContract);
        
        uint8[7] memory mockValues = [1, 2, 3, 4, 5, 6, 7];
        valueGenerator.setMockValues(1, mockValues);
        renderer.setInitialMetadata(1);
        
        string memory uri = renderer.generateTokenURI(1);
        assertTrue(bytes(uri).length > 0);
        
        vm.stopPrank();
    }

    function testSetAnimationUrl() public {
        string memory newUrl = "https://new-animation.url";
        
        // Should revert when called by non-owner
        vm.prank(address(0xdead));
        vm.expectRevert("Ownable: caller is not the owner");
        renderer.setAnimationUrl(newUrl);
        
        // Should succeed when called by owner (test contract)
        renderer.setAnimationUrl(newUrl);
        
        // Verify the URL was updated
        assertEq(renderer.getAnimationUrl(), newUrl);
    }

    function testInitialAnimationUrl() public {
        // Verify the initial animation URL is set correctly from Constants
        assertEq(renderer.getAnimationUrl(), Constants.ANIMATION_URL);
    }
}