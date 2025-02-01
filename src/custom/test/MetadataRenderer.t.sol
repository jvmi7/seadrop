// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "../MetadataRenderer.sol";
import "../interfaces/IValueGenerator.sol";

// Mock contract for ValueGenerator
contract MockValueGenerator is IValueGenerator {
    uint256 private currentIteration = 1;
    mapping(uint256 => uint256) private tokenMintIterations;
    mapping(uint256 => uint8[7]) private tokenValues;
    bytes32[7] private randomSeeds;

    // Add missing interface implementations
    function updateRandomSeeds() external {
        // Mock implementation - doesn't need to do anything for tests
    }

    function getRandomSeeds() external view returns (bytes32[7] memory) {
        return randomSeeds;
    }

    // Existing implementations
    function getCurrentIteration() external view returns (uint256) {
        return currentIteration;
    }

    function setTokenMintIteration(uint256 tokenId) external {
        tokenMintIterations[tokenId] = currentIteration;
    }

    function getTokenMintIteration(uint256 tokenId) external view returns (uint256) {
        return tokenMintIterations[tokenId];
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

    function setMockRandomSeeds(bytes32[7] memory seeds) external {
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

    function testSetSpecialToken() public {
        vm.startPrank(nftContract);
        
        uint8 specialPalette = 4; // Assuming CHROMATIC = 4
        renderer.setSpecialToken(1, specialPalette);
        
        assertTrue(renderer.getIsSpecialToken(1));
        assertEq(renderer.getTokenPalette(1), specialPalette);
        
        vm.stopPrank();
    }

    function testSetSpecialTokenInvalidPalette() public {
        vm.startPrank(nftContract);
        
        uint8 invalidPalette = 3; // Below CHROMATIC
        vm.expectRevert(MetadataRenderer.InvalidSpecialPalette.selector);
        renderer.setSpecialToken(1, invalidPalette);
        
        vm.stopPrank();
    }

    function testGetRevealedValuesCount() public {
        vm.startPrank(nftContract);
        
        // Regular token should always return 7
        assertEq(renderer.getRevealedValuesCount(1), 7);
        
        // Special token should return based on iterations
        uint8 specialPalette = 4;
        renderer.setSpecialToken(2, specialPalette);
        assertEq(renderer.getRevealedValuesCount(2), 0);
        
        valueGenerator.incrementIteration();
        assertEq(renderer.getRevealedValuesCount(2), 1);
        
        vm.stopPrank();
    }

    function testOnlyNFTContractModifier() public {
        vm.startPrank(address(0xdead));
        
        vm.expectRevert(MetadataRenderer.OnlyNFTContract.selector);
        renderer.setInitialMetadata(1);
        
        vm.expectRevert(MetadataRenderer.OnlyNFTContract.selector);
        renderer.setSpecialToken(1, 4);
        
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