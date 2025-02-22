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
    event GenesisTokenSeedsUpdated(address indexed updater, uint256 timestamp);
    event ElevatedTokenSeedUpdated(address indexed updater, uint256 timestamp);

    function setUp() public {
        owner = address(this);
        upkeep = makeAddr("upkeep");
        renderer = makeAddr("renderer");
        
        generator = new ValueGenerator();
        generator.setUpkeepAddress(upkeep);
        generator.setMetadataRenderer(renderer);
    }

    // 1. Basic Initialization and Configuration Tests
    function test_InitialState() public {
        assertEq(generator.s_upkeepAddress(), upkeep);
        assertEq(generator._metadataRendererAddress(), renderer);
    }

    // 2. Access Control and Administration Tests
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

    function test_ZeroAddressChecks() public {
        vm.expectRevert(ValueGenerator.InvalidUpkeepAddress.selector);
        generator.setUpkeepAddress(address(0));
        
        vm.expectRevert(ValueGenerator.InvalidMetadataRenderer.selector);
        generator.setMetadataRenderer(address(0));
    }

    // 3. Genesis Token Seeds Tests
    function test_updateGenesisTokenSeeds() public {
        // Test update from owner
        vm.expectEmit(true, false, false, true);
        emit GenesisTokenSeedsUpdated(address(this), block.timestamp);
        generator.updateGenesisTokenSeeds();
        
        // Test update from upkeep
        vm.prank(upkeep);
        generator.updateGenesisTokenSeeds();
    }

    function test_updateGenesisTokenSeedsRevert() public {
        // Should revert if called by unauthorized address
        vm.prank(makeAddr("unauthorized"));
        vm.expectRevert(ValueGenerator.UnauthorizedCaller.selector);
        generator.updateGenesisTokenSeeds();
    }

    function test_getGenesisTokenSeeds() public {
        bytes32[7] memory seeds = generator.getGenesisTokenSeeds();
        assertEq(seeds.length, 7);
    }

    function test_GenesisTokenSeedsArrayFull() public {
        // Fill up the array
        for (uint256 i = 0; i < 7; i++) {
            generator.updateGenesisTokenSeeds();
        }
        
        // Should revert when trying to add more seeds
        vm.expectRevert(ValueGenerator.GenesisTokenSeedsArrayFull.selector);
        generator.updateGenesisTokenSeeds();
    }

    // 4. Elevated Token Seed Tests
    function test_updateElevatedTokenSeed() public {
        // Test update from owner
        vm.expectEmit(true, false, false, true);
        emit ElevatedTokenSeedUpdated(address(this), block.timestamp);
        generator.updateElevatedTokenSeed();
        
        // Test update from upkeep
        vm.prank(upkeep);
        generator.updateElevatedTokenSeed();
    }

    function test_updateElevatedTokenSeedRevert() public {
        // Should revert if called by unauthorized address
        vm.prank(makeAddr("unauthorized"));
        vm.expectRevert(ValueGenerator.UnauthorizedCaller.selector);
        generator.updateElevatedTokenSeed();
    }

    function test_updateStateOnElevate() public {
        uint256 tokenId = 1;
        bytes32 seed = bytes32(uint256(1));
        
        // Should revert if not called by metadata renderer
        vm.prank(makeAddr("unauthorized"));
        vm.expectRevert(ValueGenerator.UnauthorizedMetadataRenderer.selector);
        generator.updateStateOnElevate(tokenId, seed);
        
        // Should succeed when called by metadata renderer
        vm.prank(renderer);
        generator.updateStateOnElevate(tokenId, seed);
        
        // Verify seed was stored (through getter)
        assertEq(generator.getTokenValuesSeed(tokenId), keccak256(abi.encodePacked(seed, generator.getElevatedTokenSeed())));
    }

    // 5. Basic Value Generation Tests
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
        vm.roll(block.number + 1);
        generator.updateGenesisTokenSeeds();
        
        uint8[7] memory values = generator.generateValuesFromSeeds(tokenId);
        
        // First value should be non-zero, rest should be zero
        assertTrue(values[0] > 0);
        for (uint256 i = 1; i < 7; i++) {
            assertEq(values[i], 0);
        }
    }

    function test_GenerateValuesFromSeeds() public {
        uint256 tokenId = 1;
        
        // Update seeds a few times
        uint256 currentTime = block.timestamp;
        for (uint256 i = 0; i < 3; i++) {
            // Advance both time and block number
            vm.warp(currentTime);
            vm.roll(block.number + 1);
            generator.updateGenesisTokenSeeds();
        }

        // Test default token (iteration 0)
        uint8[7] memory defaultValues = generator.generateValuesFromSeeds(tokenId);

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
    }

    // 6. Advanced Value Generation Tests
    function test_GenerateValuesForMultipleTokens() public {
        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = 1;
        tokenIds[1] = 2;
        tokenIds[2] = 3;
        
        // Update seeds
        vm.roll(block.number + 1);
        generator.updateGenesisTokenSeeds();
        
        // Generate values for different tokens
        uint8[7] memory values1 = generator.generateValuesFromSeeds(tokenIds[0]);
        uint8[7] memory values2 = generator.generateValuesFromSeeds(tokenIds[1]);
        uint8[7] memory values3 = generator.generateValuesFromSeeds(tokenIds[2]);
        
        // Values should be different for different tokens
        assertTrue(values1[0] != values2[0] || values2[0] != values3[0]);
    }

    function test_TokenValueConsistency() public {
        uint256 tokenId = 1;
        
        // Update seeds
        vm.roll(block.number + 1);
        generator.updateGenesisTokenSeeds();
        
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
            vm.roll(block.number + 1);
            generator.updateGenesisTokenSeeds();
        }
        
        uint8[7] memory values = generator.generateValuesFromSeeds(tokenId);
        
        // All values should be within bounds
        for (uint256 i = 0; i < 7; i++) {
            assertTrue(values[i] <= Constants.MAX_RANDOM_VALUE);
            assertTrue(values[i] > 0);
        }
    }

 
    // 7. Helper Function Tests
    function test_fastForwardReveal() public {
        generator.fastForwardReveal();
        
        bytes32[7] memory seeds = generator.getGenesisTokenSeeds();
        for (uint256 i = 0; i < 7; i++) {
            assertTrue(seeds[i] != bytes32(0));
        }
        
        // Generate values for a token after fast forward
        uint256 tokenId = 1;
        uint8[7] memory values = generator.generateValuesFromSeeds(tokenId);
        
        // All values should be non-zero after fast forward
        for (uint256 i = 0; i < 7; i++) {
            assertTrue(values[i] > 0);
            assertTrue(values[i] <= Constants.MAX_RANDOM_VALUE);
        }
    }
}