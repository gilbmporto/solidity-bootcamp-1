const ethers = require("ethers");

const voteOption = 3; // Example vote option
const secret = "mySecret231"; // Voter's secret
const voteHash = generateVoteHash(voteOption, secret);

const voteOption2 = 2;
const secret2 = "mySecret456";
const voteHash2 = generateVoteHash(voteOption2, secret2);

function generateVoteHash(voteOption, secret) {
  return ethers.utils.solidityKeccak256(
    ["uint", "string"], // Types of the elements
    [voteOption, secret] // Values of the elements
  );
}

console.log(`Vote Hash of Player 1: ${voteHash}`);
console.log(`Vote Hash of Player 2: ${voteHash2}`);
