// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract RockPaperScissors {
    enum Game {
        ZERO,
        ROCK,
        PAPER,
        SCISSORS
    }

    address public admin;
    address public player1;
    address public player2;
    address public winner;

    uint public commitPhaseEndTime;
    uint public revealPhaseEndTime;

    mapping(address => Game) public choices;
    mapping(address => bytes32) public choiceCommits;

    event ChoiceCommitted(address player, bytes32 hash);

    modifier onlyAdmin() {
        require(msg.sender == admin, "You're not the admin");
        _;
    }

    constructor(uint _commitDuration, uint _revealDuration) {
        admin = msg.sender;
        commitPhaseEndTime = block.timestamp + _commitDuration;
        revealPhaseEndTime = commitPhaseEndTime + _revealDuration;
    }

    function addPlayer1 (address _player) external onlyAdmin returns(bool) {
        require(block.timestamp < commitPhaseEndTime, "Player must be selected before commitment time");
        require(player1 == address(0), "Player was already chosen");
        player1 = _player;
        choices[player1] = Game.ZERO;
        return true;
    }

    function addPlayer2 (address _player) external onlyAdmin returns(bool) {
        require(block.timestamp < commitPhaseEndTime, "Player must be selected before commitment time");
        require(player2 == address(0), "Player was already chosen");
        player2 = _player;
        choices[player2] = Game.ZERO;
        return true;
    }

    function commitChoice(bytes32 _hashedChoice) external {
        require(block.timestamp < commitPhaseEndTime, "Commit phase is over");
        require(msg.sender == player1 || msg.sender == player2, "You're not one of the players");
        require(choiceCommits[msg.sender] == 0, "Choice already committed");
        choiceCommits[msg.sender] = _hashedChoice;
        emit ChoiceCommitted(msg.sender, _hashedChoice);
    }

    function revealChoice(uint _choice, string memory _secret) external returns(bool) {
        require(block.timestamp > commitPhaseEndTime, "Commit phase not yet ended");
        require(block.timestamp < revealPhaseEndTime, "Reveal phase is over");
        require(msg.sender == player1 || msg.sender == player2, "You're not one of the players");
        require(choiceCommits[msg.sender] != 0, "You haven't committed the choice yet");
        require(choices[msg.sender] == Game.ZERO, "Choice has already been revealed");
        require (_choice > 0 && _choice < 4);

        // Verify vote hash
        bytes32 committedHash = choiceCommits[msg.sender];
        bytes32 revealedHash = keccak256(abi.encodePacked(_choice, _secret));
        
        require(revealedHash == committedHash, "Hash does not match commitment");

        choices[msg.sender] = Game(_choice);
        return true;
    }

    /*
    function makeChoice(Game playerChoice) external returns(bool) {
        require(msg.sender == player1 || msg.sender == player2, "You're not one of the players");
        require (choices[msg.sender] == Game.ZERO, "You've already chosen it");
        choices[msg.sender] = playerChoice;
        return true;
    }
    */

    function pickWinner() external onlyAdmin returns(string memory) {
        require(choices[player1] != Game.ZERO, "Player 1 has not chosen yet");
        require(choices[player2] != Game.ZERO, "Player 2 has not chosen yet");
        require(winner == address(0), "Winner has been picked already");

        // Pick the winner down below...
        Game choicePlayer1 = choices[player1];
        Game choicePlayer2 = choices[player2];

        if (choicePlayer1 == choicePlayer2) {
            winner = address(1);
            return "It's a tie!";
        }

        if ((choicePlayer1 == Game.SCISSORS && choicePlayer2 == Game.PAPER) ||
            (choicePlayer1 == Game.PAPER && choicePlayer2 == Game.ROCK) ||
            (choicePlayer1 == Game.ROCK && choicePlayer2 == Game.SCISSORS)) {
            winner = player1;
            return "Player 1 wins!";
        } else {
            winner = player2;
            return "Player 2 wins!";
        }

    }

    function resetGame(uint _newCommitDuration, uint _newRevealDuration) external onlyAdmin returns(bool) {
        // require(winner != address(0), "The game has not ended yet");
        require(player1 != address(0) || player2 != address(0), "The game hasn't even started yet");
        require(block.timestamp >= commitPhaseEndTime, "Wait for the commit phase to end");
        delete player1;
        delete player2;
        delete choiceCommits[player1];
        delete choiceCommits[player2];
        delete choices[player1];
        delete choices[player2];
        delete winner;

        commitPhaseEndTime = block.timestamp + _newCommitDuration;
        revealPhaseEndTime = commitPhaseEndTime + _newRevealDuration;

        return true;
    }

    function currentTimeStamp() external view returns(uint) {
        return block.timestamp;
    }

}