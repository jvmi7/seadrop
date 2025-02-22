// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "../ChartsERC721SeaDrop.sol";
import "../interfaces/IMetadataRenderer.sol";
import "../interfaces/IValueGenerator.sol";
import "../MetadataImplementation.sol";
import "../libraries/Palettes.sol";

// Mock MetadataRenderer contract for testing
contract MockMetadataRenderer is IMetadataRenderer {
    mapping(uint256 => uint8) public tokenPalettes;
    mapping(uint256 => bool) public elevatedTokens;
    address public nftContractAddress;
    IValueGenerator public valueGen;
    MetadataImplementation public metadataImplementation;
    // Required interface implementations
    function nftContract() external view returns (address) {
        return nftContractAddress;
    }

    function setMetadataImplementation(address _metadataImplementation) external {
        metadataImplementation = MetadataImplementation(_metadataImplementation);
    }
    
    function generateTokenURI(uint256 tokenId) external view returns (string memory) {
        return "test-uri";
    }

    function setInitialMetadata(uint256 tokenId) external {
        tokenPalettes[tokenId] = 0;
    }


    function setElevatedToken(uint256 tokenId, uint8 palette, bytes32 seed) external {
        elevatedTokens[tokenId] = true;
        tokenPalettes[tokenId] = palette;
        valueGen.updateStateOnElevate(tokenId, seed);
    }

    function getTokenPalette(uint256 tokenId) external view returns (uint8) {
        return tokenPalettes[tokenId];
    }

    function getIsElevatedToken(uint256 tokenId) external view returns (bool) {
        return elevatedTokens[tokenId];
    }

    function valueGenerator() external view returns (IValueGenerator) {
        return valueGen;
    }

    function getRevealedValuesCount(uint256) external pure returns (uint256) {
        return 0;
    }

    // Helper functions for testing
    function setTokenPalette(uint256 tokenId, uint8 palette) external {
        tokenPalettes[tokenId] = palette;
    }

    function setNFTContract(address _nftContract) external {
        nftContractAddress = _nftContract;
    }

    function setValueGenerator(address _valueGenerator) external override {
        valueGen = IValueGenerator(_valueGenerator);
    }
}
// Mock ValueGenerator contract for testing
contract MockValueGenerator is IValueGenerator {
    function updateStateOnElevate(uint256, bytes32) external pure {}
    
    function getTokenValue(uint256, uint256) external pure returns (uint256) {
        return 0;
    }
    
    function getTokenValues(uint256) external pure returns (uint256[] memory) {
        return new uint256[](0);
    }

    function generateValuesFromSeeds(uint256) external pure returns (uint8[7] memory) {
        return [uint8(0), 0, 0, 0, 0, 0, 0];
    }

    function updateGenesisTokenSeeds() external pure {}

    function updateElevatedTokenSeed() external pure {}

    function getGenesisTokenSeeds() external pure returns (bytes32[7] memory) {
        return [bytes32(0), bytes32(0), bytes32(0), bytes32(0), bytes32(0), bytes32(0), bytes32(0)];
    }

    function getElevatedTokenSeed() external pure returns (bytes32) {
        return bytes32(0);
    }

    function fastForwardReveal() external pure {}
}

