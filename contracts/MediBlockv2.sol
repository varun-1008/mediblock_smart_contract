// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
pragma abicoder v2;

import { IterableMappingPatient, IterableMappingDoctor } from "./IterableMapping.sol";
import "hardhat/console.sol";

error AlreadyRegistered(address);
error NotADoctor(address);
error NotAPatient(address);
error NotAPathologist(address);
error NotADoctorOrPathologist(address);
error NoWriteAccess(address patient, uint linkIndex, address writer);
error NoReadAccess(address patient, uint linkIndex, uint recordIndex, address reader);
error IndexOutOfBound(uint linkIndex);

contract MediBlockv2 {
  using IterableMappingPatient for IterableMappingPatient.Map;
  using IterableMappingDoctor for IterableMappingDoctor.Map;
  IterableMappingPatient.Map patients;
  IterableMappingDoctor.Map doctors;

  enum Role {None, Patient, Doctor, Pathologist}

  mapping(address => Role) public role;

  modifier isUnregistered {
    if(role[msg.sender] != Role.None)
      revert AlreadyRegistered(msg.sender);
    _;
  }

  modifier isDoctor (address _doctor) {
    if(role[_doctor] != Role.Doctor)
        revert NotADoctor(_doctor);

    _;
  }

  modifier isPatient (address _patient){
    if(role[_patient] != Role.Patient)
        revert NotAPatient(_patient);

    _;
  }

  /*
  Description : To register patients
  can be called by user
  arguments:  patient's info
  */
  function patientRegistration(string memory _info) public isUnregistered {
    role[msg.sender] = Role.Patient;
    patients.set(msg.sender,_info);
  }

  /*
  Description : To access all records
  can be called by patient
  arguments:  null
  */
  function getAllRecords() public isPatient(msg.sender) view returns(string[] memory,string[] memory,uint[] memory){
    IterableMappingPatient.Patient storage patient = patients.get(msg.sender);
    uint linkLength = patient.linkLength;
    uint totalRecords = linkLength;
    for(uint i = 0; i < linkLength; i++)
      totalRecords += patient.records[i].length;

    string[] memory recordTitles = new string[](totalRecords);
    string[] memory recordDates = new string[](totalRecords);
    uint[] memory linkIndices = new uint[](linkLength);
    uint counter = 0;
    for(uint i = 0; i < linkLength; i++){
      uint recordLength = patient.records[i].length;
      linkIndices[i] = i;
      for(uint j = 0; j < recordLength; j++){
        recordTitles[counter] = patient.records[i][j].title;
        recordDates[counter] = patient.records[i][j].date;
        console.log(patient.records[i][j].title);
        console.log(patient.records[i][j].date);
        counter++;
      }
      recordTitles[counter] = "-";
      recordDates[counter] = "-";
      counter++;
    }
    return (recordTitles, recordDates, linkIndices);
  }
  /*
  Description : To access records by doctors
  can be called by doctors
  arguments:  patient address
  */
  function getAllRecordsWithAccess(address _patient) public isDoctor(msg.sender) view returns(string[] memory,string[] memory,uint[] memory){
    IterableMappingPatient.Patient storage patient = patients.get(_patient);
    uint linkLength = patient.linkLength;
    uint totalRecords = 0;
    uint indicesCount = 0;
    for(uint i = 0; i < linkLength; i++){
      uint recordLength = patient.records[i].length;
      uint accessListLength = patient.access[i].length;
      bool flag = false;
      for(uint j = 0; j < accessListLength; j++){
        if(patient.access[i][j].addr == msg.sender){
          flag = true;
          break;
        }
      }
      if(flag){
        totalRecords += recordLength;
        totalRecords++;
        indicesCount++;
      }
    }
    string[] memory recordTitles = new string[](totalRecords);
    string[] memory recordDates = new string[](totalRecords);
    uint[] memory linkIndices = new uint[](indicesCount);
    uint counter = 0;
    uint indexCount = 0;
    for(uint i = 0; i < linkLength; i++){
      uint recordLength = patient.records[i].length;
      uint accessListLength = patient.access[i].length;
      bool flag = false;
      for(uint j = 0; j < accessListLength; j++){
        if(patient.access[i][j].addr == msg.sender){
          flag = true;
          break;
        }
      }
      if(flag){
        for(uint j = 0; j < recordLength; j++){
          recordTitles[counter] = patient.records[i][j].title;
          recordDates[counter] = patient.records[i][j].date;
          counter++;
        }
        recordTitles[counter] = "-";
        recordDates[counter] = "-";
        counter++;
        linkIndices[indexCount] = i;
        indexCount++;
      }
    }
    return (recordTitles, recordDates, linkIndices);
  }
  /*
  Description : Get patient Info
  can be called by anyone
  arguments:  patient address
  */
  function getPatientInfo(address _patient) public view isPatient(_patient) returns(string memory){
    IterableMappingPatient.Patient storage patient = patients.get(_patient);
    return patient.info;
  }

  /*
  Description : To mark record as emergency records
  can be called by patient
  arguments:  linkIndex, recordIndex
  */
  function markAsEmergencyRecord(uint linkIndex,uint recordIndex) public isPatient(msg.sender){
    IterableMappingPatient.Patient storage patient = patients.get(msg.sender);
    uint index = patient.emergencyRecords.length;
    patient.emergencyRecords.push();
    patient.emergencyRecords[index] = patient.records[linkIndex][recordIndex];
  }

  /*
  Description : To book appointment of doctors
  can be called by patient
  arguments:  doctor address
  */
  function bookAppointment(address _doctor) public isPatient(msg.sender) isDoctor(_doctor){
    IterableMappingDoctor.Doctor storage doctor = doctors.get(_doctor);
    doctor.appointments.push(msg.sender);
  }
  /*
  Description : To register doctors
  can be called by user
  arguments:  doctor info
  */
  function doctorRegistration(string memory _info) public isUnregistered {
    role[msg.sender] = Role.Doctor;
    doctors.set(msg.sender,_info);
  }

  /*
  Description : Get list of patients
  can be called by doctors
  arguments:  null
  */
  function getPatientList() public view isDoctor(msg.sender) returns(string[] memory){
    IterableMappingDoctor.Doctor storage doctor = doctors.get(msg.sender);
    uint totalPatients = doctor.appointments.length;
    string[] memory patientList = new string[](totalPatients);
    for(uint i = 0; i < totalPatients; i++){
      patientList[i] = getPatientInfo(doctor.appointments[i]);
    }
    return patientList;
  }


}