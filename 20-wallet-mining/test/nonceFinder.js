const { ethers } = require("ethers");

const TARGET = "0xCe07CF30B540Bb84ceC5dA5547e1cb4722F9E496";
const FACTORY = "0xF62849F9A0B5Bf2913b396098F7c7019b51A820a";
const SAFE_IMPL = "0x5991A2dF15A8F6A256D3Ec51E99254Cd3fb576A9";
const OWNER = "0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf";

// Safe setup data
const setupData = ethers.utils.defaultAbiCoder.encode(
  [
    "address[]",
    "uint256",
    "address",
    "bytes",
    "address",
    "address",
    "uint256",
    "address",
  ],
  [
    [OWNER],
    1,
    ethers.constants.AddressZero,
    "0x",
    ethers.constants.AddressZero,
    ethers.constants.AddressZero,
    0,
    ethers.constants.AddressZero,
  ]
);

const initHash = ethers.utils.keccak256(setupData);

// SafeProxy creation code + constructor args
const deploymentData = ethers.utils.concat([
  "0x608060405234801561001057600080fd5b506040516101e63803806101e68339818101604052602081101561003357600080fd5b8101908080519060200190929190505050600073ffffffffffffffffffffffffffffffffffffffff168173ffffffffffffffffffffffffffffffffffffffff1614156100ca576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004018080602001828103825260248152602001806101c26024913960400191505060405180910390fd5b806000806101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055505060ab806101196000396000f3fe608060405273ffffffffffffffffffffffffffffffffffffffff600054167fa619486e0000000000000000000000000000000000000000000000000000000060003514156050578060005260206000f35b3660008037600080366000845af43d6000803e60008114156070573d6000fd5b3d6000f3fea264697066735822122003d1488ee65e08fa41e58e888a9865554c535f2bb3c7f2df2e69e63d6962729b64736f6c634300060c0033",
  ethers.utils.defaultAbiCoder.encode(["address"], [SAFE_IMPL]),
]);

const initCodeHash = ethers.utils.keccak256(deploymentData);

for (let i = 0; i < 10000000; i++) {
  const salt = ethers.utils.keccak256(
    ethers.utils.defaultAbiCoder.encode(["bytes32", "uint256"], [initHash, i])
  );
  const addr = ethers.utils.getCreate2Address(FACTORY, salt, initCodeHash);

  if (addr === TARGET) {
    console.log("NONCE:", i);
    process.exit(0);
  }

  if (i % 100000 === 0) console.log("Checked:", i);
}
