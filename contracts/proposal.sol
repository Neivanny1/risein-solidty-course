// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract ProposalContract {
    address owner;
    uint256 private counter;
    struct Proposal {
        string title; // Title of the proposal
        string description; // Description of the proposal
        uint256 approve; // Number of approve votes
        uint256 reject; // Number of reject votes
        uint256 pass; // Number of pass votes
        uint256 total_vote_to_end; // When the total votes in the proposal reaches this limit, proposal ends
        bool current_state; // This shows the current state of the proposal, meaning whether it passes or fails
        bool is_active; // This shows if others can vote to our contract
    }

    mapping(uint256 => Proposal) proposal_history; // Recordings of previous proposals

    address[]  private voted_addresses;

    constructor() {
        owner = msg.sender;
        voted_addresses.push(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the onwer");
        _;
    }

    modifier active() {
        require(proposal_history[counter].is_active == true, "The proposal is not active");
        _;
    }

    modifier newVoter(address _address) {
        require(!isVoted(_address), "Address has already voted");
        _;
    }

    function setOwner(address new_owner) external onlyOwner{
        owner = new_owner;
    }

        function isVoted(address _address) private view returns (bool) {
        for (uint256 i = 0; i < voted_addresses.length; i++) {
            if (voted_addresses[i] == _address) {
                return true;
            }
        }
        return false;
    }

    function create(string calldata _title, string calldata _description,
    uint256 _total_vote_to_end) external onlyOwner {
        counter += 1;
        proposal_history[counter] = Proposal(_title, _description,
        0, 0, 0, _total_vote_to_end, false, true);
    }
    function vote(uint8 choice) external active newVoter(msg.sender){
    Proposal storage proposal = proposal_history[counter];
    uint256 total_vote = proposal.approve + proposal.reject + proposal.pass;

    voted_addresses.push(msg.sender);

    if (choice == 1) {
        proposal.approve += 1;
        proposal.current_state = calculateCurrentState();
    } else if (choice == 2) {
        proposal.reject += 1;
        proposal.current_state = calculateCurrentState();
    } else if (choice == 0) {
        proposal.pass += 1;
        proposal.current_state = calculateCurrentState();
    }

    if ((proposal.total_vote_to_end - total_vote == 1) && (choice == 1 || choice == 2 || choice == 0)) {
        proposal.is_active = false;
        voted_addresses = [owner];
    }
    }

    function calculateCurrentState() private view returns (bool) {
    Proposal storage proposal = proposal_history[counter];

    uint256 totalVotes = proposal.approve + proposal.reject + proposal.pass;

    if (totalVotes == 0) {
        // No votes cast; return default (consider it failed)
        return false;
    }
    // Check if approve votes make up more than 60% of total votes
    if (proposal.approve * 100 / totalVotes > 60) {
        return true;
    }
    // Check if reject votes make up more than 40% of total votes
    if (proposal.reject * 100 / totalVotes > 40) {
        return false;
    }
    // If neither of the above conditions is met, use pass votes as a tie-breaker
    return proposal.pass % 2 == 0; // Even pass votes favor approval, odd favors rejection
}

}
