require("@nomicfoundation/hardhat-ethers");
require("@openzeppelin/hardhat-upgrades");

const INFURA_SEPOLIA_URL = process.env.SEPOLIA_URL;
const PRIVATE_KEY = process.env.PRIVATE_KEY;

module.exports = {
  solidity: "0.8.22",
  defaultNetwork: "hardhat",
  networks: {},
};
