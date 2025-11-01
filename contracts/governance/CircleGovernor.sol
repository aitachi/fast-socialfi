// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title CircleGovernor
 * @dev Decentralized governance for circles
 * @notice Token holders can create proposals and vote on circle decisions
 */
contract CircleGovernor is ReentrancyGuard {
    enum ProposalState {
        Pending,    // Proposal created, voting not started
        Active,     // Voting in progress
        Succeeded,  // Passed quorum and majority
        Defeated,   // Failed to pass
        Queued,     // Passed and queued for execution
        Executed,   // Successfully executed
        Cancelled,  // Cancelled by proposer or admin
        Expired     // Voting period expired
    }

    enum VoteType {
        Against,
        For,
        Abstain
    }

    struct Proposal {
        uint256 proposalId; // Unique proposal ID
        address proposer; // Proposal creator
        string title; // Proposal title
        string description; // Detailed description
        address[] targets; // Target contracts for execution
        uint256[] values; // ETH values for each call
        bytes[] calldatas; // Function call data
        uint256 createdAt; // Creation timestamp
        uint256 votingStarts; // Voting start time
        uint256 votingEnds; // Voting end time
        uint256 executionDelay; // Delay before execution (timelock)
        uint256 executeAfter; // Earliest execution time
        uint256 forVotes; // Total votes for
        uint256 againstVotes; // Total votes against
        uint256 abstainVotes; // Total abstain votes
        ProposalState state; // Current state
        bool executed; // Execution status
        mapping(address => bool) hasVoted; // User => voted status
        mapping(address => VoteType) votes; // User => vote type
        uint256 requiredQuorum; // Required quorum for this proposal
    }

    // Circle configuration
    address public circleToken; // Circle's governance token
    address public circleOwner; // Circle owner
    address public treasury; // Circle treasury for funding proposals

    // Governance parameters
    uint256 public votingDelay = 1 days; // Delay before voting starts
    uint256 public votingPeriod = 7 days; // Voting duration
    uint256 public proposalThreshold = 100 * 1e18; // Min tokens to create proposal (1% of typical supply)
    uint256 public quorumPercentage = 400; // 4% quorum (basis points)
    uint256 public executionDelay = 2 days; // Timelock delay
    uint256 public constant PERCENTAGE_PRECISION = 10000;

    // Proposal tracking
    mapping(uint256 => Proposal) public proposals;
    mapping(address => uint256) public latestProposalIds; // User => latest proposal ID
    uint256 public proposalCount;

    // Statistics
    uint256 public totalProposalsCreated;
    uint256 public totalProposalsExecuted;
    uint256 public totalVotes;

    // Events
    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed proposer,
        string title,
        uint256 votingStarts,
        uint256 votingEnds
    );

    event VoteCast(
        uint256 indexed proposalId,
        address indexed voter,
        VoteType voteType,
        uint256 weight
    );

    event ProposalQueued(
        uint256 indexed proposalId,
        uint256 executeAfter
    );

    event ProposalExecuted(
        uint256 indexed proposalId
    );

    event ProposalCancelled(
        uint256 indexed proposalId
    );

    event GovernanceParametersUpdated(
        uint256 votingDelay,
        uint256 votingPeriod,
        uint256 proposalThreshold,
        uint256 quorumPercentage
    );

    /**
     * @dev Constructor
     * @param _circleToken Address of circle token
     * @param _circleOwner Address of circle owner
     * @param _treasury Address of circle treasury
     */
    constructor(
        address _circleToken,
        address _circleOwner,
        address _treasury
    ) {
        require(_circleToken != address(0), "Invalid token");
        require(_circleOwner != address(0), "Invalid owner");
        require(_treasury != address(0), "Invalid treasury");

        circleToken = _circleToken;
        circleOwner = _circleOwner;
        treasury = _treasury;
    }

    /**
     * @dev Create a new proposal
     * @param title Short title
     * @param description Detailed description
     * @param targets Target contract addresses
     * @param values ETH values for each call
     * @param calldatas Function call data
     * @return Proposal ID
     */
    function propose(
        string memory title,
        string memory description,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas
    ) external returns (uint256) {
        require(
            IERC20(circleToken).balanceOf(msg.sender) >= proposalThreshold,
            "Below proposal threshold"
        );
        require(targets.length == values.length, "Targets/values length mismatch");
        require(targets.length == calldatas.length, "Targets/calldatas length mismatch");
        require(targets.length > 0, "Must provide actions");
        require(bytes(title).length > 0, "Empty title");

        uint256 proposalId = proposalCount++;

        Proposal storage proposal = proposals[proposalId];
        proposal.proposalId = proposalId;
        proposal.proposer = msg.sender;
        proposal.title = title;
        proposal.description = description;
        proposal.targets = targets;
        proposal.values = values;
        proposal.calldatas = calldatas;
        proposal.createdAt = block.timestamp;
        proposal.votingStarts = block.timestamp + votingDelay;
        proposal.votingEnds = proposal.votingStarts + votingPeriod;
        proposal.executionDelay = executionDelay;
        proposal.state = ProposalState.Pending;
        proposal.executed = false;

        // Calculate required quorum based on current supply
        uint256 totalSupply = IERC20(circleToken).totalSupply();
        proposal.requiredQuorum = (totalSupply * quorumPercentage) / PERCENTAGE_PRECISION;

        latestProposalIds[msg.sender] = proposalId;
        totalProposalsCreated++;

        emit ProposalCreated(
            proposalId,
            msg.sender,
            title,
            proposal.votingStarts,
            proposal.votingEnds
        );

        return proposalId;
    }

    /**
     * @dev Cast a vote on a proposal
     * @param proposalId ID of the proposal
     * @param voteType Vote type (For, Against, Abstain)
     */
    function castVote(
        uint256 proposalId,
        VoteType voteType
    ) external nonReentrant {
        require(proposalId < proposalCount, "Invalid proposal");
        Proposal storage proposal = proposals[proposalId];

        require(block.timestamp >= proposal.votingStarts, "Voting not started");
        require(block.timestamp <= proposal.votingEnds, "Voting ended");
        require(!proposal.hasVoted[msg.sender], "Already voted");

        uint256 weight = IERC20(circleToken).balanceOf(msg.sender);
        require(weight > 0, "No voting power");

        // Update proposal state if needed
        if (proposal.state == ProposalState.Pending) {
            proposal.state = ProposalState.Active;
        }

        // Record vote
        proposal.hasVoted[msg.sender] = true;
        proposal.votes[msg.sender] = voteType;

        // Update vote counts
        if (voteType == VoteType.For) {
            proposal.forVotes += weight;
        } else if (voteType == VoteType.Against) {
            proposal.againstVotes += weight;
        } else {
            proposal.abstainVotes += weight;
        }

        totalVotes++;

        emit VoteCast(proposalId, msg.sender, voteType, weight);
    }

    /**
     * @dev Queue a successful proposal for execution
     * @param proposalId ID of the proposal
     */
    function queue(uint256 proposalId) external {
        require(proposalId < proposalCount, "Invalid proposal");
        Proposal storage proposal = proposals[proposalId];

        require(
            state(proposalId) == ProposalState.Succeeded,
            "Proposal not succeeded"
        );

        proposal.state = ProposalState.Queued;
        proposal.executeAfter = block.timestamp + proposal.executionDelay;

        emit ProposalQueued(proposalId, proposal.executeAfter);
    }

    /**
     * @dev Execute a queued proposal
     * @param proposalId ID of the proposal
     */
    function execute(uint256 proposalId) external payable nonReentrant {
        require(proposalId < proposalCount, "Invalid proposal");
        Proposal storage proposal = proposals[proposalId];

        require(
            state(proposalId) == ProposalState.Queued,
            "Proposal not queued"
        );
        require(
            block.timestamp >= proposal.executeAfter,
            "Timelock not expired"
        );
        require(!proposal.executed, "Already executed");

        proposal.executed = true;
        proposal.state = ProposalState.Executed;

        // Execute all actions
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            (bool success, ) = proposal.targets[i].call{value: proposal.values[i]}(
                proposal.calldatas[i]
            );
            require(success, "Execution failed");
        }

        totalProposalsExecuted++;

        emit ProposalExecuted(proposalId);
    }

    /**
     * @dev Cancel a proposal (only proposer or circle owner)
     * @param proposalId ID of the proposal
     */
    function cancel(uint256 proposalId) external {
        require(proposalId < proposalCount, "Invalid proposal");
        Proposal storage proposal = proposals[proposalId];

        require(
            msg.sender == proposal.proposer || msg.sender == circleOwner,
            "Not authorized"
        );
        require(
            proposal.state != ProposalState.Executed,
            "Cannot cancel executed proposal"
        );

        proposal.state = ProposalState.Cancelled;

        emit ProposalCancelled(proposalId);
    }

    /**
     * @dev Get current state of a proposal
     * @param proposalId ID of the proposal
     * @return Current state
     */
    function state(uint256 proposalId) public view returns (ProposalState) {
        require(proposalId < proposalCount, "Invalid proposal");
        Proposal storage proposal = proposals[proposalId];

        if (proposal.state == ProposalState.Executed) {
            return ProposalState.Executed;
        }

        if (proposal.state == ProposalState.Cancelled) {
            return ProposalState.Cancelled;
        }

        if (proposal.state == ProposalState.Queued) {
            return ProposalState.Queued;
        }

        if (block.timestamp < proposal.votingStarts) {
            return ProposalState.Pending;
        }

        if (block.timestamp <= proposal.votingEnds) {
            return ProposalState.Active;
        }

        // Voting ended, determine outcome
        uint256 totalVotesCount = proposal.forVotes + proposal.againstVotes + proposal.abstainVotes;

        if (totalVotesCount < proposal.requiredQuorum) {
            return ProposalState.Defeated; // Didn't reach quorum
        }

        if (proposal.forVotes > proposal.againstVotes) {
            return ProposalState.Succeeded;
        } else {
            return ProposalState.Defeated;
        }
    }

    /**
     * @dev Check if user has voted on a proposal
     * @param proposalId ID of the proposal
     * @param voter Address of the voter
     * @return True if voted
     */
    function hasVoted(uint256 proposalId, address voter) external view returns (bool) {
        require(proposalId < proposalCount, "Invalid proposal");
        return proposals[proposalId].hasVoted[voter];
    }

    /**
     * @dev Get vote details for a user
     * @param proposalId ID of the proposal
     * @param voter Address of the voter
     * @return Vote type
     */
    function getVote(uint256 proposalId, address voter) external view returns (VoteType) {
        require(proposalId < proposalCount, "Invalid proposal");
        return proposals[proposalId].votes[voter];
    }

    /**
     * @dev Get proposal details
     * @param proposalId ID of the proposal
     * @return proposer Address of proposer
     * @return title Proposal title
     * @return description Proposal description
     * @return forVotes For votes count
     * @return againstVotes Against votes count
     * @return abstainVotes Abstain votes count
     * @return votingStarts Voting start time
     * @return votingEnds Voting end time
     * @return currentState Current proposal state
     */
    function getProposal(uint256 proposalId) external view returns (
        address proposer,
        string memory title,
        string memory description,
        uint256 forVotes,
        uint256 againstVotes,
        uint256 abstainVotes,
        uint256 votingStarts,
        uint256 votingEnds,
        ProposalState currentState
    ) {
        require(proposalId < proposalCount, "Invalid proposal");
        Proposal storage proposal = proposals[proposalId];

        return (
            proposal.proposer,
            proposal.title,
            proposal.description,
            proposal.forVotes,
            proposal.againstVotes,
            proposal.abstainVotes,
            proposal.votingStarts,
            proposal.votingEnds,
            state(proposalId)
        );
    }

    /**
     * @dev Get proposal actions
     * @param proposalId ID of the proposal
     * @return targets Target addresses
     * @return values ETH values
     * @return calldatas Call data
     */
    function getProposalActions(uint256 proposalId) external view returns (
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas
    ) {
        require(proposalId < proposalCount, "Invalid proposal");
        Proposal storage proposal = proposals[proposalId];

        return (proposal.targets, proposal.values, proposal.calldatas);
    }

    /**
     * @dev Update governance parameters (only circle owner)
     * @param _votingDelay New voting delay
     * @param _votingPeriod New voting period
     * @param _proposalThreshold New proposal threshold
     * @param _quorumPercentage New quorum percentage
     */
    function updateGovernanceParameters(
        uint256 _votingDelay,
        uint256 _votingPeriod,
        uint256 _proposalThreshold,
        uint256 _quorumPercentage
    ) external {
        require(msg.sender == circleOwner, "Only circle owner");
        require(_votingPeriod > 0, "Invalid voting period");
        require(_quorumPercentage <= 5000, "Quorum too high"); // Max 50%

        votingDelay = _votingDelay;
        votingPeriod = _votingPeriod;
        proposalThreshold = _proposalThreshold;
        quorumPercentage = _quorumPercentage;

        emit GovernanceParametersUpdated(
            _votingDelay,
            _votingPeriod,
            _proposalThreshold,
            _quorumPercentage
        );
    }

    /**
     * @dev Get governance statistics
     * @return totalProposals Total proposals created
     * @return executedProposals Total proposals executed
     * @return totalVotesCast Total votes cast
     */
    function getGovernanceStats() external view returns (
        uint256 totalProposals,
        uint256 executedProposals,
        uint256 totalVotesCast
    ) {
        return (totalProposalsCreated, totalProposalsExecuted, totalVotes);
    }

    /**
     * @dev Receive ETH for treasury
     */
    receive() external payable {}
}
