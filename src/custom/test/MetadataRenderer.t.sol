// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "../MetadataRenderer.sol";
import "../ValueGenerator.sol";
import "../MetadataImplementation.sol";
import "../libraries/Constants.sol";

contract MetadataRendererTest is Test {
    MetadataRenderer metadataRenderer;
    address nftContract = address(0x123);
    address metadataImplementation = address(new MetadataImplementation(address(0xabc), address(0xdef)));
    address valueGenerator = address(new ValueGenerator());

    function setUp() public {
        metadataRenderer = new MetadataRenderer(nftContract, metadataImplementation, valueGenerator);
    }

    function testConstructor() public {
        assertEq(metadataRenderer.nftContract(), nftContract, "NFT contract address mismatch");
        assertEq(
            address(metadataRenderer.metadataImplementation()),
            metadataImplementation,
            "MetadataImplementation address mismatch"
        );
        assertEq(address(metadataRenderer.valueGenerator()), valueGenerator, "ValueGenerator address mismatch");
        assertEq(metadataRenderer.animationUrl(), Constants.ANIMATION_URL, "Animation URL mismatch");
    }

    function test_AccessControl() public {
        // first transfer ownership of the contract to a new address
        vm.prank(metadataRenderer.owner());
        metadataRenderer.transferOwnership(address(0x123));

        // make sure the setters fail if called by a non-owner
        vm.expectRevert("Ownable: caller is not the owner");
        metadataRenderer.setMetadataImplementation(address(0x456));

        // make sure the setters fail if called by a non-owner
        vm.expectRevert("Ownable: caller is not the owner");
        metadataRenderer.setValueGenerator(address(0x456));

        // make sure the setters fail if called by a non-owner
        vm.expectRevert("Ownable: caller is not the owner");
        metadataRenderer.setAnimationUrl("https://www.test.com");

        vm.prank(address(0x123));
        metadataRenderer.transferOwnership(address(this));

        // make sure metadataImplementation can be set when called by the owner
        address temporaryAddress = address(0x456);
        metadataRenderer.setMetadataImplementation(temporaryAddress);
        assertEq(
            address(metadataRenderer.metadataImplementation()),
            temporaryAddress,
            "MetadataImplementation address mismatch"
        );

        // make sure valueGenerator can be set when called by the owner
        temporaryAddress = address(0x789);
        metadataRenderer.setValueGenerator(temporaryAddress);
        assertEq(address(metadataRenderer.valueGenerator()), temporaryAddress, "ValueGenerator address mismatch");

        // make sure animationUrl can be set when called by the owner
        string memory temporaryUrl = "https://www.test.com";
        metadataRenderer.setAnimationUrl(temporaryUrl);
        assertEq(metadataRenderer.animationUrl(), temporaryUrl, "Animation URL mismatch");

        // make sure the initializeTokenMetadata fails if called by a non-nft contract
        vm.expectRevert(MetadataRenderer.OnlyNFTContract.selector);
        metadataRenderer.initializeTokenMetadata(1);

        // make sure the initializeTokenMetadata works if called by the nft contract
        for (uint256 i = 1; i <= Constants.LEGENDARY_CHARTS_COUNT + 2; i++) {
            vm.prank(nftContract);
            metadataRenderer.initializeTokenMetadata(i);
        }

        // make sure the elevate fails if called by a non-nft contract
        vm.expectRevert(MetadataRenderer.OnlyNFTContract.selector);
        metadataRenderer.elevate(1, 2);

        // make sure the elevate works if called by the nft contract
        vm.prank(nftContract);
        metadataRenderer.elevate(17, 18);
    }

    function test_initializeTokenMetadata() public {
        // initialize the token metadata for all legendary charts
        for (uint256 i = 1; i <= Constants.LEGENDARY_CHARTS_COUNT; i++) {
            vm.prank(nftContract);
            metadataRenderer.initializeTokenMetadata(i);
        }
        // make sure the token palettes are set to the correct value
        for (uint256 i = 1; i <= Constants.LEGENDARY_CHARTS_COUNT; i++) {
            assertEq(metadataRenderer.tokenPalettes(i), Constants.LEGENDARY);
        }

        // initialize the token metadata for 100 genesis charts
        for (uint256 i = Constants.LEGENDARY_CHARTS_COUNT + 1; i <= Constants.LEGENDARY_CHARTS_COUNT + 100; i++) {
            vm.prank(nftContract);
            metadataRenderer.initializeTokenMetadata(i);
        }

        // make sure the token palettes are set to the correct value
        for (uint256 i = 1; i <= 100; i++) {
            uint256 tokenId = Constants.LEGENDARY_CHARTS_COUNT + i;
            uint256 expectedPalette = (i % 5 == 1) ? Constants.GREENS : (i % 5 == 2) ? Constants.BLUES : (i % 5 == 3)
                ? Constants.VIOLETS
                : (i % 5 == 4)
                ? Constants.REDS
                : Constants.YELLOWS;
            assertEq(metadataRenderer.tokenPalettes(tokenId), expectedPalette);
        }
    }

    function test_invalidElevate() public {
        // Initialize the token metadata
        for (uint256 i = 1; i <= 100; i++) {
            vm.prank(nftContract);
            metadataRenderer.initializeTokenMetadata(i);
        }

        // Duplicate token ids should not be able to be elevated
        vm.expectRevert();
        vm.prank(nftContract);
        metadataRenderer.elevate(1, 1);

        // Legendary charts should not be able to be elevated
        vm.expectRevert();
        vm.prank(nftContract);
        metadataRenderer.elevate(1, 2);

        // nonexistent token ids should not be able to be elevated
        vm.expectRevert();
        vm.prank(nftContract);
        metadataRenderer.elevate(1, 101);
    }

    function test_elevation() public {
        // Initialize the token metadata
        for (uint256 i = 1; i <= 100; i++) {
            vm.prank(nftContract);
            metadataRenderer.initializeTokenMetadata(i);
        }

        // Save the global seed
        bytes32 globalSeed = metadataRenderer.globalSeed();

        // Elevate the token
        vm.prank(nftContract);
        metadataRenderer.elevate(17, 18);

        // Make sure the token palettes are updated
        uint8 palette = metadataRenderer.tokenPalettes(17);
        uint8 burnPalette = metadataRenderer.tokenPalettes(18);

        bool validElevation = (palette == Constants.RGB ||
            palette == Constants.CMY ||
            palette == Constants.WARM ||
            palette == Constants.COOL);

        assertEq(validElevation, true, "Token palette is not valid for elevation");
        assertEq(burnPalette, 0, "Burn token palette is not 0");

        // Make sure the global seed is updated
        assertTrue(metadataRenderer.globalSeed() != globalSeed, "Global seed was not updated");

        // Make sure the elevated token seed is updated
        assertEq(metadataRenderer.tokenSeeds(17), globalSeed, "Elevated token seed was not updated");

        // Make sure the burn token seed is updated
        assertEq(metadataRenderer.tokenSeeds(18), 0, "Burn token seed was not updated");

        // Make sure the tier is updated
        assertEq(MetadataUtils.calculateTierFromPalette(palette), Constants.ELEVATED_TIER);
    }

    function test_higherTierElevation() public {
        // Initialize the token metadata
        for (uint256 i = 1; i <= 100; i++) {
            vm.prank(nftContract);
            metadataRenderer.initializeTokenMetadata(i);
        }

        // Elevate the token to tier 2
        vm.prank(nftContract);
        metadataRenderer.elevate(17, 18);
        vm.prank(nftContract);
        metadataRenderer.elevate(19, 20);
        vm.prank(nftContract);
        metadataRenderer.elevate(17, 19);

        // Make sure the token palettes are updated
        uint8 palette = metadataRenderer.tokenPalettes(17);

        bool validElevation = (palette == Constants.CHROMATIC || palette == Constants.PASTEL);

        assertEq(validElevation, true, "Token palette is not valid for elevation");
        // Make sure the tier is updated
        assertEq(MetadataUtils.calculateTierFromPalette(palette), Constants.ULTRA_TIER);

        // Elevate the token to tier 3
        vm.prank(nftContract);
        metadataRenderer.elevate(21, 22);
        vm.prank(nftContract);
        metadataRenderer.elevate(23, 24);
        vm.prank(nftContract);
        metadataRenderer.elevate(21, 23);
        vm.prank(nftContract);
        metadataRenderer.elevate(17, 21);

        // Make sure the token palettes are updated
        palette = metadataRenderer.tokenPalettes(17);
        assertEq(palette, Constants.GREYSCALE, "Token palette is not valid for elevation");
        // Make sure the tier is updated
        assertEq(MetadataUtils.calculateTierFromPalette(palette), Constants.ELITE_TIER);
    }
}
