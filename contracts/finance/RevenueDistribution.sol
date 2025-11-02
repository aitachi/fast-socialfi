// Author: Aitachi
// Email: 44158892@qq.com
// Date: 11-02-2025 17

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title RevenueDistribution
 * @dev Distributes circle revenue to community members based on holdings and contributions
 * @notice Revenue sources: trading fees, advertising, partnerships
 */
contract RevenueDistribution is ReentrancyGuard, Ownable {
    struct RevenueSource {
        string name; // e.g., "Trading Fees", "Advertising", "Partnerships"
        uint256 totalCollected; // Total revenue collected from this source
        bool isActive; // Whether this source is active
    }

    struct Distribution {
        uint256 distributionId; // Unique distribution ID
        uint256 totalAmount; // Total amount distributed
        uint256 timestamp; // Distribution timestamp
        uint256 tokenHoldersShare; // Amount for token holders (50%)
        uint256 contributorsShare; // Amount for contributors (30%)
        uint256 stakingPoolShare; // Amount for staking pool (20%)
        uint256 snapshotTotalSupply; // Total supply at snapshot
        bool isFinalized; // Whether distribution is finalized
    }

    struct UserContribution {
        uint256 postCount; // Number of posts
        uint256 commentCount; // Number of comments
        uint256 inviteCount; // Number of invites
        uint256 lastUpdate; // Last contribution update
        uint256 contributionScore; // Calculated contribution score
    }

    // Circle configuration
    address public circleToken; // Circle token address
    address public circleOwner; // Circle owner address
    address public stakingPool; // Staking pool address

    // Revenue sources
    mapping(uint256 => RevenueSource) public revenueSources;
    uint256 public nextSourceId;

    // Distribution tracking
    mapping(uint256 => Distribution) public distributions;
    mapping(uint256 => mapping(address => bool)) public hasClaimed; // distributionId => user => claimed
    mapping(uint256 => mapping(address => uint256)) public tokenBalanceSnapshots; // distributionId => user => balance
    mapping(address => UserContribution) public userContributions;
    uint256 public nextDistributionId;

    // Distribution weights (basis points)
    uint256 public tokenHoldersWeight = 5000; // 50%
    uint256 public contributorsWeight = 3000; // 30%
    uint256 public stakingPoolWeight = 2000; // 20%
    uint256 public constant WEIGHT_PRECISION = 10000;

    // Contribution scoring weights
    uint256 public postWeight = 100; // Points per post
    uint256 public commentWeight = 20; // Points per comment
    uint256 public inviteWeight = 500; // Points per invite

    // Statistics
    uint256 public totalRevenueCollected;
    uint256 public totalDistributed;
    uint256 public totalUniqueClaims;

    // Events
    event RevenueSourceAdded(uint256 indexed sourceId, string name);
    event RevenueSourceUpdated(uint256 indexed sourceId, bool isActive);
    event RevenueCollected(uint256 indexed sourceId, uint256 amount);

    event DistributionCreated(
        uint256 indexed distributionId,
        uint256 totalAmount,
        uint256 tokenHoldersShare,
        uint256 contributorsShare,
        uint256 stakingPoolShare
    );

    event RevenueClaimed(
        uint256 indexed distributionId,
        address indexed user,
        uint256 amount
    );

    event ContributionUpdated(
        address indexed user,
        uint256 postCount,
        uint256 commentCount,
        uint256 inviteCount,
        uint256 score
    );

    event WeightsUpdated(
        uint256 tokenHoldersWeight,
        uint256 contributorsWeight,
        uint256 stakingPoolWeight
    );

    /**
     * @dev Constructor
     * @param _circleToken Address of circle token
     * @param _circleOwner Address of circle owner
     * @param _stakingPool Address of staking pool
     */
    constructor(
        address _circleToken,
        address _circleOwner,
        address _stakingPool
    ) {
        require(_circleToken != address(0), "Invalid token");
        require(_circleOwner != address(0), "Invalid owner");

        circleToken = _circleToken;
        circleOwner = _circleOwner;
        stakingPool = _stakingPool;

        // Add default revenue sources
        _addRevenueSource("Trading Fees");
        _addRevenueSource("Advertising");
        _addRevenueSource("Partnerships");
    }

    /**
     * @dev Add a new revenue source
     * @param name Name of the revenue source
     */
    function addRevenueSource(string calldata name) external {
        require(msg.sender == circleOwner, "Only circle owner");
        _addRevenueSource(name);
    }

    /**
     * @dev Internal function to add revenue source
     * @param name Name of the revenue source
     */
    function _addRevenueSource(string memory name) internal {
        uint256 sourceId = nextSourceId++;
        revenueSources[sourceId] = RevenueSource({
            name: name,
            totalCollected: 0,
            isActive: true
        });

        emit RevenueSourceAdded(sourceId, name);
    }

    /**
     * @dev Toggle revenue source active status
     * @param sourceId ID of the revenue source
     */
    function toggleRevenueSource(uint256 sourceId) external {
        require(msg.sender == circleOwner, "Only circle owner");
        require(sourceId < nextSourceId, "Invalid source");

        revenueSources[sourceId].isActive = !revenueSources[sourceId].isActive;
        emit RevenueSourceUpdated(sourceId, revenueSources[sourceId].isActive);
    }

    /**
     * @dev Collect revenue from a source
     * @param sourceId ID of the revenue source
     */
    function collectRevenue(uint256 sourceId) external payable {
        require(sourceId < nextSourceId, "Invalid source");
        require(msg.value > 0, "Must collect > 0");
        require(revenueSources[sourceId].isActive, "Source not active");

        revenueSources[sourceId].totalCollected += msg.value;
        totalRevenueCollected += msg.value;

        emit RevenueCollected(sourceId, msg.value);
    }

    /**
     * @dev Create a new distribution
     * @param amount Total amount to distribute
     */
    function createDistribution(uint256 amount) external nonReentrant {
        require(msg.sender == circleOwner, "Only circle owner");
        require(amount > 0, "Amount must be > 0");
        require(address(this).balance >= amount, "Insufficient balance");

        // Calculate shares
        uint256 tokenHoldersShare = (amount * tokenHoldersWeight) / WEIGHT_PRECISION;
        uint256 contributorsShare = (amount * contributorsWeight) / WEIGHT_PRECISION;
        uint256 stakingPoolShare = (amount * stakingPoolWeight) / WEIGHT_PRECISION;

        // Get current token supply
        uint256 totalSupply = IERC20(circleToken).totalSupply();
        require(totalSupply > 0, "No token supply");

        // Create distribution
        uint256 distributionId = nextDistributionId++;
        distributions[distributionId] = Distribution({
            distributionId: distributionId,
            totalAmount: amount,
            timestamp: block.timestamp,
            tokenHoldersShare: tokenHoldersShare,
            contributorsShare: contributorsShare,
            stakingPoolShare: stakingPoolShare,
            snapshotTotalSupply: totalSupply,
            isFinalized: true
        });

        // Send staking pool share immediately
        if (stakingPoolShare > 0 && stakingPool != address(0)) {
            (bool success, ) = payable(stakingPool).call{value: stakingPoolShare}("");
            require(success, "Staking pool transfer failed");
        }

        emit DistributionCreated(
            distributionId,
            amount,
            tokenHoldersShare,
            contributorsShare,
            stakingPoolShare
        );
    }

    /**
     * @dev Claim revenue from a distribution
     * @param distributionId ID of the distribution
     */
    function claimRevenue(uint256 distributionId) external nonReentrant {
        require(distributionId < nextDistributionId, "Invalid distribution");
        require(!hasClaimed[distributionId][msg.sender], "Already claimed");

        Distribution memory dist = distributions[distributionId];
        require(dist.isFinalized, "Distribution not finalized");

        uint256 totalClaim = 0;

        // Calculate token holder share
        uint256 userBalance = IERC20(circleToken).balanceOf(msg.sender);
        if (userBalance > 0 && dist.snapshotTotalSupply > 0) {
            uint256 tokenShare = (dist.tokenHoldersShare * userBalance) / dist.snapshotTotalSupply;
            totalClaim += tokenShare;
        }

        // Calculate contributor share
        UserContribution memory contribution = userContributions[msg.sender];
        if (contribution.contributionScore > 0) {
            uint256 totalContributionScore = _getTotalContributionScore();
            if (totalContributionScore > 0) {
                uint256 contributorShare = (dist.contributorsShare * contribution.contributionScore)
                    / totalContributionScore;
                totalClaim += contributorShare;
            }
        }

        require(totalClaim > 0, "No revenue to claim");

        // Mark as claimed
        hasClaimed[distributionId][msg.sender] = true;
        totalDistributed += totalClaim;

        if (!hasClaimed[distributionId][msg.sender]) {
            totalUniqueClaims++;
        }

        // Transfer revenue
        (bool success, ) = payable(msg.sender).call{value: totalClaim}("");
        require(success, "Transfer failed");

        emit RevenueClaimed(distributionId, msg.sender, totalClaim);
    }

    /**
     * @dev Update user contributions (called by backend)
     * @param user Address of the user
     * @param postCount Number of posts
     * @param commentCount Number of comments
     * @param inviteCount Number of invites
     */
    function updateContribution(
        address user,
        uint256 postCount,
        uint256 commentCount,
        uint256 inviteCount
    ) external {
        require(msg.sender == circleOwner || msg.sender == owner(), "Not authorized");

        UserContribution storage contribution = userContributions[user];
        contribution.postCount = postCount;
        contribution.commentCount = commentCount;
        contribution.inviteCount = inviteCount;
        contribution.lastUpdate = block.timestamp;

        // Calculate contribution score
        contribution.contributionScore =
            (postCount * postWeight) +
            (commentCount * commentWeight) +
            (inviteCount * inviteWeight);

        emit ContributionUpdated(
            user,
            postCount,
            commentCount,
            inviteCount,
            contribution.contributionScore
        );
    }

    /**
     * @dev Get claimable revenue for a user
     * @param distributionId ID of the distribution
     * @param user Address of the user
     * @return Claimable amount
     */
    function getClaimableRevenue(
        uint256 distributionId,
        address user
    ) external view returns (uint256) {
        if (distributionId >= nextDistributionId) return 0;
        if (hasClaimed[distributionId][user]) return 0;

        Distribution memory dist = distributions[distributionId];
        if (!dist.isFinalized) return 0;

        uint256 totalClaim = 0;

        // Token holder share
        uint256 userBalance = IERC20(circleToken).balanceOf(user);
        if (userBalance > 0 && dist.snapshotTotalSupply > 0) {
            totalClaim += (dist.tokenHoldersShare * userBalance) / dist.snapshotTotalSupply;
        }

        // Contributor share
        UserContribution memory contribution = userContributions[user];
        if (contribution.contributionScore > 0) {
            uint256 totalScore = _getTotalContributionScore();
            if (totalScore > 0) {
                totalClaim += (dist.contributorsShare * contribution.contributionScore) / totalScore;
            }
        }

        return totalClaim;
    }

    /**
     * @dev Get total contribution score across all users
     * @return Total score
     * @notice This is a simplified version; production should cache this value
     */
    function _getTotalContributionScore() internal view returns (uint256) {
        // In production, this should be maintained as a state variable
        // For now, return a placeholder - will be updated during distribution creation
        return 1000000; // Placeholder
    }

    /**
     * @dev Update distribution weights
     * @param _tokenHoldersWeight Weight for token holders
     * @param _contributorsWeight Weight for contributors
     * @param _stakingPoolWeight Weight for staking pool
     */
    function updateWeights(
        uint256 _tokenHoldersWeight,
        uint256 _contributorsWeight,
        uint256 _stakingPoolWeight
    ) external {
        require(msg.sender == circleOwner, "Only circle owner");
        require(
            _tokenHoldersWeight + _contributorsWeight + _stakingPoolWeight == WEIGHT_PRECISION,
            "Weights must sum to 10000"
        );

        tokenHoldersWeight = _tokenHoldersWeight;
        contributorsWeight = _contributorsWeight;
        stakingPoolWeight = _stakingPoolWeight;

        emit WeightsUpdated(_tokenHoldersWeight, _contributorsWeight, _stakingPoolWeight);
    }

    /**
     * @dev Update contribution scoring weights
     * @param _postWeight Points per post
     * @param _commentWeight Points per comment
     * @param _inviteWeight Points per invite
     */
    function updateContributionWeights(
        uint256 _postWeight,
        uint256 _commentWeight,
        uint256 _inviteWeight
    ) external {
        require(msg.sender == circleOwner, "Only circle owner");

        postWeight = _postWeight;
        commentWeight = _commentWeight;
        inviteWeight = _inviteWeight;
    }

    /**
     * @dev Update staking pool address
     * @param _stakingPool New staking pool address
     */
    function updateStakingPool(address _stakingPool) external {
        require(msg.sender == circleOwner, "Only circle owner");
        stakingPool = _stakingPool;
    }

    /**
     * @dev Get distribution history
     * @param startId Start distribution ID
     * @param count Number of distributions to return
     * @return Array of distributions
     */
    function getDistributions(
        uint256 startId,
        uint256 count
    ) external view returns (Distribution[] memory) {
        uint256 endId = startId + count;
        if (endId > nextDistributionId) {
            endId = nextDistributionId;
        }

        uint256 resultCount = endId - startId;
        Distribution[] memory result = new Distribution[](resultCount);

        for (uint256 i = 0; i < resultCount; i++) {
            result[i] = distributions[startId + i];
        }

        return result;
    }

    /**
     * @dev Get user contribution details
     * @param user Address of the user
     * @return Contribution details
     */
    function getUserContribution(address user) external view returns (UserContribution memory) {
        return userContributions[user];
    }

    /**
     * @dev Get contract statistics
     * @return totalRevenue Total revenue collected
     * @return totalDist Total distributed
     * @return distributionCount Number of distributions
     */
    function getStats() external view returns (
        uint256 totalRevenue,
        uint256 totalDist,
        uint256 distributionCount
    ) {
        return (totalRevenueCollected, totalDistributed, nextDistributionId);
    }

    /**
     * @dev Receive ETH (auto-credit to default revenue source)
     */
    receive() external payable {
        if (msg.value > 0) {
            revenueSources[0].totalCollected += msg.value; // Trading fees
            totalRevenueCollected += msg.value;
            emit RevenueCollected(0, msg.value);
        }
    }
}
