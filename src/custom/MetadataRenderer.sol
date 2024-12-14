// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Base64 } from "openzeppelin-contracts/utils/Base64.sol";
import { Strings } from "openzeppelin-contracts/utils/Strings.sol";
import { SVGGenerator } from "./SVGGenerator.sol";
import { TokenMetadata } from "./SeaDropTypes.sol";

/// @title NFT Metadata Renderer
/// @notice Handles the generation and management of NFT metadata
contract MetadataRenderer {
    using Strings for uint256;

    // ============ Constants ============

    // Time constants
    uint256 private constant _DAY_IN_SECONDS = 1;

    // Value generation constants
    uint256 private constant _MAX_RANDOM_VALUE = 100;
    uint256 private constant _SEED_ARRAY_SIZE = 7;
    uint256 private constant _VALUES_ARRAY_SIZE = 7;

    // Palette distribution constants
    uint256 private constant _PALETTE_0_THRESHOLD = 8;
    uint256 private constant _PALETTE_1_THRESHOLD = 12;
    uint256 private constant _PALETTE_2_THRESHOLD = 14;
    uint256 private constant _PALETTE_3_THRESHOLD = 15;
    uint256 private constant _TOTAL_DISTRIBUTION_RANGE = 16;

    // Metadata constants
    string private constant _BASE_NAME = "Untitled";
    string private constant _BASE_DESCRIPTION = "A new NFT";
    string private constant _PALETTE_PREFIX = "Palette ";

    // ============ Storage ============

    // State variables
    bytes32[_SEED_ARRAY_SIZE] private _randomSeeds;
    uint256 private _lastUpdateBlock;
    address public immutable nftContract;

    // Mappings
    mapping(uint256 => uint8) private _tokenPalettes;
    mapping(uint256 => bool) private _tokenLocked;
    mapping(uint256 => uint8[_VALUES_ARRAY_SIZE]) private _lockedValues;

    // ============ Events ============

    event MetadataUpdated(uint256 indexed tokenId);
    event TokenLocked(uint256 indexed tokenId);

    // ============ Errors ============

    error OnlyNFTContract();
    error TooEarlyToUpdate();
    error InvalidBlockHash();
    error TokenAlreadyLocked();
    error ValuesNotReadyForLocking(string message);

    // ============ Constructor & Modifier ============

    constructor(address _nftContract) {
        nftContract = _nftContract;
        _lastUpdateBlock = block.timestamp;
    }

    modifier onlyNFTContract() {
        if (msg.sender != nftContract) revert OnlyNFTContract();
        _;
    }

    // ============ Public Functions ============

    function setInitialMetadata(uint256 tokenId) external onlyNFTContract {
        _tokenPalettes[tokenId] = _calculateInitialPalette(tokenId);
    }

    function updateDailySeeds() external {
        if (block.timestamp < _lastUpdateBlock + _DAY_IN_SECONDS) revert TooEarlyToUpdate();
        
        bytes32 newSeed = _getNewRandomSeed();
        _updateRandomSeeds(newSeed);
        _lastUpdateBlock = block.timestamp;
    }

    function generateTokenURI(uint256 tokenId) external view returns (string memory) {        
        TokenMetadata memory metadata = _createTokenMetadata(tokenId);
        return _generateFullTokenURI(metadata);
    }

    function lockTokenValues(uint256 tokenId) external onlyNFTContract {
        if (_tokenLocked[tokenId]) revert TokenAlreadyLocked();
        
        uint8[_VALUES_ARRAY_SIZE] memory currentValues = generateValuesFromSeeds(tokenId);
        if (!_areAllValuesNonZero(currentValues)) {
            revert ValuesNotReadyForLocking("Token values are not yet complete. Please wait for daily updates to generate all values before locking.");
        }
        
        _tokenLocked[tokenId] = true;
        _lockedValues[tokenId] = currentValues;
        
        emit TokenLocked(tokenId);
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

    // ============ View Functions ============

    function generateValuesFromSeeds(uint256 tokenId) 
        public 
        view 
        returns (uint8[_VALUES_ARRAY_SIZE] memory) 
    {
        return _tokenLocked[tokenId] ? _lockedValues[tokenId] : _generateNewValues(tokenId);
    }

    function getRandomSeeds() external view returns (bytes32[_SEED_ARRAY_SIZE] memory) {
        return _randomSeeds;
    }

    // ============ Internal Token Generation Functions ============

    function _calculateInitialPalette(uint256 tokenId) private pure returns (uint8) {
        uint256 mod16 = tokenId % _TOTAL_DISTRIBUTION_RANGE;
        
        if (mod16 < _PALETTE_0_THRESHOLD) return 0;
        if (mod16 < _PALETTE_1_THRESHOLD) return 1;
        if (mod16 < _PALETTE_2_THRESHOLD) return 2;
        if (mod16 < _PALETTE_3_THRESHOLD) return 3;
        return 0;
    }

    function _getNewRandomSeed() private view returns (bytes32) {
        if (block.number == 0) revert InvalidBlockHash();
        
        bytes32 previousBlockHash = blockhash(block.number - 1);
        if (previousBlockHash == bytes32(0)) revert InvalidBlockHash();
        
        return previousBlockHash;
    }

    function _updateRandomSeeds(bytes32 newSeed) private {
        uint256 emptySlot = _findEmptySlot();
        if (emptySlot < _SEED_ARRAY_SIZE) {
            _randomSeeds[emptySlot] = newSeed;
        } else {
            _shiftAndUpdateSeeds(newSeed);
        }
    }

    function _findEmptySlot() private view returns (uint256) {
        for (uint256 i = 0; i < _SEED_ARRAY_SIZE; i++) {
            if (_randomSeeds[i] == 0) return i;
        }
        return _SEED_ARRAY_SIZE;
    }

    function _shiftAndUpdateSeeds(bytes32 newSeed) private {
        for (uint256 i = 0; i < _SEED_ARRAY_SIZE - 1; i++) {
            _randomSeeds[i] = _randomSeeds[i + 1];
        }
        _randomSeeds[_SEED_ARRAY_SIZE - 1] = newSeed;
    }

    // ============ Internal Value Generation Functions ============

    function _generateNewValues(uint256 tokenId) 
        private 
        view 
        returns (uint8[_VALUES_ARRAY_SIZE] memory) 
    {
        uint8[_VALUES_ARRAY_SIZE] memory values;
        
        for (uint256 i = 0; i < _VALUES_ARRAY_SIZE; i++) {
            if (_randomSeeds[i] != 0) {
                values[i] = _generateSingleValue(_randomSeeds[i], tokenId);
            }
        }
        return values;
    }

    function _generateSingleValue(bytes32 seed, uint256 tokenId) 
        private 
        pure 
        returns (uint8) 
    {
        bytes32 combinedSeed = keccak256(abi.encodePacked(seed, tokenId));
        return uint8((uint256(combinedSeed) % _MAX_RANDOM_VALUE) + 1);
    }

    function _areAllValuesNonZero(uint8[_VALUES_ARRAY_SIZE] memory values) 
        private 
        pure 
        returns (bool) 
    {
        for (uint256 i = 0; i < _VALUES_ARRAY_SIZE; i++) {
            if (values[i] == 0) return false;
        }
        return true;
    }

    function _getLastNonZeroValue(uint8[_VALUES_ARRAY_SIZE] memory values) 
        private 
        pure 
        returns (uint8) 
    {
        uint8 lastValue = 0;
        for (uint256 i = 0; i < _VALUES_ARRAY_SIZE; i++) {
            if (values[i] != 0) {
                lastValue = values[i];
            }
        }
        return lastValue;
    }

    // ============ Internal Metadata Generation Functions ============

    function _createTokenMetadata(uint256 tokenId) 
        private 
        view 
        returns (TokenMetadata memory) 
    {
        return TokenMetadata({
            name: _generateName(tokenId),
            description: _BASE_DESCRIPTION,
            image: _generateImageURI(tokenId),
            animationUrl: _generateAnimationURI(),
            values: generateValuesFromSeeds(tokenId),
            palette: _tokenPalettes[tokenId],
            isLocked: _tokenLocked[tokenId]
        });
    }

    function _generateName(uint256 tokenId) private pure returns (string memory) {
        return string(abi.encodePacked(_BASE_NAME, " #", tokenId.toString()));
    }

    function _generateImageURI(uint256 tokenId) private view returns (string memory) {
        return string(
            abi.encodePacked(
                "data:image/svg+xml;base64,",
                SVGGenerator.generateSVG(
                    generateValuesFromSeeds(tokenId),
                    _tokenPalettes[tokenId]
                )
            )
        );
    }

    function _generateAnimationURI() private pure returns (string memory) {
        // Animation URI generation logic here
        return "";
    }

    function _generateFullTokenURI(TokenMetadata memory metadata) 
        private 
        pure 
        returns (string memory) 
    {
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        _generateJSONMetadata(metadata)
                    )
                )
            )
        );
    }

    function _generateJSONMetadata(TokenMetadata memory metadata) 
        private 
        pure 
        returns (string memory) 
    {
        return string(
            abi.encodePacked(
                '{',
                _generateBasicProperties(metadata),
                _generateAttributesSection(metadata),
                '}'
            )
        );
    }

    function _generateBasicProperties(TokenMetadata memory metadata) 
        private 
        pure 
        returns (string memory) 
    {
        return string(
            abi.encodePacked(
                '"name":"', metadata.name, '",',
                '"description":"', metadata.description, '",',
                '"image":"', metadata.image, '",',
                '"animation_url":"', metadata.animationUrl, '",'
            )
        );
    }

    function _generateAttributesSection(TokenMetadata memory metadata) 
        private 
        pure 
        returns (string memory) 
    {
        return string(
            abi.encodePacked(
                '"attributes":[',
                _generateAttributes(metadata),
                ']'
            )
        );
    }

    function _generateAttributes(TokenMetadata memory metadata) 
        private 
        pure 
        returns (string memory) 
    {
        return string(
            abi.encodePacked(
                '{"trait_type":"values","value":"', _generateValueString(metadata.values), '"},',
                '{"trait_type":"palette","value":"', _getPaletteName(metadata.palette), '"},',
                '{"trait_type":"isLocked","value":"', metadata.isLocked ? 'yes' : 'no', '"},',
                '{"trait_type":"value","value":"', uint256(_getLastNonZeroValue(metadata.values)).toString(), '"}'
            )
        );
    }

    function _generateValueString(uint8[_VALUES_ARRAY_SIZE] memory values) 
        private 
        pure 
        returns (string memory) 
    {
        string memory result = "";
        for (uint256 i = 0; i < _VALUES_ARRAY_SIZE; i++) {
            if (i > 0) result = string(abi.encodePacked(result, ","));
            result = string(abi.encodePacked(result, uint256(values[i]).toString()));
        }
        return result;
    }

    function _getPaletteName(uint8 palette) private pure returns (string memory) {
        return string(abi.encodePacked(_PALETTE_PREFIX, uint256(palette).toString()));
    }
}