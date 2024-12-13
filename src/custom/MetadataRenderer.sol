// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Base64 } from "openzeppelin-contracts/utils/Base64.sol";
import { Strings } from "openzeppelin-contracts/utils/Strings.sol";
import { SVGGenerator } from "./SVGGenerator.sol";

contract MetadataRenderer {
    using Strings for uint256;

    struct TokenMetadata {
        string name;
        string description;
        string image;
        string animationUrl;
        uint8[7] values;
        uint8 palette;
    }

    mapping(uint256 => TokenMetadata) private _tokenMetadata;
    address public immutable nftContract;

    event MetadataUpdated(uint256 indexed tokenId);

    constructor(address _nftContract) {
        nftContract = _nftContract;
    }

    modifier onlyNFTContract() {
        require(msg.sender == nftContract, "Only NFT contract");
        _;
    }

    function setTokenMetadata(
        uint256 tokenId,
        string memory name,
        string memory description,
        string memory image,
        string memory animationUrl,
        uint8[7] memory values,
        uint8 palette
    ) external onlyNFTContract {
        for (uint256 i = 0; i < 7; i++) {
            require(values[i] <= 100, "Values must be between 0 and 100");
        }

        _tokenMetadata[tokenId] = TokenMetadata({
            name: name,
            description: description,
            image: image,
            animationUrl: animationUrl,
            values: values,
            palette: palette
        });

        emit MetadataUpdated(tokenId);
    }

    function generateTokenURI(uint256 tokenId) 
        external 
        view 
        returns (string memory) 
    {
        TokenMetadata memory metadata = _tokenMetadata[tokenId];
        return _generateFullTokenURI(tokenId, metadata);
    }

    function _generateFullTokenURI(uint256 tokenId, TokenMetadata memory metadata)
        internal
        pure
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
    ) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                '{',
                _generateBasicFields(tokenId, metadata, imageUri),
                _generateAttributesSection(metadata.values, metadata.palette),
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

    function _generateAttributesSection(uint8[7] memory values, uint8 palette)
        internal
        pure
        returns (string memory)
    {
        return string(
            abi.encodePacked(
                '"values": [',
                _generateValueString(values),
                '],',
                '"palette": "',
                _getPaletteName(palette),
                '"'
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
}