// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Base64 } from "openzeppelin-contracts/utils/Base64.sol";
import { Strings } from "openzeppelin-contracts/utils/Strings.sol";
import { SVGGenerator } from "./SVGGenerator.sol";
import { TokenMetadata } from "./SeaDropTypes.sol";

contract MetadataRenderer {
    using Strings for uint256;

    bytes32[7] private _randomSeeds;
    uint256 private _lastUpdateBlock;
    uint256 private constant DAY_IN_SECONDS = 1;

    mapping(uint256 => uint8) private _tokenPalettes;
    mapping(uint256 => bool) private _tokenLocked;
    mapping(uint256 => uint8[7]) private _lockedValues;

    address public immutable nftContract;

    event MetadataUpdated(uint256 indexed tokenId);
    event TokenLocked(uint256 indexed tokenId);
    event TokenUnlocked(uint256 indexed tokenId);

    constructor(address _nftContract) {
        nftContract = _nftContract;
        _lastUpdateBlock = block.timestamp;
    }

    modifier onlyNFTContract() {
        require(msg.sender == nftContract, "Only NFT contract");
        _;
    }

    function setInitialMetadata(uint256 tokenId) external onlyNFTContract {
        uint8 palette;
        uint256 mod16 = tokenId % 16;
        
        if (mod16 < 8) palette = 0;
        else if (mod16 < 12) palette = 1;
        else if (mod16 < 14) palette = 2;
        else if (mod16 < 15) palette = 3;

        _tokenPalettes[tokenId] = palette;
    }

    function updateDailySeeds() external {
        require(block.timestamp >= _lastUpdateBlock + DAY_IN_SECONDS, "Too early to update");
        
        // Get new random hash
        require(block.number > 0, "No previous blocks");
        bytes32 previousBlockHash = blockhash(block.number - 1);
        require(previousBlockHash != bytes32(0), "Block hash not available");
        
        // Try to find first zero seed
        for (uint256 i = 0; i < 7; i++) {
            if (_randomSeeds[i] == 0) {
                _randomSeeds[i] = previousBlockHash;
                _lastUpdateBlock = block.timestamp;
                return;
            }
        }
        
        // If array is full, shift left and add new hash at end
        for (uint256 i = 0; i < 6; i++) {
            _randomSeeds[i] = _randomSeeds[i + 1];
        }
        _randomSeeds[6] = previousBlockHash;
        _lastUpdateBlock = block.timestamp;
    }

// For testing purposes only
    function fastForwardDays() external {
        _randomSeeds[0] = 0x0000000000000000000000000000000000000000000000000000000000000001;
        _randomSeeds[1] = 0x0000000000000000000000000000000000000000000000000000000000000002;
        _randomSeeds[2] = 0x0000000000000000000000000000000000000000000000000000000000000003;
        _randomSeeds[3] = 0x0000000000000000000000000000000000000000000000000000000000000004;
        _randomSeeds[4] = 0x0000000000000000000000000000000000000000000000000000000000000005;
        _randomSeeds[5] = 0x0000000000000000000000000000000000000000000000000000000000000006;
        _randomSeeds[6] = 0x0000000000000000000000000000000000000000000000000000000000000007;
        
        _lastUpdateBlock = block.timestamp;
    }

    function generateTokenURI(uint256 tokenId) 
        external 
        view 
        returns (string memory) 
    {        
        uint8[7] memory values = generateValuesFromSeeds(tokenId);
        TokenMetadata memory metadata = TokenMetadata({
            name: "Untitled",
            description: "A new NFT",
            image: "",
            animationUrl: "",
            values: values,
            palette: _tokenPalettes[tokenId]
        });
        
        return _generateFullTokenURI(tokenId, metadata);
    }

    function generateValuesFromSeeds(uint256 tokenId) 
        public 
        view 
        returns (uint8[7] memory) 
    {
        if (_tokenLocked[tokenId]) {
            return _lockedValues[tokenId];
        }

        uint8[7] memory values = [0, 0, 0, 0, 0, 0, 0];

        for (uint256 i = 0; i < 7; i++) {
            if (_randomSeeds[i] != 0) {
                bytes32 combinedSeed = keccak256(abi.encodePacked(_randomSeeds[i], tokenId));
                uint256 randomValue = (uint256(combinedSeed) % 100) + 1;
                values[i] = uint8(randomValue);
            }
        }
        return values;
    }

    function getRandomSeeds() external view returns (bytes32[7] memory) {
        return _randomSeeds;
    }

    function _generateFullTokenURI(uint256 tokenId, TokenMetadata memory metadata)
        internal
        view
        returns (string memory)
    {
        string memory imageUri = _generateImageURI(metadata.values, metadata.palette);
        string memory jsonData = _generateJsonData(tokenId, metadata, imageUri);
        
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(bytes(jsonData))
            )
        );
    }

    function _generateImageURI(uint8[7] memory values, uint8 palette)
        internal
        pure
        returns (string memory)
    {
        string memory svgBase64 = SVGGenerator.generateSVG(values, palette);
        return string(
            abi.encodePacked('data:image/svg+xml;base64,', svgBase64)
        );
    }

    function _generateJsonData(
        uint256 tokenId,
        TokenMetadata memory metadata,
        string memory imageUri
    ) internal view returns (string memory) {
        return string(
            abi.encodePacked(
                '{',
                _generateBasicFields(tokenId, metadata, imageUri),
                _generateAttributesSection(metadata.values, metadata.palette, _tokenLocked[tokenId]),
                '}'
            )
        );
    }

    function _generateBasicFields(
        uint256 tokenId,
        TokenMetadata memory metadata,
        string memory imageUri
    ) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                '"name": "#', tokenId.toString(), '",',
                '"description": "', metadata.description, '",',
                '"image": "', imageUri, '",',
                '"animation_url": "', metadata.animationUrl, '",'
            )
        );
    }

    function _generateAttributesSection(uint8[7] memory values, uint8 palette, bool isLocked)
        internal
        pure
        returns (string memory)
    {
        return string(
            abi.encodePacked(
                '"attributes": [',
                '{"trait_type": "values", "value": "', _generateValueString(values), '"},',
                '{"trait_type": "palette", "value": "', _getPaletteName(palette), '"},',
                '{"trait_type": "locked", "value": "', isLocked ? 'true' : 'false', '"},',
                '{"display_type": "number", "trait_type": "current_value", "value": ', 
                uint256(_getCurrentValue(values)).toString(), 
                ', "max_value": 100, "min_value": 0}',
                ']'
            )
        );
    }

    function _generateValueString(uint8[7] memory values) 
        internal 
        pure 
        returns (string memory) 
    {
        return string(
            abi.encodePacked(
                uint256(values[0]).toString(), ',',
                uint256(values[1]).toString(), ',',
                uint256(values[2]).toString(), ',',
                uint256(values[3]).toString(), ',',
                uint256(values[4]).toString(), ',',
                uint256(values[5]).toString(), ',',
                uint256(values[6]).toString()
            )
        );
    }

    function _getPaletteName(uint8 palette) internal pure returns (string memory) {
        if (palette == 0) return "classic";
        if (palette == 1) return "ice";
        if (palette == 2) return "fire";
        if (palette == 3) return "punch";
        if (palette == 4) return "chromatic";
        if (palette == 5) return "pastel";
        return "greyscale";
    }

    function _getCurrentValue(uint8[7] memory values) 
        internal 
        pure 
        returns (uint8) 
    {
        // Start from index 6 and iterate until index 0
        for (int256 i = 6; i >= 0; i--) {
            if (values[uint256(i)] > 0) {
                return values[uint256(i)];
            }
        }
        return 0; // Return 0 if all values are zero
    }

    function lockTokenValues(uint256 tokenId) external onlyNFTContract {
        require(!_tokenLocked[tokenId], "Token already locked");
        
        // Get current values
        uint8[7] memory currentValues = generateValuesFromSeeds(tokenId);
        
        // Check that all values are non-zero
        for (uint256 i = 0; i < 7; i++) {
            require(currentValues[i] > 0, "Cannot lock: some values are zero");
        }
        
        _tokenLocked[tokenId] = true;
        _lockedValues[tokenId] = currentValues;
        
        emit TokenLocked(tokenId);
    }
}