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
      
      it("Book Appointment if doctor address is not registered", async function () {
        let { contract, p1, d1 } = await loadFixture(mediblockv2fixture);
        await contract.patientRegistration("p1");
        await expect(contract.bookAppointment(d1.address)).to.be.revertedWithCustomError(contract, "NotADoctor");
      })
    })
    describe("Patient Info", function() {
      it("Checking patient info of registered patient", async function(){
        let {contract, p1} = await loadFixture(mediblockv2fixture);
        await contract.patientRegistration("p1");
        let patientInfo = await contract.getPatientInfo(p1.address);
        expect(patientInfo).to.be.equal("p1");
      })
      it("Checking patient info of unregistered patient", async function(){
        let {contract, p1} = await loadFixture(mediblockv2fixture);
        await expect(contract.getPatientInfo(p1.address)).to.be.revertedWithCustomError(contract, "NotAPatient");
      })
    })
  })


  describe("Doctor", function() {
    describe("Add Records", function() {
      it("Adding new link", async function () {
        let { contract, p1, d1 } = await loadFixture(mediblockv2fixture);
        await contract.patientRegistration("p1");
        contract = contract.connect(d1);
        await contract.doctorRegistration("d1");
        contract = contract.connect(p1);
        await contract.bookAppointment(d1.address);
        contract = contract.connect(d1);
        let patientList = await contract.getPatientList();
        await contract.addNewLink(patientList[0]);
        contract = contract.connect(p1);
        let {0: titleList, 1: dateList, 2:indicesList} = await contract.getAllRecords();
        console.log(titleList);
        console.log(dateList);
        console.log(indicesList);
        expect(indicesList.length).to.be.equal(1);
      })

      it("Adding new record to an existing link", async function () {
        let { contract, p1, d1 } = await loadFixture(mediblockv2fixture);
        await contract.patientRegistration("p1");
        contract = contract.connect(d1);
        await contract.doctorRegistration("d1");
        contract = contract.connect(p1);
        await contract.bookAppointment(d1.address);
        contract = contract.connect(d1);
        let patientList = await contract.getPatientList();
        await contract.addNewLink(patientList[0]);
        contract = contract.connect(p1);
        let {0: ptitleList, 1: pdateList, 2:pindicesList} = await contract.getAllRecords();
        contract = contract.connect(d1);
        await contract.addNewRecord(patientList[0],pindicesList[0],"Skin Disease","29-10-2023","Peanut allergy");
        let {0: dtitleList, 1: ddateList, 2: dindicesList} = await contract.getAllRecordsWithAccess(patientList[0]);
        console.log(dtitleList);
        console.log(ddateList);
        console.log(dindicesList);
      })


    })

    
  })

})