contract ChartsERC721SeaDropTest is Test {
    ChartsERC721SeaDrop public charts;
    MockMetadataRenderer public renderer;
    address public seaDropAddress;
    address public owner;
    address public user1;
    address public user2;

    event TokensElevated(uint256 elevateTokenId, uint256 burnTokenId);
    event MetadataRendererUpdated(address indexed oldRenderer, address indexed newRenderer);

    function setUp() public {
        owner = address(this);
        user1 = address(0x1);
        user2 = address(0x2);
        seaDropAddress = address(0x3);

        address[] memory allowedSeaDrop = new address[](1);
        allowedSeaDrop[0] = seaDropAddress;

        charts = new ChartsERC721SeaDrop("Charts", "CHRTS", allowedSeaDrop);
        renderer = new MockMetadataRenderer();
        
        // Set metadata renderer
        charts.setMetadataRenderer(address(renderer));

        // Set max supply to allow minting in tests
        charts.setMaxSupply(100);
    }

    // 1. Setup and Metadata Renderer Tests
    function testSetMetadataRenderer() public {
        address newRenderer = address(0x4);
        vm.expectEmit(true, true, false, false);
        emit MetadataRendererUpdated(address(renderer), newRenderer);
        charts.setMetadataRenderer(newRenderer);
    }

    function testSetMetadataRendererRevertZeroAddress() public {
        vm.expectRevert(abi.encodeWithSelector(IChartsErrors.InvalidAddress.selector, address(0)));
        charts.setMetadataRenderer(address(0));
    }

    // 2. Basic Minting Tests
    function testMintSeaDrop() public {
        vm.startPrank(seaDropAddress);
        charts.mintSeaDrop(user1, 1);
        assertEq(charts.balanceOf(user1), 1);
        assertEq(charts.ownerOf(1), user1);
        vm.stopPrank();
    }

    // 3. Token URI Tests
    function testTokenURI() public {
        vm.prank(seaDropAddress);
        charts.mintSeaDrop(user1, 1);

        assertEq(charts.tokenURI(1), "test-uri");
    }

    function testTokenURIRevertNonexistent() public {
        vm.expectRevert();
        charts.tokenURI(1);
    }

    // 4. Elevation Tests - Successful Cases
    function testElevateGenesisToChromatic() public {
        // Setup: Mint two tokens to user1
        vm.startPrank(seaDropAddress);
        charts.mintSeaDrop(user1, 2);
        vm.stopPrank();

        // Set genesis palettes (0-4) for both tokens
        renderer.setTokenPalette(1, Constants.REDS);
        renderer.setTokenPalette(2, Constants.GREENS);

        // Setup value generator
        MockValueGenerator valueGen = new MockValueGenerator();
        renderer.setValueGenerator(address(valueGen));
        renderer.setNFTContract(address(charts));

        // Perform elevation
        vm.startPrank(user1);
        vm.expectEmit(false, false, false, true);
        emit TokensElevated(1, 2);
        charts.elevate(1, 2);
        vm.stopPrank();

        // Verify results
        assertEq(renderer.getTokenPalette(1), Constants.CHROMATIC);
        assertTrue(renderer.getIsElevatedToken(1));
        vm.expectRevert(); // Should revert when trying to access burned token
        charts.ownerOf(2);
    }

    function testElevateChromaticToPastel() public {
        // Setup: Mint two tokens to user1
        vm.startPrank(seaDropAddress);
        charts.mintSeaDrop(user1, 2);
        vm.stopPrank();

        // Set both tokens to CHROMATIC
        renderer.setTokenPalette(1, Constants.CHROMATIC);
        renderer.setTokenPalette(2, Constants.CHROMATIC);

        // Setup value generator
        MockValueGenerator valueGen = new MockValueGenerator();
        renderer.setValueGenerator(address(valueGen));
        renderer.setNFTContract(address(charts));

        // Perform elevation
        vm.startPrank(user1);
        charts.elevate(1, 2);
        vm.stopPrank();

        // Verify results
        assertEq(renderer.getTokenPalette(1), Constants.PASTEL);
        assertTrue(renderer.getIsElevatedToken(1));
    }

    function testElevatePastelToGreyscale() public {
        // Setup: Mint two tokens to user1
        vm.startPrank(seaDropAddress);
        charts.mintSeaDrop(user1, 2);
        vm.stopPrank();

        // Set both tokens to PASTEL
        renderer.setTokenPalette(1, Constants.PASTEL);
        renderer.setTokenPalette(2, Constants.PASTEL);

        // Setup value generator
        MockValueGenerator valueGen = new MockValueGenerator();
        renderer.setValueGenerator(address(valueGen));
        renderer.setNFTContract(address(charts));

        // Perform elevation
        vm.startPrank(user1);
        charts.elevate(1, 2);
        vm.stopPrank();

        // Verify results
        assertEq(renderer.getTokenPalette(1), Constants.GREYSCALE);
        assertTrue(renderer.getIsElevatedToken(1));
        vm.expectRevert(); // Should revert when trying to access burned token
        charts.ownerOf(2);
    }

    // 5. Elevation Tests - Error Cases
    function testElevateRevertNotOwner() public {
        // Setup: Mint tokens to different users
        vm.startPrank(seaDropAddress);
        charts.mintSeaDrop(user1, 1);
        charts.mintSeaDrop(user2, 1);
        vm.stopPrank();

        // Try to elevate with tokens owned by different users
        vm.startPrank(user1);
        vm.expectRevert(abi.encodeWithSelector(IChartsErrors.NotTokenOwner.selector, user1, 2, user2));
        charts.elevate(1, 2);
        vm.stopPrank();
    }

    function testElevateRevertSameToken() public {
        // Setup: Mint token to user1
        vm.startPrank(seaDropAddress);
        charts.mintSeaDrop(user1, 1);
        vm.stopPrank();

        // Try to elevate using the same token
        vm.startPrank(user1);
        vm.expectRevert(abi.encodeWithSelector(IChartsErrors.ElevateError.selector, 1, 1));
        charts.elevate(1, 1);
        vm.stopPrank();
    }

    function testElevateRevertInvalidPaletteCombination() public {
        // Setup: Mint two tokens to user1
        vm.startPrank(seaDropAddress);
        charts.mintSeaDrop(user1, 2);
        vm.stopPrank();

        // Set different palette levels
        renderer.setTokenPalette(1, Constants.CHROMATIC);
        renderer.setTokenPalette(2, Constants.BLUES); // genesis palette

        // Try to elevate tokens with different palette levels
        vm.startPrank(user1);
        vm.expectRevert(abi.encodeWithSelector(IChartsErrors.ElevateError.selector, 1, 2));
        charts.elevate(1, 2);
        vm.stopPrank();
    }

    function testElevateRevertGreyscale() public {
        // Setup: Mint two tokens to user1
        vm.startPrank(seaDropAddress);
        charts.mintSeaDrop(user1, 2);
        vm.stopPrank();

        // Set one token to greyscale
        renderer.setTokenPalette(1, Constants.GREYSCALE);
        renderer.setTokenPalette(2, Constants.PASTEL);

        // Try to elevate with a greyscale token
        vm.startPrank(user1);
        vm.expectRevert(abi.encodeWithSelector(IChartsErrors.ElevateError.selector, 1, 2));
        charts.elevate(1, 2);
        vm.stopPrank();
    }

    function testElevateRevertPastelWithChromatic() public {
        // Setup: Mint two tokens to user1
        vm.startPrank(seaDropAddress);
        charts.mintSeaDrop(user1, 2);
        vm.stopPrank();

        // Set different special palettes
        renderer.setTokenPalette(1, Constants.PASTEL);
        renderer.setTokenPalette(2, Constants.CHROMATIC);

        // Try to elevate tokens with mismatched special palettes
        vm.startPrank(user1);
        vm.expectRevert(abi.encodeWithSelector(IChartsErrors.ElevateError.selector, 1, 2));
        charts.elevate(1, 2);
        vm.stopPrank();
    }

    function testElevateRevertNonexistentTokens() public {
        vm.startPrank(user1);
        vm.expectRevert(); // Should revert when trying to elevate non-existent tokens
        charts.elevate(999, 1000);
        vm.stopPrank();
    }

    function testElevateRevertAfterTransfer() public {
        // Setup: Mint two tokens to user1
        vm.startPrank(seaDropAddress);
        charts.mintSeaDrop(user1, 2);
        vm.stopPrank();

        // Set basic palettes
        renderer.setTokenPalette(1, Constants.REDS);
        renderer.setTokenPalette(2, Constants.REDS);

        // Transfer one token to user2
        vm.prank(user1);
        charts.transferFrom(user1, user2, 2);

        // Try to elevate after transfer
        vm.startPrank(user1);
        vm.expectRevert(abi.encodeWithSelector(IChartsErrors.NotTokenOwner.selector, user1, 2, user2));
        charts.elevate(1, 2);
        vm.stopPrank();
    }

    function testElevateRevertWithZeroAddress() public {
        // Setup: Mint token to user1
        vm.startPrank(seaDropAddress);
        charts.mintSeaDrop(user1, 1);
        vm.stopPrank();

        // Set basic palette
        renderer.setTokenPalette(1, Constants.REDS);

        // Try to elevate with non-existent token (which would return address(0) as owner)
        vm.startPrank(user1);
        vm.expectRevert(abi.encodeWithSelector(IChartsErrors.NotTokenOwner.selector, user1, 2, address(0)));
        charts.elevate(1, 2);
        vm.stopPrank();
    }

    // 6. Approval-related Tests
    function testElevateRevertWhenTokenApproved() public {
        // Setup: Mint two tokens to user1
        vm.startPrank(seaDropAddress);
        charts.mintSeaDrop(user1, 2);
        vm.stopPrank();

        // Set genesis palettes for both tokens
        renderer.setTokenPalette(1, Constants.REDS);
        renderer.setTokenPalette(2, Constants.REDS);

        // Setup mock OpenSea address
        address mockOpenSea = address(0x123);

        // User1 approves token for sale on OpenSea
        vm.prank(user1);
        charts.approve(mockOpenSea, 1);

        // Try to elevate when one token is approved
        vm.startPrank(user1);
        vm.expectRevert(abi.encodeWithSelector(IChartsErrors.TokenApprovedForTransfer.selector, 1));
        charts.elevate(1, 2);
        vm.stopPrank();

        // Verify tokens weren't elevated
        assertEq(renderer.getTokenPalette(1), Constants.REDS);
        assertEq(renderer.getTokenPalette(2), Constants.REDS);
        assertFalse(renderer.getIsElevatedToken(1));
        assertEq(charts.ownerOf(2), user1); // Ensure token 2 wasn't burned
    }

    function testClearApprovalBeforeElevate() public {
        // Setup: Mint two tokens to user1
        vm.startPrank(seaDropAddress);
        charts.mintSeaDrop(user1, 2);
        vm.stopPrank();

        // Set genesis palettes
        renderer.setTokenPalette(1, Constants.REDS);
        renderer.setTokenPalette(2, Constants.REDS);

        // Setup value generator
        MockValueGenerator valueGen = new MockValueGenerator();
        renderer.setValueGenerator(address(valueGen));
        renderer.setNFTContract(address(charts));

        // Setup mock OpenSea address and approve
        address mockOpenSea = address(0x123);
        vm.prank(user1);
        charts.approve(mockOpenSea, 1);

        // Clear approval
        vm.prank(user1);
        charts.approve(address(0), 1);

        // Now elevation should succeed
        vm.prank(user1);
        charts.elevate(1, 2);

        // Verify elevation succeeded
        assertEq(renderer.getTokenPalette(1), Constants.CHROMATIC);
        assertTrue(renderer.getIsElevatedToken(1));
        vm.expectRevert(); // Should revert when trying to access burned token
        charts.ownerOf(2);
    }
}

