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
    event GenesisTokenSeedsUpdated(address indexed updater, bytes32 indexed seed, uint256 timestamp);

    function setUp() public {
        owner = address(this);
        upkeep = makeAddr("upkeep");

        generator = new ValueGenerator();
        generator.setUpkeepAddress(upkeep);
    }

    // 1. Basic Initialization and Configuration Tests
    function test_InitialState() public {
        assertEq(generator.s_upkeepAddress(), upkeep);
    }

    function test_ConstructorInitialization() public {
        // Deploy a new instance of the contract
        ValueGenerator newGenerator = new ValueGenerator();

        // Check that lastUpdateBlock is set to the current block timestamp
        assertEq(newGenerator.lastUpdateBlock(), block.timestamp);
    }

    // 2. Access Control and Administration Tests
    function test_AccessControl() public {
        address newOwner = makeAddr("newOwner");
        address unauthorized = makeAddr("unauthorized");
        address newUpkeep = makeAddr("newUpkeep");

        // Transfer ownership
        generator.transferOwnership(newOwner);
        assertEq(generator.owner(), newOwner);

        // Old owner should no longer be able to call restricted functions
        vm.expectRevert("Ownable: caller is not the owner");
        generator.setUpkeepAddress(newUpkeep);

        // New owner should be able to call restricted functions
        vm.prank(newOwner);
        generator.setUpkeepAddress(newUpkeep);
        assertEq(generator.s_upkeepAddress(), newUpkeep);

        // Ensure updateGenesisTokenSeeds can only be called by upkeep or owner
        vm.prank(newOwner);
        generator.updateGenesisTokenSeeds();

        vm.prank(newUpkeep);
        generator.updateGenesisTokenSeeds();

        // Should revert if called by unauthorized address
        vm.prank(unauthorized);
        vm.expectRevert(ValueGenerator.UnauthorizedCaller.selector);
        generator.updateGenesisTokenSeeds();

        // Test setting upkeep address by unauthorized address
        vm.prank(unauthorized);
        vm.expectRevert("Ownable: caller is not the owner");
        generator.setUpkeepAddress(newUpkeep);

        // Test setting upkeep address by new owner
        vm.prank(newOwner);
        generator.setUpkeepAddress(newUpkeep);
        assertEq(generator.s_upkeepAddress(), newUpkeep);

        // Test setting upkeep address by upkeep address (should fail)
        vm.prank(newUpkeep);
        vm.expectRevert("Ownable: caller is not the owner");
        generator.setUpkeepAddress(address(2));

        // Test setting zero address
        vm.prank(newOwner);
        vm.expectRevert(ValueGenerator.InvalidUpkeepAddress.selector);
        generator.setUpkeepAddress(address(0));
    }

    // 3. Genesis Token Seeds Tests
    function test_updateGenesisTokenSeeds() public {
        // Test update from owner
        vm.expectEmit(true, false, false, true);
        emit GenesisTokenSeedsUpdated(address(this), bytes32(0), block.timestamp);
        generator.updateGenesisTokenSeeds();

        // Test update from upkeep
        vm.prank(upkeep);
        generator.updateGenesisTokenSeeds();
    }

    function test_getGenesisTokenSeeds() public {
        bytes32[7] memory seeds;
        for (uint256 i = 0; i < seeds.length; i++) {
            seeds[i] = generator.genesisTokenSeeds(i);
        }
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

    // 4. Value Generation Tests
    function test_generateValuesFromSeeds() public {
        bytes32 tokenSeed = keccak256(abi.encodePacked("testSeed"));
        uint8[7] memory values = generator.generateValuesFromSeeds(1, tokenSeed);

        for (uint256 i = 0; i < values.length; i++) {
            assert(values[i] == 0);
        }

        // Test with a non-zero token seed
        generator.updateGenesisTokenSeeds();
        values = generator.generateValuesFromSeeds(1, tokenSeed);

        // First value should be non-zero, second should be zero
        assert(values[0] != 0);
        assert(values[1] == 0);
    }

    // 6. Edge Case Tests
    function test_PartiallyFilledGenesisTokenSeeds() public {
        // Fill part of the array
        for (uint256 i = 0; i < 3; i++) {
            generator.updateGenesisTokenSeeds();
        }

        // Check that the array is partially filled
        for (uint256 i = 0; i < 3; i++) {
            assert(generator.genesisTokenSeeds(i) != 0);
        }
        for (uint256 i = 3; i < 7; i++) {
            assert(generator.genesisTokenSeeds(i) == 0);
        }
    }
}
