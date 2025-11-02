// Author: Aitachi
// Email: 44158892@qq.com
// Date: 11-02-2025 17

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title Governance
 * @dev DAO Governance contract for SocialFi Platform
 *
 * Features:
 * - Proposal creation (requires minimum token balance)
 * - Voting mechanism (1 token = 1 vote)
 * - Proposal execution with timelock
 * - Treasury management
 * - Multiple proposal types
 * - Vote delegation
 */
contract Governance is Ownable, ReentrancyGuard {

    // SOCIAL token
    IERC20 public socialToken;

    // Governance parameters
    uint256 public proposalThreshold = 100000 * 10**18; // 100k tokens to create proposal
    uint256 public votingPeriod = 3 days;
    uint256 public timelockPeriod = 2 days;
    uint256 public quorumPercentage = 1000; // 10% in basis points

    // Proposal types
    enum ProposalType {
        ParameterChange,
        ContractUpgrade,
        TreasurySpend,
        FeatureToggle
    }

    // Proposal status
    enum ProposalStatus {
        Pending,
        Active,
        Succeeded,
        Defeated,
        Queued,
        Executed,
        Cancelled
    }

    // Proposal structure
    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        ProposalType proposalType;
        uint256 startTime;
        uint256 endTime;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 abstainVotes;
        ProposalStatus status;
        bool executed;
        uint256 executionTime;
        bytes callData;
        address targetContract;
    }

    // Vote receipt
    struct Receipt {
        bool hasVoted;
        uint8 support; // 0 = against, 1 = for, 2 = abstain
        uint256 votes;
    }

    // Proposals
    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => Receipt)) public receipts;

    // Vote delegation
    mapping(address => address) public delegates;
    mapping(address => uint256) public votingPower;

    // Treasury
    uint256 public treasuryBalance;

    // Events
    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed proposer,
        string description,
        ProposalType proposalType,
        uint256 startTime,
        uint256 endTime
    );
    event VoteCast(
        address indexed voter,
        uint256 indexed proposalId,
        uint8 support,
        uint256 votes
    );
    event ProposalQueued(uint256 indexed proposalId, uint256 executionTime);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCancelled(uint256 indexed proposalId);
    event VoteDelegated(address indexed delegator, address indexed delegatee);
    event TreasuryFunded(uint256 amount);
    event TreasurySpent(address indexed recipient, uint256 amount, string purpose);
    event ParametersUpdated(string parameter, uint256 newValue);

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
     * @dev Create a new proposal
     * @param description Proposal description
     * @param proposalType Type of proposal
     * @param targetContract Target contract address (if applicable)
     * @param callData Call data for execution (if applicable)
     * @return proposalId The ID of the created proposal
     */
    function propose(
        string memory description,
        ProposalType proposalType,
        address targetContract,
        bytes memory callData
    ) external returns (uint256) {
        require(
            socialToken.balanceOf(msg.sender) >= proposalThreshold,
            "Insufficient tokens to propose"
        );
        require(bytes(description).length > 0, "Empty description");

        proposalCount++;
        uint256 proposalId = proposalCount;

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            description: description,
            proposalType: proposalType,
            startTime: block.timestamp,
            endTime: block.timestamp + votingPeriod,
            forVotes: 0,
            againstVotes: 0,
            abstainVotes: 0,
            status: ProposalStatus.Active,
            executed: false,
            executionTime: 0,
            callData: callData,
            targetContract: targetContract
        });

        emit ProposalCreated(
            proposalId,
            msg.sender,
            description,
            proposalType,
            block.timestamp,
            block.timestamp + votingPeriod
        );

        return proposalId;
    }

    /**
     * @dev Cast a vote on a proposal
     * @param proposalId Proposal ID
     * @param support Vote type (0 = against, 1 = for, 2 = abstain)
     */
    function castVote(uint256 proposalId, uint8 support) external nonReentrant {
        require(proposalId > 0 && proposalId <= proposalCount, "Invalid proposal ID");
        require(support <= 2, "Invalid vote type");

        Proposal storage proposal = proposals[proposalId];
        require(proposal.status == ProposalStatus.Active, "Proposal not active");
        require(block.timestamp <= proposal.endTime, "Voting period ended");

        Receipt storage receipt = receipts[proposalId][msg.sender];
        require(!receipt.hasVoted, "Already voted");

        uint256 votes = getVotes(msg.sender);
        require(votes > 0, "No voting power");

        // Record vote
        receipt.hasVoted = true;
        receipt.support = support;
        receipt.votes = votes;

        // Update proposal votes
        if (support == 0) {
            proposal.againstVotes += votes;
        } else if (support == 1) {
            proposal.forVotes += votes;
        } else {
            proposal.abstainVotes += votes;
        }

        emit VoteCast(msg.sender, proposalId, support, votes);
    }

    /**
     * @dev Queue a successful proposal for execution
     * @param proposalId Proposal ID
     */
    function queue(uint256 proposalId) external {
        require(proposalId > 0 && proposalId <= proposalCount, "Invalid proposal ID");

        Proposal storage proposal = proposals[proposalId];
        require(proposal.status == ProposalStatus.Active, "Proposal not active");
        require(block.timestamp > proposal.endTime, "Voting period not ended");

        // Check if proposal succeeded
        uint256 totalVotes = proposal.forVotes + proposal.againstVotes + proposal.abstainVotes;
        uint256 quorum = (socialToken.totalSupply() * quorumPercentage) / 10000;

        require(totalVotes >= quorum, "Quorum not reached");
        require(proposal.forVotes > proposal.againstVotes, "Proposal defeated");

        proposal.status = ProposalStatus.Queued;
        proposal.executionTime = block.timestamp + timelockPeriod;

        emit ProposalQueued(proposalId, proposal.executionTime);
    }

    /**
     * @dev Execute a queued proposal
     * @param proposalId Proposal ID
     */
    function execute(uint256 proposalId) external nonReentrant {
        require(proposalId > 0 && proposalId <= proposalCount, "Invalid proposal ID");

        Proposal storage proposal = proposals[proposalId];
        require(proposal.status == ProposalStatus.Queued, "Proposal not queued");
        require(block.timestamp >= proposal.executionTime, "Timelock not expired");
        require(!proposal.executed, "Already executed");

        proposal.executed = true;
        proposal.status = ProposalStatus.Executed;

        // Execute proposal based on type
        if (proposal.proposalType == ProposalType.TreasurySpend) {
            _executeTreasurySpend(proposal);
        } else if (proposal.proposalType == ProposalType.ContractUpgrade) {
            _executeContractCall(proposal);
        }

        emit ProposalExecuted(proposalId);
    }

    /**
     * @dev Cancel a proposal (only proposer or owner)
     * @param proposalId Proposal ID
     */
    function cancel(uint256 proposalId) external {
        require(proposalId > 0 && proposalId <= proposalCount, "Invalid proposal ID");

        Proposal storage proposal = proposals[proposalId];
        require(
            msg.sender == proposal.proposer || msg.sender == owner(),
            "Not authorized"
        );
        require(!proposal.executed, "Already executed");

        proposal.status = ProposalStatus.Cancelled;

        emit ProposalCancelled(proposalId);
    }

    /**
     * @dev Delegate voting power
     * @param delegatee Address to delegate votes to
     */
    function delegate(address delegatee) external {
        require(delegatee != address(0), "Invalid delegatee");
        require(delegatee != msg.sender, "Cannot delegate to self");

        address previousDelegate = delegates[msg.sender];

        // Update delegation
        delegates[msg.sender] = delegatee;

        // Update voting power
        uint256 voterBalance = socialToken.balanceOf(msg.sender);

        if (previousDelegate != address(0)) {
            votingPower[previousDelegate] -= voterBalance;
        }

        votingPower[delegatee] += voterBalance;

        emit VoteDelegated(msg.sender, delegatee);
    }

    /**
     * @dev Get voting power for an address
     * @param account Address to check
     * @return Voting power
     */
    function getVotes(address account) public view returns (uint256) {
        // If delegated, return 0
        if (delegates[account] != address(0)) {
            return 0;
        }

        // Own balance + delegated votes
        return socialToken.balanceOf(account) + votingPower[account];
    }

    /**
     * @dev Fund the treasury
     */
    function fundTreasury(uint256 amount) external {
        require(amount > 0, "Amount must be > 0");
        require(
            socialToken.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );

        treasuryBalance += amount;
        emit TreasuryFunded(amount);
    }

    /**
     * @dev Get proposal state
     * @param proposalId Proposal ID
     * @return ProposalStatus
     */
    function state(uint256 proposalId) public view returns (ProposalStatus) {
        require(proposalId > 0 && proposalId <= proposalCount, "Invalid proposal ID");
        return proposals[proposalId].status;
    }

    /**
     * @dev Get proposal details
     * @param proposalId Proposal ID
     * @return Proposal struct
     */
    function getProposal(uint256 proposalId) external view returns (Proposal memory) {
        require(proposalId > 0 && proposalId <= proposalCount, "Invalid proposal ID");
        return proposals[proposalId];
    }

    /**
     * @dev Update governance parameters (only owner)
     * @param parameter Parameter name
     * @param value New value
     */
    function updateParameter(string memory parameter, uint256 value) external onlyOwner {
        bytes32 paramHash = keccak256(bytes(parameter));

        if (paramHash == keccak256(bytes("proposalThreshold"))) {
            proposalThreshold = value;
        } else if (paramHash == keccak256(bytes("votingPeriod"))) {
            votingPeriod = value;
        } else if (paramHash == keccak256(bytes("timelockPeriod"))) {
            timelockPeriod = value;
        } else if (paramHash == keccak256(bytes("quorumPercentage"))) {
            require(value <= 10000, "Invalid percentage");
            quorumPercentage = value;
        } else {
            revert("Invalid parameter");
        }

        emit ParametersUpdated(parameter, value);
    }

    /**
     * @dev Internal function to execute treasury spend
     * @param proposal Proposal struct
     */
    function _executeTreasurySpend(Proposal storage proposal) internal {
        // Decode call data to get recipient and amount
        (address recipient, uint256 amount, string memory purpose) = abi.decode(
            proposal.callData,
            (address, uint256, string)
        );

        require(treasuryBalance >= amount, "Insufficient treasury balance");

        treasuryBalance -= amount;
        require(socialToken.transfer(recipient, amount), "Transfer failed");

        emit TreasurySpent(recipient, amount, purpose);
    }

    /**
     * @dev Internal function to execute contract call
     * @param proposal Proposal struct
     */
    function _executeContractCall(Proposal storage proposal) internal {
        require(proposal.targetContract != address(0), "Invalid target");

        (bool success,) = proposal.targetContract.call(proposal.callData);
        require(success, "Contract call failed");
    }

    /**
     * @dev Receive ETH for treasury
     */
    receive() external payable {
        // Accept ETH donations to treasury
    }
}
