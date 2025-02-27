// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../MetadataImplementation.sol";
import "../libraries/Palettes.sol";
import "../ChartsERC721SeaDrop.sol";
import "../interfaces/IChartsErrors.sol";
import "../MetadataRenderer.sol";
import "../ValueGenerator.sol";
import "forge-std/Test.sol";
import "../libraries/Constants.sol";

contract MaliciousElevator {
    ChartsERC721SeaDrop public charts;
    bool public attackInProgress;

    constructor(address _charts) {
        charts = ChartsERC721SeaDrop(_charts);
    }

    function attack(uint256 tokenId1, uint256 tokenId2) external {
        attackInProgress = true;
        charts.elevate(tokenId1, tokenId2);
        attackInProgress = false;
    }

    // Fallback function to attempt reentrancy
    fallback() external {
        if (attackInProgress) {
            charts.elevate(1, 2); // Attempt to re-enter
        }
    }
}

contract ChartsERC721SeaDropTest is Test {
    ChartsERC721SeaDrop public charts;
    MetadataRenderer public renderer;
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

        address metadataImplementation = address(new MetadataImplementation(address(0xabc), address(0xdef)));
        address valueGenerator = address(new ValueGenerator());

        // Deploy MetadataRenderer with dependencies
        renderer = new MetadataRenderer(address(charts), address(metadataImplementation), address(valueGenerator));

        // Configure ChartsERC721SeaDrop
        charts.setMetadataRenderer(address(renderer));
        charts.setMaxSupply(100);
    }

    function mintTokens(uint256 quantity) public {
        for (uint256 i = 1; i <= quantity; i++) {
            vm.prank(seaDropAddress);
            charts.mintSeaDrop(user1, 1);
        }
    }

    function testSetMetadataRendererRevertZeroAddress() public {
        vm.expectRevert(abi.encodeWithSelector(IChartsErrors.InvalidAddress.selector, address(0)));
        charts.setMetadataRenderer(address(0));
    }

    function testTokenURIRevertNonexistent() public {
        vm.expectRevert();
        charts.tokenURI(1);
    }

    function testMintSeaDrop() public {
        vm.startPrank(seaDropAddress);
        charts.mintSeaDrop(user1, 1);
        assertEq(charts.balanceOf(user1), 1);
        assertEq(charts.ownerOf(1), user1);
        vm.stopPrank();
    }

    function testElevationDisabled() public {
        mintTokens(100);
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(IChartsErrors.ElevationDisabled.selector));
        charts.elevate(17, 18);

        // enable elevation
        vm.prank(owner);
        charts.setElevationStatus(true);

        vm.prank(user1);
        charts.elevate(17, 18);
    }

    function testElevationInvalid() public {
        mintTokens(100);

        // enable elevation
        vm.prank(owner);
        charts.setElevationStatus(true);

        // test elevation of the same token
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(IChartsErrors.ElevationError.selector, 17, 17));
        charts.elevate(17, 17);

        // test elevation of a non-existent token
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(IChartsErrors.TokenDoesNotExist.selector, 1000));
        charts.elevate(17, 1000);

        // test elevation of a non-existent token
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(IChartsErrors.TokenDoesNotExist.selector, 1000));
        charts.elevate(1000, 17);

        // test elevation of a token that is not owned by the user
        vm.prank(user2);
        vm.expectRevert(abi.encodeWithSelector(IChartsErrors.NotTokenOwner.selector, user2, 17, user1));
        charts.elevate(17, 18);

        // transfer the token to user2
        vm.prank(user1);
        charts.transferFrom(user1, user2, 17);

        // test elevation of a token that is not owned by the user
        vm.prank(user2);
        vm.expectRevert(abi.encodeWithSelector(IChartsErrors.NotTokenOwner.selector, user2, 18, user1));
        charts.elevate(17, 18);

        // test elevation of a legendary token
        vm.prank(user1);
        vm.expectRevert();
        charts.elevate(1, 2);

        // test elevation of a non-existent token
        vm.prank(user1);
        vm.expectRevert();
        charts.elevate(0, 0);
    }

    function testElevate() public {
        mintTokens(100);

        // enable elevation
        vm.prank(owner);
        charts.setElevationStatus(true);

        vm.prank(user1);
        charts.elevate(17, 18);

        // make sure the tokenUri for 18 reverts
        vm.expectRevert();
        charts.tokenURI(18);

        // make sure the token palette is valid
        uint8 palette = renderer.tokenPalettes(17);
        bool validPalette = palette == Constants.RGB ||
            palette == Constants.CMY ||
            palette == Constants.WARM ||
            palette == Constants.COOL;
        assertEq(validPalette, true);

        // make sure the token tier is updated
        uint8 tier = MetadataUtils.calculateTierFromPalette(palette);
        assertEq(tier, Constants.RARE_TIER);
    }

    function testReentrancyOnElevate() public {
        mintTokens(100);

        // enable elevation
        vm.prank(owner);
        charts.setElevationStatus(true);

        // Deploy the malicious contract
        MaliciousElevator malicious = new MaliciousElevator(address(charts));

        // Attempt to perform a reentrancy attack
        vm.prank(user1);
        vm.expectRevert(); // Expect the reentrancy to fail
        malicious.attack(17, 18);
    }
}
