// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "../MetadataImplementation.sol";

contract MetadataImplementationTest is Test {
    MetadataImplementation metadataImplementation;
    address owner = address(0x123);
    address newMetadataBadges = address(0x456);
    address newMetadataPatterns = address(0x789);

    function setUp() public {
        // Deploy the MetadataImplementation contract with initial addresses
        metadataImplementation = new MetadataImplementation(address(0xabc), address(0xdef));
        metadataImplementation.transferOwnership(owner);
    }

    function testSetMetadataBadges() public {
        // Ensure only the owner can set the metadata badges address
        vm.prank(owner);
        metadataImplementation.setMetadataBadges(newMetadataBadges);

        // Verify the address was updated
        assertEq(metadataImplementation.metadataBadges(), newMetadataBadges);
    }

    function testSetMetadataPatterns() public {
        // Ensure only the owner can set the metadata patterns address
        vm.prank(owner);
        metadataImplementation.setMetadataPatterns(newMetadataPatterns);

        // Verify the address was updated
        assertEq(metadataImplementation.metadataPatterns(), newMetadataPatterns);
    }

    function testSetMetadataBadgesNotOwner() public {
        // Attempt to set the metadata badges address from a non-owner account
        vm.expectRevert("Ownable: caller is not the owner");
        metadataImplementation.setMetadataBadges(newMetadataBadges);
    }

    function testSetMetadataPatternsNotOwner() public {
        // Attempt to set the metadata patterns address from a non-owner account
        vm.expectRevert("Ownable: caller is not the owner");
        metadataImplementation.setMetadataPatterns(newMetadataPatterns);
    }
}
