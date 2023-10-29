const {
    loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { expect } = require("chai");

describe("MediBlockv2", function() {
  async function mediblockv2fixture() {
    const mappingContractPatient = await ethers.deployContract("IterableMappingPatient");
    const mappingContractAddressPatient = await mappingContractPatient.getAddress();
    const mappingContractDoctor = await ethers.deployContract("IterableMappingDoctor");
    const mappingContractAddressDoctor = await mappingContractDoctor.getAddress();
    const [p1, p2, p3, d1, d2, d3] = await ethers.getSigners();
    const contractFactory = await ethers.getContractFactory("MediBlockv2", {
      libraries: {
        IterableMappingPatient: mappingContractAddressPatient,
        IterableMappingDoctor: mappingContractAddressDoctor,
      },
    });

    const contract = await contractFactory.deploy();

    return {contract, p1, p2, p3, d1, d2, d3};
  }

  describe("Registration", function() {
    it("Registering patient", async function () {
      let { contract, p1 } = await loadFixture(mediblockv2fixture);
      await contract.patientRegistration("p1");
      const val = await contract.role(p1.address)
      expect(val).to.be.equal("1");
    })
    it("Doing registration of a registered patient", async function () {
      const { contract, p1 } = await loadFixture(mediblockv2fixture);
      await(contract.patientRegistration("p1"));
      await expect(contract.patientRegistration("p2")).to.be.revertedWithCustomError(contract, "AlreadyRegistered");
    })
    it("Doctor Registration", async function () {
      let { contract, d1 } = await loadFixture(mediblockv2fixture);
      contract = contract.connect(d1);
      await contract.doctorRegistration("d1");
      const val = await contract.role(d1.address);
      expect(val).to.be.equal("2");
    })
  })

  describe("Patient", function() {
    describe("Book Appointment", function() {
      it("Book Appointment", async function () {
        let { contract, p1, d1 } = await loadFixture(mediblockv2fixture);
        await contract.patientRegistration("p1");
        contract = contract.connect(d1);
        await contract.doctorRegistration("d1");
        contract = contract.connect(p1);
        await contract.bookAppointment(d1.address);
        contract = contract.connect(d1);
        let patientList = await contract.getPatientList();
        expect(patientList.length).to.be.equal(1);
      })

      it("Book Appointment if sender is not a patient", async function () {
        let { contract, p1, d1 } = await loadFixture(mediblockv2fixture);
        contract = contract.connect(d1);
        await contract.doctorRegistration("d1");
        contract = contract.connect(p1);
        await expect(contract.bookAppointment(d1.address)).to.be.revertedWithCustomError(contract, "NotAPatient");
      })
    })
  })

})