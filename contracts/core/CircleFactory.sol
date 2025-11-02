// Author: Aitachi
// Email: 44158892@qq.com
// Date: 11-02-2025 17

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./CircleToken.sol";
import "./BondingCurve.sol";

/**
 * @title CircleFactory
 * @dev Factory contract for creating and managing social circles
 */
contract CircleFactory is Ownable, Pausable, ReentrancyGuard {
    struct Circle {
        uint256 circleId;
        address owner;
        address tokenAddress;
        address bondingCurveAddress;
        string name;
        string symbol;
        uint256 createdAt;
        bool active;
        BondingCurve.CurveType curveType;
    }

    // State variables
    mapping(uint256 => Circle) public circles;
    mapping(address => uint256[]) public ownerCircles;
    mapping(address => bool) public isCircleToken;

    uint256 public circleCount;
    address public bondingCurveImpl;
    address public platformTreasury;

    // Configuration
    uint256 public circleCreationFee = 0.01 ether;
    uint256 public constant MAX_CIRCLES_PER_USER = 10;

    // Events
    event CircleCreated(
        uint256 indexed circleId,
        address indexed owner,
        address indexed tokenAddress,
        string name,
        string symbol,
        BondingCurve.CurveType curveType
    );

    event CircleDeactivated(uint256 indexed circleId);
    event CircleReactivated(uint256 indexed circleId);
    event CircleOwnershipTransferred(
        uint256 indexed circleId,
        address indexed oldOwner,
        address indexed newOwner
    );
    event CircleCreationFeeUpdated(uint256 newFee);

    constructor(address _platformTreasury) {
        require(_platformTreasury != address(0), "Invalid treasury");
        platformTreasury = _platformTreasury;

        // Deploy bonding curve implementation
        bondingCurveImpl = address(new BondingCurve(address(this)));
    }

    /**
     * @dev Create a new circle with token and bonding curve
     * @param name Circle name
     * @param symbol Token symbol
     * @param description Circle description
     * @param curveType Type of bonding curve
     * @param basePrice Base price for the curve
     * @param param1 Curve parameter 1 (slope/growthRate)
     * @param param2 Curve parameter 2
     * @param param3 Curve parameter 3
     */
    function createCircle(
        string calldata name,
        string calldata symbol,
        string calldata description,
        BondingCurve.CurveType curveType,
        uint256 basePrice,
        uint256 param1,
        uint256 param2,
        uint256 param3
    ) external payable whenNotPaused nonReentrant returns (uint256) {
        require(msg.value >= circleCreationFee, "Insufficient fee");
        require(bytes(name).length > 0 && bytes(name).length <= 50, "Invalid name");
        require(bytes(symbol).length > 0 && bytes(symbol).length <= 10, "Invalid symbol");
        require(
            ownerCircles[msg.sender].length < MAX_CIRCLES_PER_USER,
            "Max circles reached"
        );
        require(basePrice > 0, "Invalid base price");

        uint256 circleId = ++circleCount;

        // Deploy new token
        CircleToken token = new CircleToken(
            name,
            symbol,
            msg.sender,
            address(this),
            bondingCurveImpl,
            platformTreasury,
            circleId
        );

        address tokenAddress = address(token);

        // Initialize bonding curve
        BondingCurve(payable(bondingCurveImpl)).initializeCurve(
            tokenAddress,
            curveType,
            basePrice,
            param1,
            param2,
            param3
        );

        // Store circle data
        circles[circleId] = Circle({
            circleId: circleId,
            owner: msg.sender,
            tokenAddress: tokenAddress,
            bondingCurveAddress: bondingCurveImpl,
            name: name,
            symbol: symbol,
            createdAt: block.timestamp,
            active: true,
            curveType: curveType
        });

        ownerCircles[msg.sender].push(circleId);
        isCircleToken[tokenAddress] = true;

        // Update metadata
        token.updateMetadata(description, "");

        // Transfer creation fee to treasury
        (bool success, ) = platformTreasury.call{value: msg.value}("");
        require(success, "Fee transfer failed");

        emit CircleCreated(
            circleId,
            msg.sender,
            tokenAddress,
            name,
            symbol,
            curveType
        );

        return circleId;
    }

    /**
     * @dev Get circle details
     */
    function getCircle(uint256 circleId) external view returns (Circle memory) {
        return circles[circleId];
    }

    /**
     * @dev Get circles owned by an address
     */
    function getOwnerCircles(address owner) external view returns (uint256[] memory) {
        return ownerCircles[owner];
    }

    /**
     * @dev Deactivate a circle
     */
    function deactivateCircle(uint256 circleId) external {
        Circle storage circle = circles[circleId];
        require(circle.owner == msg.sender, "Not circle owner");
        require(circle.active, "Already inactive");

        circle.active = false;
        emit CircleDeactivated(circleId);
    }

    /**
     * @dev Reactivate a circle
     */
    function reactivateCircle(uint256 circleId) external {
        Circle storage circle = circles[circleId];
        require(circle.owner == msg.sender, "Not circle owner");
        require(!circle.active, "Already active");

        circle.active = true;
        emit CircleReactivated(circleId);
    }

    /**
     * @dev Transfer circle ownership
     */
    function transferCircleOwnership(uint256 circleId, address newOwner) external {
        require(newOwner != address(0), "Invalid new owner");
        Circle storage circle = circles[circleId];
        require(circle.owner == msg.sender, "Not circle owner");

        address oldOwner = circle.owner;
        circle.owner = newOwner;

        // Update owner circles mappings
        uint256[] storage oldOwnerCircles = ownerCircles[oldOwner];
        for (uint256 i = 0; i < oldOwnerCircles.length; i++) {
            if (oldOwnerCircles[i] == circleId) {
                oldOwnerCircles[i] = oldOwnerCircles[oldOwnerCircles.length - 1];
                oldOwnerCircles.pop();
                break;
            }
        }

        ownerCircles[newOwner].push(circleId);

        emit CircleOwnershipTransferred(circleId, oldOwner, newOwner);
    }

    /**
     * @dev Update circle creation fee
     */
    function updateCircleCreationFee(uint256 newFee) external onlyOwner {
        require(newFee <= 1 ether, "Fee too high");
        circleCreationFee = newFee;
        emit CircleCreationFeeUpdated(newFee);
    }

    /**
     * @dev Update platform treasury
     */
    function updatePlatformTreasury(address newTreasury) external onlyOwner {
        require(newTreasury != address(0), "Invalid treasury");
        platformTreasury = newTreasury;
    }

    /**
     * @dev Pause circle creation
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause circle creation
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Get all active circles (paginated)
     */
    function getActiveCircles(
        uint256 offset,
        uint256 limit
    ) external view returns (Circle[] memory) {
        require(limit <= 100, "Limit too high");

        uint256 activeCount = 0;
        for (uint256 i = 1; i <= circleCount; i++) {
            if (circles[i].active) activeCount++;
        }

        uint256 resultCount = activeCount > offset ? activeCount - offset : 0;
        if (resultCount > limit) resultCount = limit;

        Circle[] memory result = new Circle[](resultCount);
        uint256 index = 0;
        uint256 skipped = 0;

        for (uint256 i = 1; i <= circleCount && index < resultCount; i++) {
            if (circles[i].active) {
                if (skipped >= offset) {
                    result[index] = circles[i];
                    index++;
                } else {
                    skipped++;
                }
            }
        }

        return result;
    }

    /**
     * @dev Get platform statistics
     */
    function getStatistics()
        external
        view
        returns (uint256 totalCircles, uint256 activeCircles, uint256 totalValue)
    {
        totalCircles = circleCount;

        for (uint256 i = 1; i <= circleCount; i++) {
            if (circles[i].active) {
                activeCircles++;
                CircleToken token = CircleToken(payable(circles[i].tokenAddress));
                totalValue += token.reserveBalance();
            }
        }
    }

    /**
     * @dev Emergency withdraw
     */
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = owner().call{value: balance}("");
        require(success, "Withdrawal failed");
    }

    receive() external payable {}
}
