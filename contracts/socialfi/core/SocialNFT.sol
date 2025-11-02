// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "../libraries/Counters.sol";

/**
 * @title SocialNFT
 * @dev ERC721 NFT for SocialFi Content with royalty support
 *
 * Features:
 * - Standard ERC721 functionality
 * - Content creators can mint their own NFTs
 * - Royalty mechanism (ERC2981)
 * - IPFS metadata storage
 * - Batch minting capability
 * - Minting fee system
 * - Whitelist mechanism
 * - NFT attributes system
 */
contract SocialNFT is ERC721, ERC721URIStorage, ERC721Burnable, Ownable, ERC2981 {
    using Counters for Counters.Counter;

    // Token ID counter
    Counters.Counter private _tokenIdCounter;

    // Minting fee in wei
    uint256 public mintingFee;

    // Default royalty percentage (basis points: 1000 = 10%)
    uint96 public constant DEFAULT_ROYALTY_FEE = 1000; // 10%

    // Whitelist for minting
    mapping(address => bool) public whitelist;
    bool public whitelistEnabled;

    // NFT attributes
    struct NFTAttributes {
        string contentType;
        uint256 createdAt;
        address creator;
        bool isVerified;
        uint256 likes;
        uint256 shares;
    }

    mapping(uint256 => NFTAttributes) public nftAttributes;

    // Events
    event NFTMinted(uint256 indexed tokenId, address indexed creator, string uri);
    event BatchMinted(address indexed creator, uint256[] tokenIds);
    event MintingFeeUpdated(uint256 oldFee, uint256 newFee);
    event WhitelistUpdated(address indexed account, bool status);
    event WhitelistToggled(bool enabled);
    event RoyaltyUpdated(uint256 indexed tokenId, address receiver, uint96 feeNumerator);
    event NFTVerified(uint256 indexed tokenId);
    event NFTInteraction(uint256 indexed tokenId, string interactionType, uint256 count);

    /**
     * @dev Constructor to initialize SocialFi Content NFT
     * @param initialOwner Address of the initial owner
     * @param _mintingFee Initial minting fee
     */
    constructor(address initialOwner, uint256 _mintingFee)
        ERC721("SocialFi Content NFT", "SNFT")
        Ownable(initialOwner)
    {
        mintingFee = _mintingFee;
        whitelistEnabled = false;

        // Set default royalty for contract owner
        _setDefaultRoyalty(initialOwner, DEFAULT_ROYALTY_FEE);
    }

    /**
     * @dev Mint a new NFT
     * @param uri IPFS URI for the NFT metadata
     * @param contentType Type of content (image, video, article, etc.)
     * @return tokenId The ID of the minted token
     */
    function mint(string memory uri, string memory contentType) public payable returns (uint256) {
        require(msg.value >= mintingFee, "Insufficient minting fee");

        if (whitelistEnabled) {
            require(whitelist[msg.sender] || msg.sender == owner(), "Not whitelisted");
        }

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, uri);

        // Set NFT attributes
        nftAttributes[tokenId] = NFTAttributes({
            contentType: contentType,
            createdAt: block.timestamp,
            creator: msg.sender,
            isVerified: false,
            likes: 0,
            shares: 0
        });

        // Set royalty for this token
        _setTokenRoyalty(tokenId, msg.sender, DEFAULT_ROYALTY_FEE);

        emit NFTMinted(tokenId, msg.sender, uri);
        return tokenId;
    }

    /**
     * @dev Batch mint multiple NFTs
     * @param uris Array of IPFS URIs
     * @param contentTypes Array of content types
     * @return tokenIds Array of minted token IDs
     */
    function batchMint(
        string[] memory uris,
        string[] memory contentTypes
    ) external payable returns (uint256[] memory) {
        require(uris.length == contentTypes.length, "Array length mismatch");
        require(uris.length > 0, "Empty arrays");
        require(msg.value >= mintingFee * uris.length, "Insufficient minting fee");

        if (whitelistEnabled) {
            require(whitelist[msg.sender] || msg.sender == owner(), "Not whitelisted");
        }

        uint256[] memory tokenIds = new uint256[](uris.length);

        for (uint256 i = 0; i < uris.length; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();

            _safeMint(msg.sender, tokenId);
            _setTokenURI(tokenId, uris[i]);

            // Set NFT attributes
            nftAttributes[tokenId] = NFTAttributes({
                contentType: contentTypes[i],
                createdAt: block.timestamp,
                creator: msg.sender,
                isVerified: false,
                likes: 0,
                shares: 0
            });

            // Set royalty for this token
            _setTokenRoyalty(tokenId, msg.sender, DEFAULT_ROYALTY_FEE);

            tokenIds[i] = tokenId;
        }

        emit BatchMinted(msg.sender, tokenIds);
        return tokenIds;
    }

    /**
     * @dev Set custom royalty for a specific token
     * @param tokenId Token ID
     * @param receiver Royalty receiver address
     * @param feeNumerator Royalty fee in basis points
     */
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external {
        require(_ownerOf(tokenId) == msg.sender || msg.sender == owner(), "Not authorized");
        require(feeNumerator <= 10000, "Fee too high");

        _setTokenRoyalty(tokenId, receiver, feeNumerator);
        emit RoyaltyUpdated(tokenId, receiver, feeNumerator);
    }

    /**
     * @dev Verify an NFT (only owner)
     * @param tokenId Token ID to verify
     */
    function verifyNFT(uint256 tokenId) external onlyOwner {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        nftAttributes[tokenId].isVerified = true;
        emit NFTVerified(tokenId);
    }

    /**
     * @dev Record NFT interaction (like/share)
     * @param tokenId Token ID
     * @param interactionType Type of interaction ("like" or "share")
     */
    function recordInteraction(uint256 tokenId, string memory interactionType) external {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");

        if (keccak256(bytes(interactionType)) == keccak256(bytes("like"))) {
            nftAttributes[tokenId].likes++;
            emit NFTInteraction(tokenId, "like", nftAttributes[tokenId].likes);
        } else if (keccak256(bytes(interactionType)) == keccak256(bytes("share"))) {
            nftAttributes[tokenId].shares++;
            emit NFTInteraction(tokenId, "share", nftAttributes[tokenId].shares);
        } else {
            revert("Invalid interaction type");
        }
    }

    /**
     * @dev Update minting fee (only owner)
     * @param newFee New minting fee in wei
     */
    function setMintingFee(uint256 newFee) external onlyOwner {
        uint256 oldFee = mintingFee;
        mintingFee = newFee;
        emit MintingFeeUpdated(oldFee, newFee);
    }

    /**
     * @dev Add or remove address from whitelist (only owner)
     * @param account Address to update
     * @param status Whitelist status
     */
    function setWhitelist(address account, bool status) external onlyOwner {
        whitelist[account] = status;
        emit WhitelistUpdated(account, status);
    }

    /**
     * @dev Toggle whitelist requirement (only owner)
     * @param enabled Enable/disable whitelist
     */
    function toggleWhitelist(bool enabled) external onlyOwner {
        whitelistEnabled = enabled;
        emit WhitelistToggled(enabled);
    }

    /**
     * @dev Withdraw collected minting fees (only owner)
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        payable(owner()).transfer(balance);
    }

    /**
     * @dev Get NFT attributes
     * @param tokenId Token ID
     * @return NFTAttributes structure
     */
    function getAttributes(uint256 tokenId) external view returns (NFTAttributes memory) {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        return nftAttributes[tokenId];
    }

    /**
     * @dev Get total number of NFTs minted
     * @return Total supply
     */
    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter.current();
    }

    // Required overrides
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
