// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
// pragma abicoder v2;

import "hardhat/console.sol";

error AlreadyRegistered(address);
error NotADoctor(address);
error NotAPatient(address);
error NotAPathologist(address);
error NotADoctorOrPathologist(address);
error NoWriteAccess(address patient, uint linkIndex, address writer);
error NoReadAccess(address patient, uint linkIndex, uint recordIndex, address reader);

contract MediBlock {

    enum Role {None, Patient, Doctor, Pathologist}

    struct Record {
        address creator;
        string data;
        mapping(address => uint) readAccess;
    }

    struct Patient {
        string name;
        uint linkLength;
        mapping(uint => mapping(address => uint)) writeAccess;
        mapping(uint => Record[]) records;
    }

    struct Doctor {
        string name;
    }

    struct Pathologist {
        string name;
    }

    mapping(address => Role) public role;

    mapping(address => Patient) public patient;

    mapping(address => Doctor) public doctor;

    mapping(address => Pathologist) public pathologist;

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
    
    modifier isPathologist (address _pathologist){
        if(role[_pathologist] != Role.Pathologist)
            revert NotAPathologist(_pathologist);

        _;
    }

    modifier isDoctorOrPathologist (address _address){
        if(role[_address] != Role.Pathologist && role[_address] != Role.Doctor)
            revert NotADoctorOrPathologist(_address);

        _;
    }

    function patientRegistration(string memory _name) public isUnregistered {
        role[msg.sender] = Role.Patient;
        patient[msg.sender].name = _name;
    }
 
    // function getPatientRecordArray(address _patient, uint linkIndex) internal view returns (Record[] storage) {
    //     return patient[_patient].records[linkIndex];
    // }

    // function setPatientRecordArray(address _patient, uint linkIndex, address _doctor, string memory _data) public {
    //     Record storage newRecord = patient[_patient].records[linkIndex].push();

    //     newRecord.doctor = _doctor;
    //     newRecord.data = _data;
    // }

    // function getAccessList(address _patient, uint linkIndex, address _doctor) public view returns (uint) {
    //     return patient[_patient].records[linkIndex][0].accessList[_doctor];
    // }

    // function setAccessList(address _patient, uint linkIndex, address _doctor, uint time) public {
    //     patient[_patient].records[linkIndex][0].accessList[_doctor] = time;
    // } 

    // function giveInitialAccess(address _doctor, uint _seconds) public isPatient(msg.sender) isDoctor(_doctor) {
    //     uint linkIndex = patient[msg.sender].linkLength;
    //     Record storage newRecord = patient[msg.sender].records[linkIndex].push();
    //     newRecord.doctor = address(0);
    //     newRecord.data = "Intial record";
    //     patient[msg.sender].linkLength++;

    //     uint accessTime = block.timestamp;
    //     accessTime += _seconds;
    //     newRecord.accessList[_doctor] = accessTime;
    // }

    function giveWriteAccess(address writer, uint _seconds) public isPatient(msg.sender) isDoctorOrPathologist(writer) {
        uint linkLength = patient[msg.sender].linkLength;

        uint accessTime = block.timestamp;
        accessTime += _seconds;

        patient[msg.sender].writeAccess[linkLength][writer] = accessTime;
        patient[msg.sender].linkLength++;
    }

    function revokeWriteAccess(address writer, uint linkIndex) public isPatient(msg.sender) isDoctorOrPathologist(writer) {
       patient[msg.sender].writeAccess[linkIndex][writer] = 0;
    }
    
    function giveReadAccess(address reader, uint linkIndex, uint recordIndex, uint _seconds) public isPatient(msg.sender) isDoctorOrPathologist(reader) {
        uint accessTime = block.timestamp;
        accessTime += _seconds;

        Record storage record =  patient[msg.sender].records[linkIndex][recordIndex];
        record.readAccess[reader] = accessTime;
    }

    function revokeReadAccess(address reader, uint linkIndex, uint recordIndex) public isPatient(msg.sender) isDoctorOrPathologist(reader) {
       Record storage record =  patient[msg.sender].records[linkIndex][recordIndex];
        record.readAccess[reader] = 0;
    }

    
    function doctorRegistration(string memory _name) public isUnregistered {
        role[msg.sender] = Role.Doctor;
        doctor[msg.sender].name = _name;
    }

    // function hasAccess(address _patient, uint linkIndex) public isDoctor(msg.sender) isPatient(_patient) view {
    //     uint currentTime = block.timestamp;
    //     uint accessTime = patient[_patient].accessList[linkIndex][msg.sender];
    //     if(accessTime < currentTime)
    //         revert NoAccess(_patient, linkIndex, msg.sender);
    // }

    function hasWriteAccess(address _patient, uint linkIndex) public isDoctorOrPathologist(msg.sender) isPatient(_patient) view returns (bool) {
        uint currentTime = block.timestamp;
        uint accessTime = patient[_patient].writeAccess[linkIndex][msg.sender];

        return accessTime >= currentTime;
    }

    function hasReadAccess(address _patient, uint linkIndex, uint recordIndex) public isDoctorOrPathologist(msg.sender) isPatient(_patient) view returns (bool) {
        uint currentTime = block.timestamp;

        Record storage record = patient[_patient].records[linkIndex][recordIndex];
        uint accessTime = record.readAccess[msg.sender];

        return accessTime >= currentTime;
    }

    function readRecord(address _patient, uint linkIndex, uint recordIndex) public isDoctorOrPathologist(msg.sender) isPatient(_patient) view returns (address, string memory) {
        bool access = hasReadAccess(_patient, linkIndex, recordIndex);
        if(!access)
            revert NoReadAccess(_patient, linkIndex, recordIndex, msg.sender);

        Record storage newRecord = patient[_patient].records[linkIndex][recordIndex];
        return (newRecord.creator, newRecord.data);
    }

    function pathologistRegistration(string memory _name) public isUnregistered {
        role[msg.sender] = Role.Pathologist;
        pathologist[msg.sender].name = _name;
    }
}