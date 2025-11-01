// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title CircleToken
 * @dev ERC20 token for social circles with bonding curve pricing
 * @notice Each circle has its own token that can be bought/sold via bonding curve
 */
contract CircleToken is ERC20, Ownable, Pausable, ReentrancyGuard {
    // Bonding curve parameters
    address public bondingCurve;
    address public factory;
    address public circleOwner;

    // Circle metadata
    string public circleDescription;
    string public circleImage;
    uint256 public circleId;

    // Token economics
    uint256 public reserveBalance; // ETH reserve
    uint256 public transactionFeePercent = 250; // 2.5% (basis points: 250/10000)
    uint256 public constant FEE_DENOMINATOR = 10000;

    // Fee distribution
    uint256 public ownerFeePercent = 6000; // 60% to circle owner
    uint256 public platformFeePercent = 2000; // 20% to platform
    uint256 public liquidityFeePercent = 2000; // 20% to liquidity pool

    address public platformTreasury;

    // Statistics
    uint256 public totalVolume;
    uint256 public totalTransactions;

    // Events
    event TokensPurchased(
        address indexed buyer,
        uint256 amount,
        uint256 cost,
        uint256 fee,
        uint256 newSupply
    );
    event TokensSold(
        address indexed seller,
        uint256 amount,
        uint256 refund,
        uint256 fee,
        uint256 newSupply
    );
    event FeesCollected(uint256 ownerFee, uint256 platformFee, uint256 liquidityFee);
    event MetadataUpdated(string description, string image);
    event TransactionFeeUpdated(uint256 newFee);

    modifier onlyFactory() {
        require(msg.sender == factory, "Only factory can call");
        _;
    }

    modifier onlyCircleOwner() {
        require(msg.sender == circleOwner, "Only circle owner can call");
        _;
    }

    /**
     * @dev Constructor
     * @param name Token name
     * @param symbol Token symbol
     * @param _circleOwner Address of circle owner
     * @param _factory Address of factory contract
     * @param _bondingCurve Address of bonding curve contract
     * @param _platformTreasury Address of platform treasury
     * @param _circleId ID of the circle
     */
    constructor(
        string memory name,
        string memory symbol,
        address _circleOwner,
        address _factory,
        address _bondingCurve,
        address _platformTreasury,
        uint256 _circleId
    ) ERC20(name, symbol) {
        require(_circleOwner != address(0), "Invalid owner");
        require(_factory != address(0), "Invalid factory");
        require(_bondingCurve != address(0), "Invalid bonding curve");
        require(_platformTreasury != address(0), "Invalid treasury");

        circleOwner = _circleOwner;
        factory = _factory;
        bondingCurve = _bondingCurve;
        platformTreasury = _platformTreasury;
        circleId = _circleId;

        // Transfer ownership to factory
        transferOwnership(_factory);

        // Mint initial supply to circle owner (founder tokens)
        _mint(_circleOwner, 1000 * 10 ** decimals());
    }

    /**
     * @dev Update circle metadata
     * @param description New description
     * @param image New image URL/IPFS hash
     */
    function updateMetadata(
        string calldata description,
        string calldata image
    ) external {
        require(
            msg.sender == circleOwner || msg.sender == factory,
            "Only circle owner or factory can update metadata"
        );
        circleDescription = description;
        circleImage = image;
        emit MetadataUpdated(description, image);
    }

    /**
     * @dev Update transaction fee
     * @param newFee New fee in basis points (max 500 = 5%)
     */
    function updateTransactionFee(uint256 newFee) external onlyFactory {
        require(newFee <= 500, "Fee too high");
        transactionFeePercent = newFee;
        emit TransactionFeeUpdated(newFee);
    }

    /**
     * @dev Mint tokens (called by bonding curve during buy)
     * @param to Recipient address
     * @param amount Amount to mint
     */
    function mint(address to, uint256 amount) external onlyFactory nonReentrant {
        _mint(to, amount);
    }

    /**
     * @dev Burn tokens (called by bonding curve during sell)
     * @param from Address to burn from
     * @param amount Amount to burn
     */
    function burn(address from, uint256 amount) external onlyFactory nonReentrant {
        _burn(from, amount);
    }

    /**
     * @dev Add to reserve (called during token purchase)
     * @param amount Amount to add
     */
    function addToReserve(uint256 amount) external payable onlyFactory {
        require(msg.value == amount, "Value mismatch");
        reserveBalance += amount;
    }

    /**
     * @dev Remove from reserve (called during token sale)
     * @param amount Amount to remove
     * @param to Recipient address
     */
    function removeFromReserve(
        uint256 amount,
        address to
    ) external onlyFactory nonReentrant {
        require(reserveBalance >= amount, "Insufficient reserve");
        reserveBalance -= amount;
        (bool success, ) = to.call{value: amount}("");
        require(success, "Transfer failed");
    }

    /**
     * @dev Collect and distribute fees
     * @param totalFee Total fee amount
     */
    function collectFees(uint256 totalFee) external payable onlyFactory {
        require(msg.value == totalFee, "Fee mismatch");

        uint256 ownerFee = (totalFee * ownerFeePercent) / FEE_DENOMINATOR;
        uint256 platformFee = (totalFee * platformFeePercent) / FEE_DENOMINATOR;
        uint256 liquidityFee = (totalFee * liquidityFeePercent) / FEE_DENOMINATOR;

        // Transfer fees
        (bool success1, ) = circleOwner.call{value: ownerFee}("");
        require(success1, "Owner fee transfer failed");

        (bool success2, ) = platformTreasury.call{value: platformFee}("");
        require(success2, "Platform fee transfer failed");

        // Liquidity fee stays in contract
        reserveBalance += liquidityFee;

        emit FeesCollected(ownerFee, platformFee, liquidityFee);
    }

    /**
     * @dev Record transaction statistics
     * @param volume Transaction volume
     */
    function recordTransaction(uint256 volume) external onlyFactory {
        totalVolume += volume;
        totalTransactions++;
    }

    /**
     * @dev Pause token transfers
     */
    function pause() external onlyCircleOwner {
        _pause();
    }

    /**
     * @dev Unpause token transfers
     */
    function unpause() external onlyCircleOwner {
        _unpause();
    }

    /**
     * @dev Get current token price from bonding curve
     * @return price Current price per token in wei
     */
    function getCurrentPrice() external view returns (uint256) {
        // This would call the bonding curve contract
        // Implemented in BondingCurve contract
        return 0; // Placeholder
    }

    /**
     * @dev Override _beforeTokenTransfer to add pause functionality
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    /**
     * @dev Get circle statistics
     * @return holder count, total volume, transaction count, reserve balance
     */
    function getStatistics()
        external
        view
        returns (uint256, uint256, uint256, uint256)
    {
        return (totalSupply(), totalVolume, totalTransactions, reserveBalance);
    }

    /**
     * @dev Emergency withdraw (only factory owner in case of emergency)
     */
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = owner().call{value: balance}("");
        require(success, "Withdrawal failed");
    }

    /**
     * @dev Receive function to accept ETH
     */
    receive() external payable {}
}
