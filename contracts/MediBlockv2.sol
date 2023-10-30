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
  return value: 3 string array, list of string of title, date and link Index of emergency records
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
        counter++;
      }
      recordTitles[counter] = "-";
      recordDates[counter] = "-";
      counter++;
    }
    //"p1","p2","-","p3","p4","-"
    return (recordTitles, recordDates, linkIndices);
  }
  /*
  Description : To access records by doctors
  can be called by doctors
  arguments:  patient address
  return value: 3 string array, list of string of title, date and link index of emergency records
  */
  function getAllRecordsWithAccess(address _patient) public view isDoctor(msg.sender) returns(string[] memory,string[] memory,uint[] memory){
    // updateAcessList(_patient);
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
    // console.log("Total records: ");
    // console.log(totalRecords);
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
          // console.log("Inside doctor: ");
          // console.log(patient.records[i][j].title);
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
  Description : Add new records to existing link
  can be called by doctors
  arguments:  patient address, linkIndex, record data
  */
  function addNewRecord(address _patient,uint linkIndex,string memory _title,string memory _date,string memory _data) public isPatient(_patient) isDoctor(msg.sender){
    IterableMappingPatient.Patient storage patient = patients.get(_patient);
    uint recordIndex = patient.records[linkIndex].length;
    // console.log(recordIndex);
    patient.records[linkIndex].push();
    patient.records[linkIndex][recordIndex].creator = msg.sender;
    patient.records[linkIndex][recordIndex].title = _title;
    patient.records[linkIndex][recordIndex].date = _date;
    patient.records[linkIndex][recordIndex].data = _data; 
    // console.log(patient.records[linkIndex].length);
  }

  /*
  Description : Creating new link
  can be called by doctors
  arguments:  patient address
  */
  function addNewLink(address _patient) public isPatient(_patient) isDoctor(msg.sender){
    IterableMappingPatient.Patient storage patient = patients.get(_patient);
    uint linkIndex = patient.linkLength;
    patient.linkLength++;
    giveAccess(_patient, linkIndex, msg.sender, 10000);
  }

  /*
  Description : To give access
  called internally or by patient
  arguments:  patient address, linkIndex
  */  
  function giveAccess(address _patient,uint linkIndex,address _addr,uint _seconds) public isPatient(_patient){
    IterableMappingPatient.Patient storage patient = patients.get(_patient);
    uint accessIndex = patient.access[linkIndex].length;
    patient.access[linkIndex].push();
    patient.access[linkIndex][accessIndex].addr = _addr;
    uint accessTime = block.timestamp;
    accessTime += _seconds;
    patient.access[linkIndex][accessIndex].time = accessTime;
    // console.log("Access List Length: ");
    // console.log(patient.access[linkIndex].length);
    
  }

  /*
  Description : Revoke access
  called patient
  arguments:  patient address, linkIndex
  */
  function revokeAccess(address _patient,uint linkIndex, address _addr) public isPatient(_patient){
    IterableMappingPatient.Patient storage patient = patients.get(_patient);
    uint accessListLen = patient.access[linkIndex].length;
    for(uint i = 0; i < accessListLen; i++){
      if(patient.access[linkIndex][i].addr == _addr){
        patient.access[linkIndex][i] = patient.access[linkIndex][accessListLen-1];
        patient.access[linkIndex].pop();
        break;
      }
    }
  }

  /*
  Description : Update accesslist
  called system internally
  arguments:  patient address, linkIndex
  */
  function updateAcessList(address _patient) internal isPatient(_patient){
    IterableMappingPatient.Patient storage patient = patients.get(_patient);
    uint linkLength = patient.linkLength;
    // console.log("Link Lenght: ");
    // console.log(linkLength);
    for(uint i = 0; i < linkLength; i++){
      uint accessListLen = patient.access[i].length;
      // console.log("Access List Length: ");
      // console.log(accessListLen);
      for(uint j = 0; j < accessListLen; j++){
        // console.log("Time: ");
        // console.log(patient.access[i][j].time);
        // console.log(block.timestamp);
        if(patient.access[i][j].time < block.timestamp){
          // console.log("here");
          patient.access[i][j] = patient.access[i][accessListLen-1];
          delete patient.access[i][accessListLen-1];
          j--;
          accessListLen--;
        }
      }
    }
  }


  /*
  Description : Get patient Info
  can be called by anyone
  arguments:  patient address
  return value: string, patient info
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
  Description : To remove record from emergency records
  can be called by patient
  arguments:  Emeregency record index
  */
  function removeEmergencyRecord(uint index) public isPatient(msg.sender){
    IterableMappingPatient.Patient storage patient = patients.get(msg.sender);
    uint len = patient.emergencyRecords.length;
    patient.emergencyRecords[index] = patient.emergencyRecords[len-1];
    patient.emergencyRecords.pop();
    len = patient.emergencyRecords.length;
  }

  /*
  Description : Get all emergency records related to a patient
  can be called by patient
  arguments:  patient address
  return value: 3 string array, list of string of title, date and data of emergency records
  */
  function getEmergencyRecords(address _patient) public view isPatient(_patient) returns(string[] memory, string[] memory, string[] memory){
    IterableMappingPatient.Patient storage patient = patients.get(msg.sender);
    uint len = patient.emergencyRecords.length;
    string[] memory titleList = new string[](len);
    string[] memory dateList = new string[](len);
    string[] memory dataList = new string[](len);
    for(uint i = 0; i < len; i++){
      titleList[i] = patient.emergencyRecords[i].title;
      dateList[i] = patient.emergencyRecords[i].date;
      dataList[i] = patient.emergencyRecords[i].data;
    }
    return (titleList, dateList, dataList);
  }

  /*
  Description : To book appointment of doctors
  can be called by patient
  arguments:  doctor address
  */
  function bookAppointment(address _doctor) public isPatient(msg.sender) isDoctor(_doctor){
    IterableMappingDoctor.Doctor storage doctor = doctors.get(_doctor);
    IterableMappingPatient.Patient storage patient = patients.get(msg.sender);
    patient.appointedDoctors.push(_doctor);
    doctor.appointments.push(msg.sender);
  }

  /*
  Description : To delete appointment of doctors
  can be called by patient
  arguments:  doctor address
  */
  function deleteAppointment(address _doctor) public isPatient(msg.sender) isDoctor(_doctor){
    IterableMappingDoctor.Doctor storage doctor = doctors.get(_doctor);
    IterableMappingPatient.Patient storage patient = patients.get(msg.sender);
    uint len = doctor.appointments.length;
    for(uint i = 0; i < len; i++){
      if(doctor.appointments[i] == msg.sender){
        doctor.appointments[i] = doctor.appointments[len-1];
        doctor.appointments.pop();
        break;
      }
    }
    len = patient.appointedDoctors.length;
    for(uint i = 0; i < len; i++){
      if(patient.appointedDoctors[i] == _doctor){
        patient.appointedDoctors[i] = patient.appointedDoctors[len-1];
        patient.appointedDoctors.pop();
        break;
      }
    }
  }

  /*
  Description : Get all list of doctors who are not appointed to a patient (for Booking of appointment)
  can be called by patients
  arguments:  null
  return value: string array, list of addresses of all not appointed doctors
  */
  function getNotAppointedDoctorList() public view isPatient(msg.sender) returns(address[] memory){
    uint len = doctors.size();
    IterableMappingPatient.Patient storage patient = patients.get(msg.sender);
    uint patientAppointmentList = patient.appointedDoctors.length;
    uint totalDoctors = 0; 
    for(uint i = 0; i < len; i++){
      address addr =  doctors.getKeyAtIndex(i);
      bool flag = true;
      for(uint j = 0; j < patientAppointmentList; j++){
        if(patient.appointedDoctors[j] == addr){
          flag = false;
          break;
        }
      }
      if(flag)  totalDoctors++;
    }
    address[] memory addressList = new address[](totalDoctors);
    uint counter = 0;
    for(uint i = 0; i < len; i++){
      address addr =  doctors.getKeyAtIndex(i);
      bool flag = true;
      for(uint j = 0; j < patientAppointmentList; j++){
        if(patient.appointedDoctors[j] == addr){
          flag = false;
          break;
        }
      }
      if(flag){
        addressList[counter] = addr;
        counter++;
      }
    }
    return addressList;
  }

  /*
  Description : Get list of appointed doctors
  can be called by patients
  arguments:  null
  return value: string array, list of addresses of appointed doctors
  */
  function getAppointedDoctorList() public view isPatient(msg.sender) returns(address[] memory){
    IterableMappingPatient.Patient storage patient = patients.get(msg.sender);
    uint len = patient.appointedDoctors.length;
    address[] memory appointedDoctorList = new address[](len);
    for(uint i = 0; i < len; i++){
      appointedDoctorList[i] = patient.appointedDoctors[i];
      // console.log(getDoctorInfo(appointedDoctorList[i]));
    }
    return appointedDoctorList;
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
  Description : Get information related to doctor
  can be called by doctors
  arguments:  doctor address
  return value: string, doctor info
  */
  function getDoctorInfo(address _doctor) public view isDoctor(_doctor) returns(string memory){
    IterableMappingDoctor.Doctor storage doctor = doctors.get(_doctor);
    return doctor.info;
  }

  /*
  Description : Get list of patients who appointed the doctor
  can be called by doctors
  arguments:  null
  return value: list of addresses of appointed patients
  */
  function getPatientList() public view isDoctor(msg.sender) returns(address[] memory){
    IterableMappingDoctor.Doctor storage doctor = doctors.get(msg.sender);
    uint totalPatients = doctor.appointments.length;
    address[] memory patientList = new address[](totalPatients);
    for(uint i = 0; i < totalPatients; i++){
      patientList[i] = doctor.appointments[i];
    }
    return patientList;
  }

  /*
  Description : Get all list of patients (for Emergency Records)
  can be called by doctors
  arguments:  null
  return value: string array, list of addresses of all patients
  */
  function getAllPatientList() public view isDoctor(msg.sender) returns(address[] memory){
    uint len = patients.size();
    address[] memory addressList = new address[](len);
    for(uint i = 0; i < len; i++){
      addressList[i] = patients.getKeyAtIndex(i);
    }
    return addressList;
  }

  

}