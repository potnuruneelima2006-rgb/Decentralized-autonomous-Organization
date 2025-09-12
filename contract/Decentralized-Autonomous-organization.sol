// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Decentralized Autonomous Organization (DAO)
 * @dev A smart contract implementing core DAO functionality with governance features
 * @author DAO Development Team
 */
contract Project {
    // State variables
    struct Proposal {
        uint256 id;
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 endTime;
        bool executed;
        address proposer;
        mapping(address => bool) hasVoted;
    }

    struct Member {
        bool isActive;
        uint256 votingPower;
        uint256 joinedAt;
    }

    mapping(address => Member) public members;
    mapping(uint256 => Proposal) public proposals;
    
    address public owner;
    uint256 public totalMembers;
    uint256 public proposalCount;
    uint256 public constant VOTING_DURATION = 7 days;
    uint256 public constant MIN_VOTING_POWER = 1;
    
    // Events
    event MemberAdded(address indexed member, uint256 votingPower);
    event MemberRemoved(address indexed member);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender].isActive, "Only active members can call this function");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId < proposalCount, "Proposal does not exist");
        _;
    }

    // Constructor
    constructor() {
        owner = msg.sender;
        // Add owner as first member with maximum voting power
        members[owner] = Member({
            isActive: true,
            votingPower: 100,
            joinedAt: block.timestamp
        });
        totalMembers = 1;
        
        emit MemberAdded(owner, 100);
    }

    /**
     * @dev Core Function 1: Add Member
     * @notice Adds a new member to the DAO with specified voting power
     * @param _member Address of the new member
     * @param _votingPower Voting power to assign to the member (minimum 1)
     */
    function addMember(address _member, uint256 _votingPower) external onlyOwner {
        require(_member != address(0), "Invalid member address");
        require(!members[_member].isActive, "Member already exists");
        require(_votingPower >= MIN_VOTING_POWER, "Voting power must be at least 1");

        members[_member] = Member({
            isActive: true,
            votingPower: _votingPower,
            joinedAt: block.timestamp
        });
        
        totalMembers++;
        emit MemberAdded(_member, _votingPower);
    }

    /**
     * @dev Core Function 2: Create Proposal
     * @notice Creates a new proposal for DAO members to vote on
     * @param _description Description of the proposal
     * @return proposalId The ID of the created proposal
     */
    function createProposal(string memory _description) external onlyMember returns (uint256) {
        require(bytes(_description).length > 0, "Proposal description cannot be empty");

        uint256 proposalId = proposalCount;
        Proposal storage newProposal = proposals[proposalId];
        
        newProposal.id = proposalId;
        newProposal.description = _description;
        newProposal.votesFor = 0;
        newProposal.votesAgainst = 0;
        newProposal.endTime = block.timestamp + VOTING_DURATION;
        newProposal.executed = false;
        newProposal.proposer = msg.sender;

        proposalCount++;
        
        emit ProposalCreated(proposalId, msg.sender, _description);
        return proposalId;
    }

    /**
     * @dev Core Function 3: Vote on Proposal
     * @notice Allows DAO members to vote on active proposals
     * @param _proposalId ID of the proposal to vote on
     * @param _support True for voting in favor, false for voting against
     */
    function vote(uint256 _proposalId, bool _support) external onlyMember proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        
        require(block.timestamp < proposal.endTime, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Member has already voted");
        require(!proposal.executed, "Proposal has already been executed");

        proposal.hasVoted[msg.sender] = true;
        uint256 votingPower = members[msg.sender].votingPower;

        if (_support) {
            proposal.votesFor += votingPower;
        } else {
            proposal.votesAgainst += votingPower;
        }

        emit VoteCast(_proposalId, msg.sender, _support, votingPower);
    }

    // Additional utility functions

    /**
     * @dev Execute a proposal if it has passed
     * @param _proposalId ID of the proposal to execute
     */
    function executeProposal(uint256 _proposalId) external proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        
        require(block.timestamp >= proposal.endTime, "Voting period is still active");
        require(!proposal.executed, "Proposal has already been executed");
        require(proposal.votesFor > proposal.votesAgainst, "Proposal did not pass");

        proposal.executed = true;
        
        emit ProposalExecuted(_proposalId);
    }

    /**
     * @dev Remove a member from the DAO
     * @param _member Address of the member to remove
     */
    function removeMember(address _member) external onlyOwner {
        require(_member != owner, "Cannot remove owner");
        require(members[_member].isActive, "Member is not active");

        members[_member].isActive = false;
        totalMembers--;
        
        emit MemberRemoved(_member);
    }

    /**
     * @dev Get proposal details
     * @param _proposalId ID of the proposal
     * @return id, description, votesFor, votesAgainst, endTime, executed, proposer
     */
    function getProposal(uint256 _proposalId) external view proposalExists(_proposalId) 
        returns (uint256, string memory, uint256, uint256, uint256, bool, address) {
        Proposal storage proposal = proposals[_proposalId];
        return (
            proposal.id,
            proposal.description,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.endTime,
            proposal.executed,
            proposal.proposer
        );
    }

    /**
     * @dev Check if an address is an active member
     * @param _member Address to check
     * @return bool indicating if the address is an active member
     */
    function isMember(address _member) external view returns (bool) {
        return members[_member].isActive;
    }

    /**
     * @dev Get member information
     * @param _member Address of the member
     * @return isActive, votingPower, joinedAt
     */
    function getMember(address _member) external view returns (bool, uint256, uint256) {
        Member storage member = members[_member];
        return (member.isActive, member.votingPower, member.joinedAt);
    }
}
