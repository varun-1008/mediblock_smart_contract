// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
pragma abicoder v2;

import {IterableMappingPatient, IterableMappingDoctor} from "./IterableMapping.sol";
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

    enum Role {
        None,
        Patient,
        Doctor,
        Pathologist
    }

    mapping(address => Role) public role;

    modifier isUnregistered() {
        if (role[msg.sender] != Role.None) revert AlreadyRegistered(msg.sender);
        _;
    }

    modifier isDoctor(address _doctor) {
        if (role[_doctor] != Role.Doctor) revert NotADoctor(_doctor);

        _;
    }

    modifier isPatient(address _patient) {
        if (role[_patient] != Role.Patient) revert NotAPatient(_patient);

        _;
    }

    modifier isDoctorOrPathologist(address _address) {
        if (role[_address] != Role.Pathologist && role[_address] != Role.Doctor)
            revert NotADoctorOrPathologist(_address);

        _;
    }

    // ➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖
    // ➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖  Unregistered  ➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖
    // ➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖

    /**
     * @notice to register a patient
     * @dev the information should be an encrypted CID
     * @param _info information about the patient
     */
    function patientRegistration(string memory _info) public isUnregistered {
        role[msg.sender] = Role.Patient;
        patients.set(msg.sender, _info);
    }

    /**
     * @notice to register a doctor
     * @dev the information should be an encrypted CID
     * @param _info information about the doctor
     */
    function doctorRegistration(string memory _info) public isUnregistered {
        role[msg.sender] = Role.Doctor;
        doctors.set(msg.sender, _info);
    }

    // ➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖
    // ➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖  Anyone  ➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖
    // ➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖

    /**
     * @notice to get information about a patient
     * @param _patient patient address
     * @return info the patient information
     */
    function getPatientInfo(address _patient) public view isPatient(_patient) returns (string memory) {
        IterableMappingPatient.Patient storage patient = patients.get(_patient);
        return patient.info;
    }

    /**
     * @notice to get information about the doctor
     * @dev doctor information should be an encrypted CID
     * @param _doctor doctor address
     * @return info information about the doctor
     */
    function getDoctorInfo(address _doctor) public view isDoctor(_doctor) returns (string memory) {
        IterableMappingDoctor.Doctor storage doctor = doctors.get(_doctor);
        return doctor.info;
    }

    /**
     * @notice to give access of a link of records to a doctor or pathologist
     * @param _patient patient address
     * @param linkIndex the link index of the records
     * @param _addr doctor or pathologist address
     * @param _seconds access time in seconds
     */
    function giveAccess(
        address _patient,
        uint linkIndex,
        address _addr,
        uint _seconds
    ) public isPatient(_patient) isDoctorOrPathologist(_addr) {
        IterableMappingPatient.Patient storage patient = patients.get(_patient);
        uint accessIndex = patient.access[linkIndex].length;
        patient.access[linkIndex].push();
        patient.access[linkIndex][accessIndex].addr = _addr;
        uint accessTime = block.timestamp;
        accessTime += _seconds;
        patient.access[linkIndex][accessIndex].time = accessTime;
    }

    /**
     * @notice to revoke access of a link of records to a doctor or pathologist
     * @param _patient patient address
     * @param linkIndex the link index of the records
     * @param _addr doctor or pathologist address
     */
    function revokeAccess(
        address _patient,
        uint linkIndex,
        address _addr
    ) public isPatient(_patient) isDoctorOrPathologist(_addr) {
        IterableMappingPatient.Patient storage patient = patients.get(_patient);
        uint accessListLen = patient.access[linkIndex].length;
        for (uint i = 0; i < accessListLen; i++) {
            if (patient.access[linkIndex][i].addr == _addr) {
                patient.access[linkIndex][i] = patient.access[linkIndex][accessListLen - 1];
                patient.access[linkIndex].pop();
                break;
            }
        }
    }

    /**
     * @notice to get information about a record
     * @param _patient patient address
     * @param linkIndex link index
     * @param recordIndex record index
     * @return title title of the record
     * @return date time of the record
     * @return data content of the record
     */
    function getRecord(address _patient, uint linkIndex, uint recordIndex) public view returns (string memory,string memory, string memory) {
        IterableMappingPatient.Patient storage patient = patients.get(_patient);
        string memory _title = patient.records[linkIndex][recordIndex].title;
        string memory _date = patient.records[linkIndex][recordIndex].date;
        string memory _data = patient.records[linkIndex][recordIndex].data;
        return (_title, _date, _data);
    }

    // ➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖
    // ➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖  Patient  ➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖
    // ➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖

    /**
     * @notice to get the records of a patient
     * @dev the patient address is provided by msg.sender
     * @return recordTitles array
     * @return recordDates array
     * @return linkIndices array
     * @return recordIndices array
     */
    function getRecords()
        public
        view
        isPatient(msg.sender)
        returns (string[] memory, string[] memory, uint[] memory, uint[] memory)
    {
        IterableMappingPatient.Patient storage patient = patients.get(msg.sender);
        uint linkLength = patient.linkLength;
        uint totalRecords = 0;
        for (uint i = 0; i < linkLength; i++) totalRecords += patient.records[i].length;
        string[] memory recordTitles = new string[](totalRecords);
        string[] memory recordDates = new string[](totalRecords);
        uint[] memory linkIndices = new uint[](totalRecords);
        uint[] memory recordIndices = new uint[](totalRecords);
        uint counter = 0;
        for (uint i = 0; i < linkLength; i++) {
            uint recordLength = patient.records[i].length;
            for (uint j = 0; j < recordLength; j++) {
                recordTitles[counter] = patient.records[i][j].title;
                recordDates[counter] = patient.records[i][j].date;
                linkIndices[counter] = i;
                recordIndices[counter] = j;
                counter++;
            }
        }
        return (recordTitles, recordDates, linkIndices, recordIndices);
    }

    /**
     * @notice get list of not appointed doctors
     * @dev patient address is provided by msg.sender
     * @return address array of doctors
     */
    function getNotAppointedDoctors() public view isPatient(msg.sender) returns (address[] memory) {
        uint len = doctors.size();
        IterableMappingPatient.Patient storage patient = patients.get(msg.sender);
        uint patientAppointmentList = patient.appointedDoctors.length;
        uint totalDoctors = 0;
        for (uint i = 0; i < len; i++) {
            address addr = doctors.getKeyAtIndex(i);
            bool flag = true;
            for (uint j = 0; j < patientAppointmentList; j++) {
                if (patient.appointedDoctors[j] == addr) {
                    flag = false;
                    break;
                }
            }
            if (flag) totalDoctors++;
        }
        address[] memory addressList = new address[](totalDoctors);
        uint counter = 0;
        for (uint i = 0; i < len; i++) {
            address addr = doctors.getKeyAtIndex(i);
            bool flag = true;
            for (uint j = 0; j < patientAppointmentList; j++) {
                if (patient.appointedDoctors[j] == addr) {
                    flag = false;
                    break;
                }
            }
            if (flag) {
                addressList[counter] = addr;
                counter++;
            }
        }
        return addressList;
    }

    /**
     * @notice get list of appointed doctors
     * @dev patient address is provided by msg.sender
     * @return address array of doctors
     */
    function getAppointedDoctors() public view isPatient(msg.sender) returns (address[] memory) {
        IterableMappingPatient.Patient storage patient = patients.get(msg.sender);
        uint len = patient.appointedDoctors.length;
        address[] memory appointedDoctorList = new address[](len);
        for (uint i = 0; i < len; i++) {
            appointedDoctorList[i] = patient.appointedDoctors[i];
            // console.log(getDoctorInfo(appointedDoctorList[i]));
        }
        return appointedDoctorList;
    }

    /**
     * @notice to book a doctor appointment
     * @dev patient address is provided by msg.sender
     * @param _doctor doctor address
     */
    function addAppointment(address _doctor) public isPatient(msg.sender) isDoctor(_doctor) {
        IterableMappingDoctor.Doctor storage doctor = doctors.get(_doctor);
        IterableMappingPatient.Patient storage patient = patients.get(msg.sender);
        patient.appointedDoctors.push(_doctor);
        doctor.appointments.push(msg.sender);
    }

    /**
     * @notice to check whether a record is emergency record or not
     * @param linkIndex link index
     * @param recordIndex record index
     * @return flag
     */
    function isEmergencyRecord(uint linkIndex,uint recordIndex) public view isPatient(msg.sender) returns(bool){
        IterableMappingPatient.Patient storage patient = patients.get(msg.sender);
        return patient.records[linkIndex][recordIndex].isEmergency;
    }

    /**
     * @notice to mark a record as an emergency record
     * @param linkIndex link index of the record
     * @param recordIndex record index of the record
     */
    function addEmergencyRecord(uint linkIndex, uint recordIndex) public isPatient(msg.sender) {
        IterableMappingPatient.Patient storage patient = patients.get(msg.sender);
        patient.records[linkIndex][recordIndex].isEmergency = true;
    }

    /**
     * @notice to mark a record as not an emergency record
     * @param linkIndex index of link
     * @param recordIndex index of record
     */
    function removeEmergencyRecord(uint linkIndex,uint recordIndex) public isPatient(msg.sender) {
        IterableMappingPatient.Patient storage patient = patients.get(msg.sender);
        patient.records[linkIndex][recordIndex].isEmergency = false;
    }

    /**
     * @notice get all emergency records of a patient
     * @param _patient patient address
     * @return titleList array
     * @return dateList array
     * @return dataList array
     */
    function getEmergencyRecords(
        address _patient
    ) public view isPatient(_patient) returns (string[] memory, string[] memory, string[] memory) {
        IterableMappingPatient.Patient storage patient = patients.get(msg.sender);
        uint len = 0;
        uint linkLength = patient.linkLength;
        for(uint i = 0; i < linkLength; i++){
            uint recordLen = patient.records[i].length;
            for(uint j = 0; j < recordLen; j++){
                if(patient.records[i][j].isEmergency)   len++;
            }
        }
        string[] memory titleList = new string[](len);
        string[] memory dateList = new string[](len);
        string[] memory dataList = new string[](len);
        uint counter = 0;
        for(uint i = 0; i < linkLength; i++){
            uint recordLen = patient.records[i].length;
            for(uint j = 0; j < recordLen; j++){
                if(patient.records[i][j].isEmergency){
                    titleList[counter] = patient.records[i][j].title;
                    dateList[counter] = patient.records[i][j].date;
                    dataList[counter] = patient.records[i][j].data;
                    counter++;

                }
            }
        }
        return (titleList, dateList, dataList);
    }

    // ➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖
    // ➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖  Doctor  ➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖
    // ➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖

    /**
     * @notice list of patient who have active appointment
     * @dev doctor address is provided by msg.sender
     * @return address array of patients
     */
    function getAppointedPatients() public view isDoctor(msg.sender) returns (address[] memory) {
        IterableMappingDoctor.Doctor storage doctor = doctors.get(msg.sender);
        uint totalPatients = doctor.appointments.length;
        address[] memory patientList = new address[](totalPatients);
        for (uint i = 0; i < totalPatients; i++) {
            patientList[i] = doctor.appointments[i];
        }
        return patientList;
    }

    /**
     * @notice to get the records of a patient the doctor has access
     * @dev the doctor address is provided by msg.sender
     * @param _patient patient address
     * @return recordTitles array
     * @return recordDates array
     * @return linkIndices array
     * @return recordIndices array
     */
    function getRecordsWithAccess(
        address _patient
    ) public view isDoctor(msg.sender) returns (string[] memory, string[] memory, uint[] memory, uint[] memory) {
        // updateAcessList(_patient);
        IterableMappingPatient.Patient storage patient = patients.get(_patient);
        uint linkLength = patient.linkLength;
        uint totalRecords = 0;
        for (uint i = 0; i < linkLength; i++) {
            uint recordLength = patient.records[i].length;
            uint accessListLength = patient.access[i].length;
            bool flag = false;
            for (uint j = 0; j < accessListLength; j++) {
                if (patient.access[i][j].addr == msg.sender) {
                    flag = true;
                    break;
                }
            }
            if (flag) {
                totalRecords += recordLength;
            }
        }
        // console.log("Total records: ");
        // console.log(totalRecords);
        string[] memory recordTitles = new string[](totalRecords);
        string[] memory recordDates = new string[](totalRecords);
        uint[] memory linkIndices = new uint[](totalRecords);
        uint[] memory recordIndices = new uint[](totalRecords);
        uint counter = 0;
        for (uint i = 0; i < linkLength; i++) {
            uint recordLength = patient.records[i].length;
            uint accessListLength = patient.access[i].length;
            bool flag = false;
            for (uint j = 0; j < accessListLength; j++) {
                if (patient.access[i][j].addr == msg.sender) {
                    flag = true;
                    break;
                }
            }
            if (flag) {
                for (uint j = 0; j < recordLength; j++) {
                    recordTitles[counter] = patient.records[i][j].title;
                    recordDates[counter] = patient.records[i][j].date;
                    linkIndices[counter] = i;
                    recordIndices[counter] = j;
                    // console.log("Inside doctor: ");
                    // console.log(patient.records[i][j].title);
                    counter++;
                }
            }
        }
        return (recordTitles, recordDates, linkIndices, recordIndices);
    }

    /**
     * @notice to add a record to a new link
     * @dev doctor address is provided by msg.sender, _data should be provided as an encrypted string
     * @param _patient patient address
     * @param _title the title of the record
     * @param _date current time
     * @param _data the content of the record
     */
    function addRecordNewLink(
        address _patient,
        string memory _title,
        string memory _date,
        string memory _data
    ) public isPatient(_patient) isDoctor(msg.sender) {
        IterableMappingPatient.Patient storage patient = patients.get(_patient);
        uint linkIndex = patient.linkLength;
        patient.linkLength++;
        giveAccess(_patient, linkIndex, msg.sender, 10000);
        patient.records[linkIndex].push(IterableMappingPatient.Record(msg.sender, _title, _date, _data, false));
    }

    /**
     * @notice to add a record at a existing link
     * @dev doctor address is provided by msg.sender, _data should be provided as an encrypted string
     * @param _patient patient address
     * @param linkIndex the link index
     * @param _title the title of the record
     * @param _date current time
     * @param _data the content of the record
     */
    function addRecordExistingLink(
        address _patient,
        uint linkIndex,
        string memory _title,
        string memory _date,
        string memory _data
    ) public isPatient(_patient) isDoctor(msg.sender) {
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

    /**
     * @notice to remove a doctor appointment
     * @dev doctor address is provided by msg.sender
     * @param _patient patient address
     */
    function removeAppointment(address _patient) public isDoctor(msg.sender) isPatient(_patient) {
        IterableMappingDoctor.Doctor storage doctor = doctors.get(msg.sender);
        IterableMappingPatient.Patient storage patient = patients.get(_patient);
        uint len = doctor.appointments.length;
        for (uint i = 0; i < len; i++) {
            if (doctor.appointments[i] == _patient) {
                doctor.appointments[i] = doctor.appointments[len - 1];
                doctor.appointments.pop();
                break;
            }
        }
        len = patient.appointedDoctors.length;
        for (uint i = 0; i < len; i++) {
            if (patient.appointedDoctors[i] == msg.sender) {
                patient.appointedDoctors[i] = patient.appointedDoctors[len - 1];
                patient.appointedDoctors.pop();
                break;
            }
        }
    }

    /**
     * @notice list of all patients
     * @return address array of patients
     */
    function getPatients() public view isDoctor(msg.sender) returns (address[] memory) {
        uint len = patients.size();
        address[] memory addressList = new address[](len);
        for (uint i = 0; i < len; i++) {
            addressList[i] = patients.getKeyAtIndex(i);
        }
        return addressList;
    }

    // ➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖
    // ➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖  Internal  ➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖
    // ➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖

    /**
     * @notice to update the access list
     * @param _patient patient address
     */
    function updateAcessList(address _patient) internal isPatient(_patient) {
        IterableMappingPatient.Patient storage patient = patients.get(_patient);
        uint linkLength = patient.linkLength;
        // console.log("Link Lenght: ");
        // console.log(linkLength);
        for (uint i = 0; i < linkLength; i++) {
            uint accessListLen = patient.access[i].length;
            // console.log("Access List Length: ");
            // console.log(accessListLen);
            for (uint j = 0; j < accessListLen; j++) {
                // console.log("Time: ");
                // console.log(patient.access[i][j].time);
                // console.log(block.timestamp);
                if (patient.access[i][j].time < block.timestamp) {
                    // console.log("here");
                    patient.access[i][j] = patient.access[i][accessListLen - 1];
                    delete patient.access[i][accessListLen - 1];
                    j--;
                    accessListLen--;
                }
            }
        }
    }
    
}
