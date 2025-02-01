// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "../libraries/MetadataUtils.sol";
import "../types/MetadataTypes.sol";
import "./StringAssertions.sol";

contract MetadataUtilsTest is Test, StringAssertions {
    using MetadataUtils for TokenMetadata;

    function setUp() public {
        // No setup needed for library tests
    }

    function test_GenerateTokenURI() public {
        // Arrange
        uint8[7] memory values = [1, 2, 3, 4, 5, 6, 7];
        TokenMetadata memory metadata = TokenMetadata({
            id: 1,
            values: values,
            palette: 0
        });

        // Act
        string memory uri = MetadataUtils.generateTokenURI(metadata);

        // Assert
        assertTrue(bytes(uri).length > 0);
        assertStringStartsWith(uri, "data:application/json;base64,");
    }

    function test_GenerateName() public {
        // Test multiple token IDs to ensure deterministic naming
        string memory name1 = MetadataUtils.generateName(1);
        string memory name2 = MetadataUtils.generateName(1);
        string memory name3 = MetadataUtils.generateName(2);

        // Assert format and deterministic behavior
        assertEq(bytes(name1).length, 8); // $XXX-XXX format
        assertTrue(bytes(name1)[0] == "$");
        assertTrue(bytes(name1)[4] == "-");
        assertEq(name1, name2); // Same ID should produce same name
        assertTrue(keccak256(bytes(name1)) != keccak256(bytes(name3))); // Different IDs should produce different names
    }

    function test_GenerateValueString() public {
        // Test with different value arrays
        uint8[7] memory values1 = [1, 2, 3, 4, 5, 6, 7];
        string memory result1 = MetadataUtils.generateValueString(values1);
        assertEq(result1, "1,2,3,4,5,6,7");

        uint8[7] memory values2 = [0, 0, 0, 0, 0, 0, 0];
        string memory result2 = MetadataUtils.generateValueString(values2);
        assertEq(result2, "0,0,0,0,0,0,0");
    }

    function test_GenerateBasicProperties() public {
        // Arrange
        uint8[7] memory values = [1, 2, 3, 4, 5, 6, 7];
        TokenMetadata memory metadata = TokenMetadata({
            id: 1,
            values: values,
            palette: 0
        });

        // Act
        string memory properties = MetadataUtils.generateBasicProperties(metadata);

        // Assert
        assertTrue(bytes(properties).length > 0);
        assertStringContains(properties, '"name"');
        assertStringContains(properties, '"description"');
        assertStringContains(properties, '"image"');
        assertStringContains(properties, '"values"');
    }

    function test_GenerateAttributesSection() public {
        // Arrange
        uint8[7] memory values = [1, 2, 3, 4, 5, 6, 7];
        TokenMetadata memory metadata = TokenMetadata({
            id: 1,
            values: values,
            palette: 0
        });

        // Act
        string memory attributes = MetadataUtils.generateAttributesSection(metadata);

        // Assert
        assertTrue(bytes(attributes).length > 0);
        assertStringContains(attributes, '"trait_type"');
    }

    function test_GenerateImageURI() public {
        // Arrange
        uint8[7] memory values = [1, 2, 3, 4, 5, 6, 7];
        uint8 palette = 0;

        // Act
        string memory imageUri = MetadataUtils.generateImageURI(values, palette);

        // Assert
        assertTrue(bytes(imageUri).length > 0);
        assertStringStartsWith(imageUri, "data:image/svg+xml;base64,");
    }

    // Fuzz tests
    function testFuzz_GenerateName(uint256 tokenId) public {
        string memory name = MetadataUtils.generateName(tokenId);
        assertEq(bytes(name).length, 8);
        assertTrue(bytes(name)[0] == "$");
        assertTrue(bytes(name)[4] == "-");
    }

    function testFuzz_GenerateValueString(uint8[7] memory values) public {
        string memory result = MetadataUtils.generateValueString(values);
        assertTrue(bytes(result).length > 0);
    }
}