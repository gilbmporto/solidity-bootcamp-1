// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract DecentralizedVotingSystem {

    address public owner;
    uint public id;
    uint public votes;
    bool public electionEnded;

    struct Candidate {
        uint id;
        address candidateAddress;
        string name;
        uint voteCount;
        bool isWinner;
    }

    mapping(uint => Candidate) public idToCandidates;
    mapping(address => bool) public voted;

    Candidate private winnerCandidate;

    event NewCandidateInserted(uint id, address indexed candidateAddress, string name);
    event NewVoteHappened(uint candidateID, address indexed voter);
    event WinnerWasAnnounced(uint candidateID, address indexed candidateAddress, string candidateName, uint voteCount);

    constructor(address _owner) {
        owner = _owner;
        id = 0;
        votes = 0;
        electionEnded = false;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function addNewCandidate(address _address, string memory _name) public onlyOwner {
        require(msg.sender != _address, "Owner of the contract cannot be a candidate");
        
        // Make sure that we cannot insert the same address twice
        if (id > 0) {
            for (uint i = 0; i < id; i++) {
                if (_address == idToCandidates[i].candidateAddress) {
                    revert("Cannot insert the same address twice");
                }
            }
        }

        idToCandidates[id] = Candidate(id, _address, _name, 0, false);
        emit NewCandidateInserted(id, _address, _name);
        id++;
    }

    function vote(uint _id) public {
        require(voted[msg.sender] == false, "You already voted");
        require(_id < id, "This candidate does not exist");

         // Check if the voter is a candidate
        for (uint i = 0; i < id; i++) {
            require(msg.sender != idToCandidates[i].candidateAddress, "Candidates cannot vote");
        }

        idToCandidates[_id].voteCount += 1;

        // A person may only vote once
        voted[msg.sender] = true;
        
        // Increment votes
        votes++;

        emit NewVoteHappened(_id, msg.sender);
    }

    function declareWinner() public onlyOwner returns(Candidate memory) {
        require(id >= 3, "Not enough candidates to declare a winner");
        require(votes >= 5, "Not enough number of votes to declare a winner");
        require(electionEnded == false, "Election already happened");

        winnerCandidate = idToCandidates[0];

        // Check for ties
        bool isTie = false;

        for (uint i = 1; i < id; i++) {
            if (winnerCandidate.voteCount < idToCandidates[i].voteCount) {
                winnerCandidate = idToCandidates[i];
                isTie = false;
            } else if (winnerCandidate.voteCount == idToCandidates[i].voteCount) {
                isTie = true;
            }
        }

        require(!isTie, "Election is tied, cannot declare a winner");

        // Set isWinner to true in order to getWinnerCandidate() function to work properly
        winnerCandidate.isWinner = true;

        // Set electionEnded variable to true in order to be able to reset the contract
        electionEnded = true;

        emit WinnerWasAnnounced(winnerCandidate.id, winnerCandidate.candidateAddress, winnerCandidate.name, winnerCandidate.voteCount);
        return winnerCandidate;
    }

    function resetElection() public onlyOwner returns(bool) {
        require(electionEnded == true, "Election is not finished yet");

        for (uint i = 0; i < id; i++) {
            delete idToCandidates[i];
        }

        delete winnerCandidate;
        id = 0;
        votes = 0;
        electionEnded = false;

        return true;
    }

    // Getters

    function getNumberOfVotes(uint _id) public view returns(uint) {
        return idToCandidates[_id].voteCount;
    }

    function getWinnerCandidate() public view returns(Candidate memory) {
        require(winnerCandidate.candidateAddress != address(0) && winnerCandidate.isWinner == true, "There is no winner yet");
        return winnerCandidate;
    }

}