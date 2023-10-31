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
      it("Getting list of all doctors who are not appointed by patient", async function () {
        let { contract, p1, d1, d2 } = await loadFixture(mediblockv2fixture);
        contract = contract.connect(d1);
        await contract.doctorRegistration("d1");
        contract = contract.connect(d2)
        await contract.doctorRegistration("d2");
        contract = contract.connect(p1);
        await contract.patientRegistration("p1");
        let doctorList = await contract.getNotAppointedDoctors();
        expect(doctorList.length).to.be.equal(2);
        expect(doctorList[0]).to.be.equal(d1.address);
      })

      it("Booking Appointment", async function () {
        let { contract, p1, d1 } = await loadFixture(mediblockv2fixture);
        await contract.patientRegistration("p1");
        contract = contract.connect(d1);
        await contract.doctorRegistration("d1");
        contract = contract.connect(p1);
        await contract.addAppointment(d1.address);
        contract = contract.connect(d1);
        let patientList = await contract.getAppointedPatients();
        expect(patientList.length).to.be.equal(1);
      })

      it("Book Appointment if sender is not a patient", async function () {
        let { contract, p1, d1 } = await loadFixture(mediblockv2fixture);
        contract = contract.connect(d1);
        await contract.doctorRegistration("d1");
        contract = contract.connect(p1);
        await expect(contract.addAppointment(d1.address)).to.be.revertedWithCustomError(contract, "NotAPatient");
      })
      
      it("Book Appointment if doctor address is not registered", async function () {
        let { contract, p1, d1 } = await loadFixture(mediblockv2fixture);
        await contract.patientRegistration("p1");
        await expect(contract.addAppointment(d1.address)).to.be.revertedWithCustomError(contract, "NotADoctor");
      })

      it("Getting list of all doctors who are appointed by patient", async function () {
        let { contract, p1, d1, d2 } = await loadFixture(mediblockv2fixture);
        contract = contract.connect(d1);
        await contract.doctorRegistration("d1");
        contract = contract.connect(d2)
        await contract.doctorRegistration("d2");
        contract = contract.connect(p1);
        await contract.patientRegistration("p1");
        await contract.addAppointment(d1.address);
        await contract.addAppointment(d2.address);
        let doctorList = await contract.getAppointedDoctors();
        expect(doctorList.length).to.be.equal(2);
        expect(doctorList[0]).to.be.equal(d1.address);
      })

      it("Deleting Appointment", async function () {
        let { contract, p1, d1} = await loadFixture(mediblockv2fixture);
        contract = contract.connect(d1);
        await contract.doctorRegistration("d1");
        contract = contract.connect(p1);
        await contract.patientRegistration("p1");
        await contract.addAppointment(d1.address);
        await contract.removeAppointment(d1.address);
        let appointedDoctorList = await contract.getAppointedDoctors();
        let notAppointedDoctorList = await contract.getNotAppointedDoctors();
        expect(appointedDoctorList.length).to.be.equal(0);
        expect(notAppointedDoctorList.length).to.be.equal(1);
        expect(notAppointedDoctorList[0]).to.be.equal(d1.address);
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
    describe("Granting/Revoking access by patient",function(){
      it("Giving access to doctors for a particular link",async function(){
        let {contract, p1, d1, d2} = await loadFixture(mediblockv2fixture);
        await contract.patientRegistration("p1");
        contract = contract.connect(d1);
        await contract.doctorRegistration("d1");
        contract = contract.connect(d2);
        await contract.doctorRegistration("d2");
        contract = contract.connect(p1);
        await contract.addAppointment(d1.address);
        contract = contract.connect(d1);
        let patientList = await contract.getAppointedPatients();
        await contract.addRecordNewLink(patientList[0],"Skin Disease","29-10-2023","Peanut allergy");
        await contract.addRecordNewLink(patientList[0],"Skin Disease","29-10-2023","Peanut allergy");
        contract = contract.connect(d1);
        await contract.addRecordExistingLink(patientList[0],0,"Skin Disease","29-10-2023","Peanut allergy");
        await contract.addRecordExistingLink(patientList[0],1,"Pulmonary Disease","29-10-2023","Difficulty in breathing");
        contract = contract.connect(p1);
        await contract.giveAccess(p1.address,1,d2.address,1000);
        contract = contract.connect(d2);
        let {0: dtitleList, 1: ddateList, 2: dindicesList} = await contract.getRecordsWithAccess(p1.address);
        expect(dindicesList.length).to.be.equal(2);
      })
      it("Revoking access from doctors for a particular link",async function(){
        let {contract, p1, d1, d2} = await loadFixture(mediblockv2fixture);
        await contract.patientRegistration("p1");
        contract = contract.connect(d1);
        await contract.doctorRegistration("d1");
        contract = contract.connect(d2);
        await contract.doctorRegistration("d2");
        contract = contract.connect(p1);
        await contract.addAppointment(d1.address);
        contract = contract.connect(d1);
        let patientList = await contract.getAppointedPatients();
        await contract.addRecordNewLink(patientList[0],"Skin Disease","29-10-2023","Peanut allergy");
        await contract.addRecordNewLink(patientList[0],"Skin Disease","29-10-2023","Peanut allergy");
        contract = contract.connect(d1);
        await contract.addRecordExistingLink(patientList[0],0,"Skin Disease","29-10-2023","Peanut allergy");
        await contract.addRecordExistingLink(patientList[0],1,"Pulmonary Disease","29-10-2023","Difficulty in breathing");
        contract = contract.connect(p1);
        await contract.giveAccess(p1.address,1,d2.address,1000);
        await contract.giveAccess(p1.address,0,d2.address,1000);
        await contract.revokeAccess(p1.address,1,d2.address);
        contract = contract.connect(d2);
        let {0: dtitleList, 1: ddateList, 2: dindicesList} = await contract.getRecordsWithAccess(p1.address);
        expect(dindicesList.length).to.be.equal(2);
      })
    })

    describe("Emergency Records",function(){
      it("Add Emeregency Records",async function(){
        let {contract, p1, d1, d2} = await loadFixture(mediblockv2fixture);
        await contract.patientRegistration("p1");
        contract = contract.connect(d1);
        await contract.doctorRegistration("d1");
        contract = contract.connect(d2);
        await contract.doctorRegistration("d2");
        contract = contract.connect(p1);
        await contract.addAppointment(d1.address);
        contract = contract.connect(d1);
        let patientList = await contract.getAppointedPatients();
        await contract.addRecordNewLink(patientList[0],"Skin Disease","29-10-2023","Peanut allergy");
        await contract.addRecordNewLink(patientList[0],"Skin Disease","29-10-2023","Peanut allergy");
        contract = contract.connect(d1);
        await contract.addRecordExistingLink(patientList[0],0,"Skin Disease","29-10-2023","Peanut allergy");
        await contract.addRecordExistingLink(patientList[0],1,"Pulmonary Disease","29-10-2023","Difficulty in breathing");
        contract = contract.connect(p1);
        await contract.addEmergencyRecord(0,0);
        let{0: titleList, 1: dateList, 2:dataList} = await contract.getEmergencyRecords(p1.address);
        expect(titleList.length).to.be.equal(1);
        expect(titleList[0]).to.be.equal("Skin Disease");
      })

      it("Remove Emeregency Records",async function(){
        let {contract, p1, d1, d2} = await loadFixture(mediblockv2fixture);
        await contract.patientRegistration("p1");
        contract = contract.connect(d1);
        await contract.doctorRegistration("d1");
        contract = contract.connect(d2);
        await contract.doctorRegistration("d2");
        contract = contract.connect(p1);
        await contract.addAppointment(d1.address);
        contract = contract.connect(d1);
        let patientList = await contract.getAppointedPatients();
        await contract.addRecordNewLink(patientList[0],"Skin Disease","29-10-2023","Peanut allergy");
        await contract.addRecordNewLink(patientList[0],"Skin Disease","29-10-2023","Peanut allergy");
        contract = contract.connect(d1);
        await contract.addRecordExistingLink(patientList[0],0,"Skin Disease","29-10-2023","Peanut allergy");
        await contract.addRecordExistingLink(patientList[0],1,"Pulmonary Disease","29-10-2023","Difficulty in breathing");
        contract = contract.connect(p1);
        await contract.addEmergencyRecord(0,0);
        await contract.addEmergencyRecord(1,0);
        await contract.removeEmergencyRecord(0);
        let{0: titleList, 1: dateList, 2:dataList} = await contract.getEmergencyRecords(p1.address);
        expect(titleList.length).to.be.equal(1);
        expect(titleList[0]).to.be.equal("Skin Disease");
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
        await contract.addAppointment(d1.address);
        contract = contract.connect(d1);
        let patientList = await contract.getAppointedPatients();
        await contract.addRecordNewLink(patientList[0],"Skin Disease","29-10-2023","Peanut allergy");
        contract = contract.connect(p1);
        let {0: titleList, 1: dateList, 2:indicesList} = await contract.getRecords();
        expect(indicesList.length).to.be.equal(1);
      })

      it("Adding new record to an existing link", async function () {
        let { contract, p1, d1 } = await loadFixture(mediblockv2fixture);
        await contract.patientRegistration("p1");
        contract = contract.connect(d1);
        await contract.doctorRegistration("d1");
        contract = contract.connect(p1);
        await contract.addAppointment(d1.address);
        contract = contract.connect(d1);
        let patientList = await contract.getAppointedPatients();
        await contract.addRecordNewLink(patientList[0],"Skin Disease","29-10-2023","Peanut allergy");
        await contract.addRecordNewLink(patientList[0],"Skin Disease","29-10-2023","Peanut allergy");
        contract = contract.connect(p1);
        let {0: ptitleList, 1: pdateList, 2: pindicesList} = await contract.getRecords();
        contract = contract.connect(d1);
        await contract.addRecordExistingLink(patientList[0],pindicesList[0],"Skin Disease","29-10-2023","Peanut allergy");
        await contract.addRecordExistingLink(patientList[0],pindicesList[1],"Pulmonary Disease","29-10-2023","Difficulty in breathing");
        let {0: titleList, 1: dateList, 2: indicesList} = await contract.getRecordsWithAccess(p1.address);
        contract = contract.connect(p1);
        let{0: titles, 1: dates, 2: indices} = await contract.getRecords();
        expect(indices.length).to.be.equal(4);
      })
    })

    describe("Getting Patient List", function() {
      it("Getting patient list registered in our system", async function () {
        let { contract, p1, p2, p3, d1 } = await loadFixture(mediblockv2fixture);
        await contract.patientRegistration("p1");
        contract = contract.connect(p2);
        await contract.patientRegistration("p2");
        contract = contract.connect(p3);
        await contract.patientRegistration("p3");
        contract = contract.connect(d1);
        await contract.doctorRegistration("d1");
        let patientList = await contract.getPatients();
        expect(patientList.length).to.be.equal(3);
        expect(patientList[0]).to.be.equal(p1.address);
      })
      it("Getting appointed patient list for doctor", async function () {
        let { contract, p1, p2, p3, d1 } = await loadFixture(mediblockv2fixture);
        contract = contract.connect(d1);
        await contract.doctorRegistration("d1");
        contract = contract.connect(p1);
        await contract.patientRegistration("p1");
        await contract.addAppointment(d1.address);
        contract = contract.connect(p2);
        await contract.patientRegistration("p2");
        await contract.addAppointment(d1.address);
        contract = contract.connect(p3);
        await contract.patientRegistration("p3");
        contract = contract.connect(d1);
        let patientList = await contract.getAppointedPatients();
        expect(patientList.length).to.be.equal(2);
        expect(patientList[1]).to.be.equal(p2.address);
      })
    })

  })

})