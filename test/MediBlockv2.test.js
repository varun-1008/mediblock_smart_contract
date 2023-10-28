const {
    loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { expect } = require("chai");

describe("MediBlockv2", function() {
  async function mediblockv2fixture() {
    const mappingContract = await ethers.deployContract("IterableMappingPatient");
    const mappingContractAddress = await mappingContract.getAddress();

    const [p1, p2, p3, d1, d2, d3] = await ethers.getSigners();
    const contractFactory = await ethers.getContractFactory("MediBlockv2", {
      libraries: {
        IterableMappingPatient: mappingContractAddress,
      },
    });

    const contract = await contractFactory.deploy();

    return {contract, p1, p2, p3, d1, d2, d3};
  }

  describe("Patient", function() {
    it("deploying", async function () {
      const { contract, p1 } = await loadFixture(mediblockv2fixture);

      const val = await contract.patient()

      expect("1").to.be.equal("1");
    })
  })
})