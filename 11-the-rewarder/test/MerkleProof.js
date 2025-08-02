const { MerkleTree } = require("merkletreejs");
const { keccak256, solidityPacked } = require("ethers");
const { toUtf8Bytes } = require("ethers");

const users = [
  ["0x0000000000000000000000000000000000000001", 100],
  ["0x0000000000000000000000000000000000000002", 200],
  ["0x0000000000000000000000000000000000000003", 300],
  ["0x0000000000000000000000000000000000000004", 400],
];

const leaves = users.map(([addr, amt]) =>
  Buffer.from(
    keccak256(solidityPacked(["address", "uint256"], [addr, amt])).slice(2),
    "hex"
  )
);

const tree = new MerkleTree(leaves, keccak256, { sortPairs: true });

console.log("Merkle Root:", tree.getHexRoot());

const leaf = Buffer.from(
  keccak256(solidityPacked(["address", "uint256"], users[0])).slice(2),
  "hex"
);
console.log("Proof for first user:", tree.getHexProof(leaf));

//  Creating Claim



