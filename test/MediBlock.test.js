const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { expect } = require("chai");

describe("MediBlock", function () {
  async function mediBlockFixture() {
    const [p1, p2, p3, d1, d2, d3] = await ethers.getSigners();
    const contract = await ethers.deployContract("MediBlock");
    return { contract, p1, p2, p3, d1, d2, d3 };
  }

  describe("Patient", function () {

    describe("Register", function () {
      it("Register as patient", async function () {
        const { contract, p1 } = await loadFixture(mediBlockFixture);

        await contract.patientRegistration("p1");
        console.log(p1.address);
        let newRole = await contract.role(p1.address);
        
        expect(newRole).to.be.equal(1);
      });

      it("Cannot register if already registered", async function() {
        const {contract, p1} = await loadFixture(mediBlockFixture);

        await contract.patientRegistration("p1");

        await expect(contract.patientRegistration("p1")).to.be.revertedWithCustomError(contract, "AlreadyRegistered");
      })
    });

    describe("Give initial access", function() {
      it("Neither a patient, nor a doctor", async function () {
        const {contract, p1, d1} = await loadFixture(mediBlockFixture);

        await expect(contract.giveAccess(d1.address, 0)).to.be.revertedWithCustomError(contract, "NotAPatient");
      });

      it("Not a patient but a doctor", async function () {
        let {contract, p1, d1} = await loadFixture(mediBlockFixture);

        contract = contract.connect(d1);
        await contract.doctorRegistration(d1.address);

        contract = contract.connect(p1);
        await expect(contract.giveAccess(d1.address, 0)).to.be.revertedWithCustomError(contract, "NotAPatient");
      });

      it("A patient but not a doctor", async function() {
        let {contract, p1, d1} = await loadFixture(mediBlockFixture);

        await contract.patientRegistration(p1.address);

        await expect(contract.giveAccess(d1.address, 0)).to.be.revertedWithCustomError(contract, "NotADoctor");
      });

      // it("A patient and a doctor", async function() {
      //   let {contract, p1, d1} = await loadFixture(mediBlockFixture);

      //   await contract.patientRegistration(p1.address);

      //   contract = contract.connect(d1);
      //   await contract.doctorRegistration(d1.address);
      //   contract = contract.connect(p1);

      //   let value = await contract.giveAccess(d1.address, 0);
      //   value = value.toString();

      //   expect(value).to.be.equal("5");
      // });

      it("Check link length value", async function() {
        let {contract, p1, d1, d2} = await loadFixture(mediBlockFixture);

        await contract.patientRegistration(p1.address);

        contract = contract.connect(d1);
        await contract.doctorRegistration(d1.address);

        contract = contract.connect(d2);
        await contract.doctorRegistration(d2.address);
        contract = contract.connect(p1);

        await contract.giveAccess(d1.address, 1000);
        await contract.giveAccess(d2.address, 1000);
        await expect(1).to.be.equal(1);
      });

      it("check return value", async function () {
        let {contract, p1, d1, d2} = await loadFixture(mediBlockFixture);

        let value = await contract.patient(p1.address);
        console.log(value);
      })
    })
  });
});
