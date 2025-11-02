// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title ContentRegistry
 * @dev Content copyright registration and monetization platform
 *
 * Features:
 * - Content copyright registration
 * - Tipping system (ETH or SOCIAL tokens)
 * - Creator revenue distribution
 * - Content licensing management
 * - Content verification
 * - Platform fee system
 */
contract ContentRegistry is Ownable, ReentrancyGuard {

    // Content structure
    struct Content {
        uint256 id;
        address creator;
        string ipfsHash;
        uint256 timestamp;
        uint256 totalTipsETH;
        uint256 totalTipsToken;
        bool isNFT;
        uint256 nftTokenId;
        bool isVerified;
        string licenseType;
        uint256 price;
    }

    // License structure
    struct License {
        address licensee;
        uint256 contentId;
        uint256 expiryDate;
        bool isActive;
    }

    // SOCIAL token contract
    IERC20 public socialToken;

    // Platform fee (basis points: 250 = 2.5%)
    uint256 public platformFeePercent = 250;

    // Content counter
    uint256 private contentCounter;

    // Content mappings
    mapping(uint256 => Content) public contents;
    mapping(string => uint256) public ipfsHashToContentId;
    mapping(address => uint256[]) public creatorContents;

    // License mappings
    mapping(uint256 => License[]) public contentLicenses;
    mapping(address => mapping(uint256 => bool)) public hasLicense;

    // Platform earnings
    uint256 public platformEarningsETH;
    uint256 public platformEarningsToken;

    // Events
    event ContentRegistered(
        uint256 indexed contentId,
        address indexed creator,
        string ipfsHash,
        bool isNFT,
        uint256 nftTokenId
    );
    event ContentTipped(
        uint256 indexed contentId,
        address indexed tipper,
        uint256 amount,
        bool isETH
    );
    event ContentVerified(uint256 indexed contentId);
    event LicenseGranted(
        uint256 indexed contentId,
        address indexed licensee,
        uint256 expiryDate
    );
    event LicenseRevoked(uint256 indexed contentId, address indexed licensee);
    event PlatformFeeUpdated(uint256 oldFee, uint256 newFee);
    event EarningsWithdrawn(address indexed recipient, uint256 amountETH, uint256 amountToken);

    /**
     * @dev Constructor
     * @param initialOwner Initial owner address
     * @param _socialToken SOCIAL token contract address
     */
    constructor(address initialOwner, address _socialToken) Ownable(initialOwner) {
        require(_socialToken != address(0), "Invalid token address");
        socialToken = IERC20(_socialToken);
    }

    /**
     * @dev Register new content
     * @param ipfsHash IPFS hash of the content
     * @param isNFT Whether content is minted as NFT
     * @param nftTokenId Token ID if it's an NFT
     * @param licenseType Type of license (e.g., "CC-BY", "All Rights Reserved")
     * @param price Price for licensing (0 if free)
     * @return contentId The ID of registered content
     */
    function registerContent(
        string memory ipfsHash,
        bool isNFT,
        uint256 nftTokenId,
        string memory licenseType,
        uint256 price
    ) external returns (uint256) {
        require(bytes(ipfsHash).length > 0, "Empty IPFS hash");
        require(ipfsHashToContentId[ipfsHash] == 0, "Content already registered");

        contentCounter++;
        uint256 contentId = contentCounter;

        contents[contentId] = Content({
            id: contentId,
            creator: msg.sender,
            ipfsHash: ipfsHash,
            timestamp: block.timestamp,
            totalTipsETH: 0,
            totalTipsToken: 0,
            isNFT: isNFT,
            nftTokenId: nftTokenId,
            isVerified: false,
            licenseType: licenseType,
            price: price
        });

        ipfsHashToContentId[ipfsHash] = contentId;
        creatorContents[msg.sender].push(contentId);

        emit ContentRegistered(contentId, msg.sender, ipfsHash, isNFT, nftTokenId);
        return contentId;
    }

    /**
     * @dev Tip content with ETH
     * @param contentId Content ID to tip
     */
    function tipContentETH(uint256 contentId) external payable nonReentrant {
        require(msg.value > 0, "Tip amount must be > 0");
        require(contents[contentId].creator != address(0), "Content does not exist");

        Content storage content = contents[contentId];

        // Calculate platform fee
        uint256 platformFee = (msg.value * platformFeePercent) / 10000;
        uint256 creatorAmount = msg.value - platformFee;

        // Update balances
        content.totalTipsETH += msg.value;
        platformEarningsETH += platformFee;

        // Transfer to creator
        payable(content.creator).transfer(creatorAmount);

        emit ContentTipped(contentId, msg.sender, msg.value, true);
    }

    /**
     * @dev Tip content with SOCIAL tokens
     * @param contentId Content ID to tip
     * @param amount Amount of tokens to tip
     */
    function tipContentToken(uint256 contentId, uint256 amount) external nonReentrant {
        require(amount > 0, "Tip amount must be > 0");
        require(contents[contentId].creator != address(0), "Content does not exist");

        Content storage content = contents[contentId];

        // Calculate platform fee
        uint256 platformFee = (amount * platformFeePercent) / 10000;
        uint256 creatorAmount = amount - platformFee;

        // Update balances
        content.totalTipsToken += amount;
        platformEarningsToken += platformFee;

        // Transfer tokens
        require(
            socialToken.transferFrom(msg.sender, content.creator, creatorAmount),
            "Creator transfer failed"
        );
        require(
            socialToken.transferFrom(msg.sender, address(this), platformFee),
            "Platform fee transfer failed"
        );

        emit ContentTipped(contentId, msg.sender, amount, false);
    }

    /**
     * @dev Grant license to access content
     * @param contentId Content ID
     * @param durationDays License duration in days
     */
    function purchaseLicense(uint256 contentId, uint256 durationDays) external payable nonReentrant {
        require(contents[contentId].creator != address(0), "Content does not exist");
        require(!hasLicense[msg.sender][contentId], "License already exists");

        Content storage content = contents[contentId];
        require(content.price > 0, "Content is free");
        require(msg.value >= content.price, "Insufficient payment");

        // Calculate platform fee
        uint256 platformFee = (msg.value * platformFeePercent) / 10000;
        uint256 creatorAmount = msg.value - platformFee;

        // Update balances
        platformEarningsETH += platformFee;

        // Transfer to creator
        payable(content.creator).transfer(creatorAmount);

        // Grant license
        uint256 expiryDate = block.timestamp + (durationDays * 1 days);
        contentLicenses[contentId].push(License({
            licensee: msg.sender,
            contentId: contentId,
            expiryDate: expiryDate,
            isActive: true
        }));

        hasLicense[msg.sender][contentId] = true;

        emit LicenseGranted(contentId, msg.sender, expiryDate);
    }

    /**
     * @dev Revoke license (only creator or owner)
     * @param contentId Content ID
     * @param licensee Address to revoke license from
     */
    function revokeLicense(uint256 contentId, address licensee) external {
        require(
            msg.sender == contents[contentId].creator || msg.sender == owner(),
            "Not authorized"
        );
        require(hasLicense[licensee][contentId], "No active license");

        License[] storage licenses = contentLicenses[contentId];
        for (uint256 i = 0; i < licenses.length; i++) {
            if (licenses[i].licensee == licensee && licenses[i].isActive) {
                licenses[i].isActive = false;
                break;
            }
        }

        hasLicense[licensee][contentId] = false;

        emit LicenseRevoked(contentId, licensee);
    }

    /**
     * @dev Verify content (only owner)
     * @param contentId Content ID to verify
     */
    function verifyContent(uint256 contentId) external onlyOwner {
        require(contents[contentId].creator != address(0), "Content does not exist");
        contents[contentId].isVerified = true;
        emit ContentVerified(contentId);
    }

    /**
     * @dev Update platform fee (only owner)
     * @param newFeePercent New fee percentage in basis points
     */
    function setPlatformFee(uint256 newFeePercent) external onlyOwner {
        require(newFeePercent <= 1000, "Fee too high"); // Max 10%
        uint256 oldFee = platformFeePercent;
        platformFeePercent = newFeePercent;
        emit PlatformFeeUpdated(oldFee, newFeePercent);
    }

    /**
     * @dev Withdraw platform earnings (only owner)
     */
    function withdrawEarnings() external onlyOwner nonReentrant {
        uint256 ethAmount = platformEarningsETH;
        uint256 tokenAmount = platformEarningsToken;

        platformEarningsETH = 0;
        platformEarningsToken = 0;

        if (ethAmount > 0) {
            payable(owner()).transfer(ethAmount);
        }

        if (tokenAmount > 0) {
            require(socialToken.transfer(owner(), tokenAmount), "Token transfer failed");
        }

        emit EarningsWithdrawn(owner(), ethAmount, tokenAmount);
    }

    /**
     * @dev Get content by ID
     * @param contentId Content ID
     * @return Content struct
     */
    function getContent(uint256 contentId) external view returns (Content memory) {
        require(contents[contentId].creator != address(0), "Content does not exist");
        return contents[contentId];
    }

    /**
     * @dev Get contents by creator
     * @param creator Creator address
     * @return Array of content IDs
     */
    function getCreatorContents(address creator) external view returns (uint256[] memory) {
        return creatorContents[creator];
    }

    /**
     * @dev Check if user has valid license
     * @param contentId Content ID
     * @param user User address
     * @return bool Whether user has valid license
     */
    function hasValidLicense(uint256 contentId, address user) external view returns (bool) {
        if (!hasLicense[user][contentId]) {
            return false;
        }

        License[] memory licenses = contentLicenses[contentId];
        for (uint256 i = 0; i < licenses.length; i++) {
            if (
                licenses[i].licensee == user &&
                licenses[i].isActive &&
                licenses[i].expiryDate > block.timestamp
            ) {
                return true;
            }
        }

        return false;
    }

    /**
     * @dev Get total number of registered contents
     * @return Total content count
     */
    function getTotalContents() external view returns (uint256) {
        return contentCounter;
    }
}
