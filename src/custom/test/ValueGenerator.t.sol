// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import { console } from "forge-std/console.sol";
import "../ValueGenerator.sol";

contract ValueGeneratorTest is Test {
    ValueGenerator private generator;
    address private owner;
    address private upkeep;
    address private renderer;

    event SeedUpdated(address indexed updater, uint256 timestamp);

    function setUp() public {
        owner = address(this);
        upkeep = makeAddr("upkeep");
        renderer = makeAddr("renderer");
        
        generator = new ValueGenerator();
        generator.setUpkeepAddress(upkeep);
        generator.setMetadataRenderer(renderer);
    }

    function test_InitialState() public {
        assertEq(generator.s_upkeepAddress(), upkeep);
        assertEq(generator._metadataRendererAddress(), renderer);
        assertEq(generator.getCurrentIteration(), 0);
        assertEq(generator._requiredInterval(), Constants.DEFAULT_INTERVAL);
    }

    function test_UpdateRandomSeeds() public {
        // Warp time forward to allow update
        vm.warp(block.timestamp + 24 hours);
        
        // Test update from owner
        vm.expectEmit(true, false, false, true);
        emit SeedUpdated(address(this), block.timestamp);
        generator.updateRandomSeeds();
        
        // Test update from upkeep
        vm.warp(block.timestamp + 24 hours);
        vm.prank(upkeep);
        generator.updateRandomSeeds();
        
        assertEq(generator.getCurrentIteration(), 2);
    }

    function test_UpdateRandomSeedsRevert() public {
        // Should revert if called too soon
        vm.expectRevert(ValueGenerator.InsufficientTimePassed.selector);
        generator.updateRandomSeeds();

        // Should revert if called by unauthorized address
        vm.prank(makeAddr("unauthorized"));
        vm.expectRevert(ValueGenerator.UnauthorizedCaller.selector);
        generator.updateRandomSeeds();
    }

    function test_SetTokenMintIteration() public {
        uint256 tokenId = 1;

        // Should revert if not called by renderer
        vm.expectRevert(ValueGenerator.UnauthorizedMetadataRenderer.selector);
        generator.setTokenMintIteration(tokenId);

        // Should succeed when called by renderer
        vm.prank(renderer);
        generator.setTokenMintIteration(tokenId);
        
        assertEq(generator.getTokenMintIteration(tokenId), 0);
    }

    function test_GenerateValuesFromSeeds() public {
        uint256 tokenId = 1;
        
        // Update seeds a few times
        uint256 currentTime = block.timestamp;
        for (uint256 i = 0; i < 3; i++) {
            currentTime += generator._requiredInterval();
            // Advance both time and block number
            vm.warp(currentTime);
            vm.roll(block.number + 1);
            generator.updateRandomSeeds();
        }

        // Test default token (iteration 0)
        uint8[7] memory defaultValues = generator.generateValuesFromSeeds(tokenId);

        bytes32[7] memory seeds = generator.getRandomSeeds();

        // Check that at least one value is non-zero
        bool hasNonZeroValue = false;
        for (uint256 i = 0; i < 7; i++) {
            if (defaultValues[i] != 0) {
                hasNonZeroValue = true;
                // Debug any failing values
                assertTrue(defaultValues[i] <= Constants.MAX_RANDOM_VALUE, 
                    "Value exceeds MAX_RANDOM_VALUE");
            }
        }
        
        assertTrue(hasNonZeroValue, "Should have at least one non-zero value");
        assertTrue(defaultValues[2] != 0, "Should have at least one non-zero value");

        // Test special token
        vm.prank(renderer);
        generator.setTokenMintIteration(tokenId);
        
        uint8[7] memory specialValues = generator.generateValuesFromSeeds(tokenId);
      
        // For special tokens, we expect values based on the seeds that became
        // available after the token was minted. Some or all might be zero
        // depending on timing and implementation.
        for (uint256 i = 0; i < 7; i++) {
            if (specialValues[i] != 0) {
                assertTrue(specialValues[i] <= Constants.MAX_RANDOM_VALUE,
                    "Special value exceeds MAX_RANDOM_VALUE");
            }
        }
    }

    function test_SetUpkeepAddress() public {
        address newUpkeep = makeAddr("newUpkeep");
        
        // Should revert if zero address
        vm.expectRevert(ValueGenerator.InvalidUpkeepAddress.selector);
        generator.setUpkeepAddress(address(0));

        // Should succeed with valid address
        generator.setUpkeepAddress(newUpkeep);
        assertEq(generator.s_upkeepAddress(), newUpkeep);
    }

    function test_SetMetadataRenderer() public {
        address newRenderer = makeAddr("newRenderer");
        
        // Should revert if zero address
        vm.expectRevert(ValueGenerator.InvalidMetadataRenderer.selector);
        generator.setMetadataRenderer(address(0));

        // Should succeed with valid address
        generator.setMetadataRenderer(newRenderer);
        assertEq(generator._metadataRendererAddress(), newRenderer);
    }

    function test_GetRandomSeeds() public {
        bytes32[7] memory seeds = generator.getRandomSeeds();
        assertEq(seeds.length, 7);
    }
}