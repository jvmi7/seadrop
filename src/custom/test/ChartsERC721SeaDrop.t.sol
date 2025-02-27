// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "../ChartsERC721SeaDrop.sol";

contract ChartsERC721SeaDropTest is Test {
    ChartsERC721SeaDrop private chartsERC721;
    address private owner;
    address private nonOwner = address(0x456);
    address private metadataRenderer = address(0x789);
    address seaDropAddress = address(0x3);

    function setUp() public {
        // New setup code
        owner = address(this);

        address[] memory allowedSeaDrop = new address[](1);
        allowedSeaDrop[0] = seaDropAddress;

        // Updated instantiation of chartsERC721
        chartsERC721 = new ChartsERC721SeaDrop("Charts", "CHRTS", allowedSeaDrop);

        // Existing setup code
        vm.startPrank(owner);
        chartsERC721.setMetadataRenderer(metadataRenderer);
        chartsERC721.setMaxSupply(1000);
        vm.stopPrank();
    }

    // Helper function to set the metadata renderer
    function setMetadataRendererHelper(address renderer) internal {
        vm.startPrank(owner);
        chartsERC721.setMetadataRenderer(renderer);
        vm.stopPrank();
    }

    function testConstructor() public {
        assertEq(chartsERC721.name(), "Charts");
        assertEq(chartsERC721.symbol(), "CHRTS");
    }

    function testSetMetadataRenderer() public {
        setMetadataRendererHelper(metadataRenderer);
        assertEq(address(chartsERC721.metadataRenderer()), metadataRenderer);
    }

    function testSetMetadataRendererRevertsIfNotOwner() public {
        vm.startPrank(nonOwner);
        vm.expectRevert();
        chartsERC721.setMetadataRenderer(metadataRenderer);
        vm.stopPrank();
    }

    function testSetElevationStatus() public {
        vm.startPrank(owner);
        chartsERC721.setElevationStatus(true);
        assertTrue(chartsERC721.isElevationEnabled());
        vm.stopPrank();
    }

    function testSetElevationStatusRevertsIfNotOwner() public {
        vm.startPrank(nonOwner);
        vm.expectRevert();
        chartsERC721.setElevationStatus(true);
        vm.stopPrank();
    }
}
