const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");

describe("Lock", function () {
  async function deployProxyContractFixture() {
    const [owner] = await ethers.getSigners();

    const ProxyContract = await ethers.getContractFactory("Proxy");
    const LogicContract = await ethers.getContractFactory("logicContract");
    const proxyContract = await ProxyContract.deploy(LogicContract, 12);
    return { proxyContract, owner };
  }

  describe("Deployment", function () {
    it("Should set the right value", async function () {
      const { proxyContract } = await loadFixture(deployProxyContractFixture);

      expect(await proxyContract.value()).to.equal(12);
    });
  });
});
