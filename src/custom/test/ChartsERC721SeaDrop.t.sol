// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "../ChartsERC721SeaDrop.sol";
import "../interfaces/IMetadataRenderer.sol";
import "../interfaces/IValueGenerator.sol";
import "../libraries/Palettes.sol";

// Mock MetadataRenderer contract for testing
contract MockMetadataRenderer is IMetadataRenderer {
    mapping(uint256 => uint8) public tokenPalettes;
    mapping(uint256 => bool) public elevatedTokens;
    address public nftContractAddress;
    IValueGenerator public valueGen;

    function generateTokenURI(uint256) external pure returns (string memory) {
        return "test-uri";
    }

    function setInitialMetadata(uint256 tokenId) external {
        tokenPalettes[tokenId] = 0;
    }


    function setElevatedToken(uint256 tokenId, uint8 palette, bytes32 seed) external {
        elevatedTokens[tokenId] = true;
        tokenPalettes[tokenId] = palette;
        valueGen.setTokenValuesSeed(tokenId, seed);
    }

    function getTokenPalette(uint256 tokenId) external view returns (uint8) {
        return tokenPalettes[tokenId];
    }

    function getIsElevatedToken(uint256 tokenId) external view returns (bool) {
        return elevatedTokens[tokenId];
    }

    // Required interface implementations
    function nftContract() external view returns (address) {
        return nftContractAddress;
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

    function setValueGenerator(IValueGenerator _valueGen) external {
        valueGen = _valueGen;
    }
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

    function testMintSeaDrop() public {
        vm.startPrank(seaDropAddress);
        charts.mintSeaDrop(user1, 1);
        assertEq(charts.balanceOf(user1), 1);
        assertEq(charts.ownerOf(1), user1);
        vm.stopPrank();
    }

    function testConvertTokensChromatic() public {
        // Mint 4 tokens
        vm.startPrank(seaDropAddress);
        charts.mintSeaDrop(user1, 4);
        vm.stopPrank();

        // Set different palettes for the tokens
        renderer.setTokenPalette(1, 0);
        renderer.setTokenPalette(2, 1);
        renderer.setTokenPalette(3, 2);
        renderer.setTokenPalette(4, 3);

        uint256[] memory tokenIds = new uint256[](4);
        tokenIds[0] = 1;
        tokenIds[1] = 2;
        tokenIds[2] = 3;
        tokenIds[3] = 4;

        vm.prank(user1);
        vm.expectEmit(true, true, true, true);
        emit TokensElevated(tokenIds[0], tokenIds[1]);
        charts.elevate(tokenIds[0], tokenIds[1]);

        // Verify conversion
        assertTrue(renderer.getIsElevatedToken(5));
        assertEq(renderer.getTokenPalette(5), Constants.CHROMATIC);
    }

    function testConvertTokensPastel() public {
        // Mint 4 tokens of the same palette for Pastel conversion
        vm.startPrank(seaDropAddress);
        charts.mintSeaDrop(user1, 3);
        vm.stopPrank();

        // Set all tokens to palette 0
        for (uint256 i = 1; i <= 3; i++) {
            renderer.setTokenPalette(i, Constants.CHROMATIC);
        }

        uint256[] memory tokenIds = new uint256[](3);
        for (uint256 i = 0; i < 3; i++) {
            tokenIds[i] = i + 1;
        }

        vm.prank(user1);
        vm.expectEmit(true, true, true, true);
        emit TokensElevated(tokenIds[0], tokenIds[1]);
        charts.elevate(tokenIds[0], tokenIds[1]);

        assertTrue(renderer.getIsElevatedToken(4));
        assertEq(renderer.getTokenPalette(4), Constants.PASTEL);
    }

    function testConvertTokensGreyscale() public {
        // Mint 4 tokens of the same palette for Greyscale conversion
        vm.startPrank(seaDropAddress);
        charts.mintSeaDrop(user1, 2);
        vm.stopPrank();

        // Set all tokens to palette 1
        for (uint256 i = 1; i <= 2; i++) {
            renderer.setTokenPalette(i, Constants.PASTEL);
        }

        uint256[] memory tokenIds = new uint256[](2);
        for (uint256 i = 0; i < 2; i++) {
            tokenIds[i] = i + 1;
        }

        vm.prank(user1);
        vm.expectEmit(true, true, true, true);
        emit TokensElevated(tokenIds[0], tokenIds[1]);
        charts.elevate(tokenIds[0], tokenIds[1]);

        assertTrue(renderer.getIsElevatedToken(3));
        assertEq(renderer.getTokenPalette(3), Constants.GREYSCALE);
    }

    function testConvertTokensRevertInvalidInput() public {
        uint256[] memory tokenIds = new uint256[](0);
        vm.expectRevert(abi.encodeWithSelector(IChartsErrors.InvalidTokenInput.selector, tokenIds));
        charts.elevate(tokenIds[0], tokenIds[1]);

        tokenIds = new uint256[](5);
        vm.expectRevert(abi.encodeWithSelector(IChartsErrors.InvalidTokenInput.selector, tokenIds));
        charts.elevate(tokenIds[0], tokenIds[1]);
    }

    function testConvertTokensRevertWrongPalette() public {
        vm.prank(seaDropAddress);
        charts.mintSeaDrop(user1, 4);

        // Set different palettes
        renderer.setTokenPalette(1, Constants.GREENS);
        renderer.setTokenPalette(2, Constants.BLUES);
        renderer.setTokenPalette(3, Constants.VIOLETS);
        renderer.setTokenPalette(4, Constants.YELLOWS);

        uint256[] memory tokenIds = new uint256[](4);
        for (uint256 i = 0; i < 4; i++) {
            tokenIds[i] = i + 1;
        }

        vm.prank(user1);
        vm.expectRevert();
        charts.elevate(tokenIds[0], tokenIds[1]);
    }

    function testTokenURI() public {
        vm.prank(seaDropAddress);
        charts.mintSeaDrop(user1, 1);

        assertEq(charts.tokenURI(1), "test-uri");
    }

    function testTokenURIRevertNonexistent() public {
        vm.expectRevert();
        charts.tokenURI(1);
    }
}