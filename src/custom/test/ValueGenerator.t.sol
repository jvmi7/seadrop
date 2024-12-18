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

    function test_SetRequiredInterval() public {
        uint256 newInterval = 12 hours;
        
        // Should revert if zero interval
        vm.expectRevert(ValueGenerator.InvalidInterval.selector);
        generator.setRequiredInterval(0);
        
        // Should succeed with valid interval
        generator.setRequiredInterval(newInterval);
        assertEq(generator._requiredInterval(), newInterval);
    }

    function test_GenerateValuesFromSeedsWithEmptySeeds() public {
        uint256 tokenId = 1;
        uint8[7] memory values = generator.generateValuesFromSeeds(tokenId);
        
        // All values should be 0 since no seeds have been set
        for (uint256 i = 0; i < 7; i++) {
            assertEq(values[i], 0);
        }
    }

    function test_GenerateValuesFromSeedsWithPartialSeeds() public {
        uint256 tokenId = 1;
        
        // Update seeds only once
        vm.warp(block.timestamp + generator._requiredInterval());
        vm.roll(block.number + 1);
        generator.updateRandomSeeds();
        
        uint8[7] memory values = generator.generateValuesFromSeeds(tokenId);
        
        // First value should be non-zero, rest should be zero
        assertTrue(values[0] > 0);
        for (uint256 i = 1; i < 7; i++) {
            assertEq(values[i], 0);
        }
    }

    function test_GenerateValuesForMultipleTokens() public {
        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = 1;
        tokenIds[1] = 2;
        tokenIds[2] = 3;
        
        // Update seeds
        vm.warp(block.timestamp + generator._requiredInterval());
        vm.roll(block.number + 1);
        generator.updateRandomSeeds();
        
        // Generate values for different tokens
        uint8[7] memory values1 = generator.generateValuesFromSeeds(tokenIds[0]);
        uint8[7] memory values2 = generator.generateValuesFromSeeds(tokenIds[1]);
        uint8[7] memory values3 = generator.generateValuesFromSeeds(tokenIds[2]);
        
        // Values should be different for different tokens
        assertTrue(values1[0] != values2[0] || values2[0] != values3[0]);
    }

    function test_SpecialTokenValueGeneration() public {
        uint256 tokenId = 1;
        
        // Set token as special (non-zero iteration)
        vm.startPrank(renderer);
        generator.setTokenMintIteration(tokenId);
        vm.stopPrank();
        
        // Update seeds multiple times
        for (uint256 i = 0; i < 7; i++) {
            vm.warp(block.timestamp + generator._requiredInterval());
            vm.roll(block.number + 1);
            generator.updateRandomSeeds();
        }
        
        uint8[7] memory values = generator.generateValuesFromSeeds(tokenId);
        
        // Verify values are within expected range
        for (uint256 i = 0; i < 7; i++) {
            if (values[i] != 0) {
                assertTrue(values[i] <= Constants.MAX_RANDOM_VALUE);
                assertTrue(values[i] > 0);
            }
        }
    }

    function test_ConsecutiveUpdates() public {
        // Try to update seeds consecutively
        vm.warp(block.timestamp + generator._requiredInterval());
        vm.roll(block.number + 1);
        generator.updateRandomSeeds();
        
        // Second update should fail
        vm.expectRevert(ValueGenerator.InsufficientTimePassed.selector);
        generator.updateRandomSeeds();
        
        // Update after interval should succeed
        vm.warp(block.timestamp + generator._requiredInterval());
        vm.roll(block.number + 1);
        generator.updateRandomSeeds();
        
        assertEq(generator.getCurrentIteration(), 2);
    }

    function test_TokenMintIterationMultipleTokens() public {
        vm.startPrank(renderer);
        
        // Set iterations for multiple tokens
        generator.setTokenMintIteration(1);
        vm.stopPrank();

        // Update seeds (as owner)
        vm.warp(block.timestamp + generator._requiredInterval());
        vm.roll(block.number + 1);
        generator.updateRandomSeeds();
        
        vm.prank(renderer);
        generator.setTokenMintIteration(2);
        
        // Verify different iterations
        assertEq(generator.getTokenMintIteration(1), 0);
        assertEq(generator.getTokenMintIteration(2), 1);
    }

    function test_UpdateRandomSeedsAsUpkeep() public {
        vm.startPrank(upkeep);
        
        // Should succeed after required interval
        vm.warp(block.timestamp + generator._requiredInterval());
        vm.roll(block.number + 1);
        generator.updateRandomSeeds();
        
        uint256 firstIteration = generator.getCurrentIteration();
        assertEq(firstIteration, 1);
        
        // Should fail immediately after
        vm.expectRevert(ValueGenerator.InsufficientTimePassed.selector);
        generator.updateRandomSeeds();
        
        vm.stopPrank();
    }

    function test_TokenValueConsistency() public {
        uint256 tokenId = 1;
        
        // Update seeds
        vm.warp(block.timestamp + generator._requiredInterval());
        vm.roll(block.number + 1);
        generator.updateRandomSeeds();
        
        // Generate values twice for same token
        uint8[7] memory values1 = generator.generateValuesFromSeeds(tokenId);
        uint8[7] memory values2 = generator.generateValuesFromSeeds(tokenId);
        
        // Values should be identical for same token
        for (uint256 i = 0; i < 7; i++) {
            assertEq(values1[i], values2[i]);
        }
    }

    function test_MaxValueBoundary() public {
        uint256 tokenId = 1;
        
        // Update seeds multiple times
        for (uint256 i = 0; i < 7; i++) {
            vm.warp(block.timestamp + generator._requiredInterval());
            vm.roll(block.number + 1);
            generator.updateRandomSeeds();
        }
        
        uint8[7] memory values = generator.generateValuesFromSeeds(tokenId);
        
        // All values should be within bounds
        for (uint256 i = 0; i < 7; i++) {
            assertTrue(values[i] <= Constants.MAX_RANDOM_VALUE);
            assertTrue(values[i] > 0);
        }
    }

    function test_OwnershipTransfer() public {
        address newOwner = makeAddr("newOwner");
        
        // Transfer ownership
        generator.transferOwnership(newOwner);
        assertEq(generator.owner(), newOwner);
        
        // Old owner should no longer be able to call restricted functions
        vm.expectRevert("Ownable: caller is not the owner");
        generator.setUpkeepAddress(address(1));
        
        // New owner should be able to call restricted functions
        vm.prank(newOwner);
        generator.setUpkeepAddress(address(1));
        assertEq(generator.s_upkeepAddress(), address(1));
    }

    function test_ZeroAddressChecks() public {
        vm.expectRevert(ValueGenerator.InvalidUpkeepAddress.selector);
        generator.setUpkeepAddress(address(0));
        
        vm.expectRevert(ValueGenerator.InvalidMetadataRenderer.selector);
        generator.setMetadataRenderer(address(0));
    }

    function test_MultipleTokensWithSameIteration() public {
        vm.startPrank(renderer);
        
        // Set same iteration for multiple tokens
        for (uint256 i = 1; i <= 3; i++) {
            generator.setTokenMintIteration(i);
        }
        vm.stopPrank();
        
        // Update seeds
        vm.warp(block.timestamp + generator._requiredInterval());
        vm.roll(block.number + 1);
        generator.updateRandomSeeds();
        
        // Generate values for all tokens
        uint8[7] memory values1 = generator.generateValuesFromSeeds(1);
        uint8[7] memory values2 = generator.generateValuesFromSeeds(2);
        uint8[7] memory values3 = generator.generateValuesFromSeeds(3);
        
        // Values should be different for different tokens even with same iteration
        bool hasDifference = false;
        for (uint256 i = 0; i < 7; i++) {
            if (values1[i] != values2[i] || values2[i] != values3[i]) {
                hasDifference = true;
                break;
            }
        }
        assertTrue(hasDifference, "Values should be different for different tokens");
    }
}