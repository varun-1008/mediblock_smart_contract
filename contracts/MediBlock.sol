// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
// pragma abicoder v2;

import "hardhat/console.sol";

error AlreadyRegistered(address);
error NotADoctor(address);
error NotAPatient(address);
error NotAPathologist(address);
error NotADoctorOrPathologist(address);
error NoWriteAccess(address patient, uint linkIndex, address writer);
error NoReadAccess(
    address patient,
    uint linkIndex,
    uint recordIndex,
    address reader
);
error IndexOutOfBound(uint linkIndex);

contract MediBlock {
    enum Role {
        None,
        Patient,
        Doctor,
        Pathologist
    }

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

    modifier isPathologist(address _pathologist) {
        if (role[_pathologist] != Role.Pathologist)
            revert NotAPathologist(_pathologist);

        _;
    }

    modifier isDoctorOrPathologist(address _address) {
        if (role[_address] != Role.Pathologist && role[_address] != Role.Doctor)
            revert NotADoctorOrPathologist(_address);

        _;
    }

    modifier checkIndexOutOfBound(address paddr, uint linkIndex) {
        if (patient[paddr].linkLength <= linkIndex)
            revert IndexOutOfBound(linkIndex);

        _;
    }

    function patientRegistration(string memory _name) public isUnregistered {
        role[msg.sender] = Role.Patient;
        patient[msg.sender].name = _name;
    }

    function getLinkLength(
        address _paddr
    ) public view isPatient(_paddr) returns (uint) {
        return patient[_paddr].linkLength;
    }

    // New Link can only be created by a patient
    function createNewLink(
        address writer,
        uint _seconds
    ) public isPatient(msg.sender) isDoctor(writer) {
        uint linkLength = patient[msg.sender].linkLength;

        uint accessTime = block.timestamp;
        accessTime += _seconds;

        patient[msg.sender].writeAccess[linkLength][writer] = accessTime;
        patient[msg.sender].linkLength++;
    }

    function giveWriteAccess(
        address writer,
        uint linkIndex,
        uint _seconds
    )
        public
        isPatient(msg.sender)
        checkIndexOutOfBound(msg.sender, linkIndex)
        isDoctorOrPathologist(writer)
    {
        uint accessTime = block.timestamp;
        accessTime += _seconds;
        patient[msg.sender].writeAccess[linkIndex][writer] = accessTime;
    }

    function revokeWriteAccess(
        address writer,
        uint linkIndex
    )
        public
        isPatient(msg.sender)
        checkIndexOutOfBound(msg.sender, linkIndex)
        isDoctorOrPathologist(writer)
    {
        patient[msg.sender].writeAccess[linkIndex][writer] = 0;
    }

    function giveReadAccess(
        address reader,
        uint linkIndex,
        uint recordIndex,
        uint _seconds
    )
        public
        isPatient(msg.sender)
        checkIndexOutOfBound(msg.sender, linkIndex)
        isDoctorOrPathologist(reader)
    {
        require(
            patient[msg.sender].records[linkIndex].length > recordIndex,
            "Record Index out of bound"
        );
        uint accessTime = block.timestamp;
        accessTime += _seconds;

        Record storage record = patient[msg.sender].records[linkIndex][
            recordIndex
        ];
        record.readAccess[reader] = accessTime;
    }

    function revokeReadAccess(
        address reader,
        uint linkIndex,
        uint recordIndex
    )
        public
        isPatient(msg.sender)
        checkIndexOutOfBound(msg.sender, linkIndex)
        isDoctorOrPathologist(reader)
    {
        require(
            patient[msg.sender].records[linkIndex].length > recordIndex,
            "Record Index out of bound"
        );
        Record storage record = patient[msg.sender].records[linkIndex][
            recordIndex
        ];
        record.readAccess[reader] = 0;
    }

    function doctorRegistration(string memory _name) public isUnregistered {
        role[msg.sender] = Role.Doctor;
        doctor[msg.sender].name = _name;
    }

    function hasWriteAccess(
        address _patient,
        uint linkIndex
    )
        public
        view
        isDoctorOrPathologist(msg.sender)
        isPatient(_patient)
        returns (bool)
    {
        uint currentTime = block.timestamp;
        uint accessTime = patient[_patient].writeAccess[linkIndex][msg.sender];

        return accessTime >= currentTime;
    }

    function hasReadAccess(
        address _patient,
        uint linkIndex,
        uint recordIndex
    )
        public
        view
        isDoctorOrPathologist(msg.sender)
        isPatient(_patient)
        returns (bool)
    {
        uint currentTime = block.timestamp;

        Record storage record = patient[_patient].records[linkIndex][
            recordIndex
        ];
        uint accessTime = record.readAccess[msg.sender];

        return accessTime >= currentTime;
    }

    function readRecord(
        address _patient,
        uint linkIndex,
        uint recordIndex
    )
        public
        view
        isDoctorOrPathologist(msg.sender)
        isPatient(_patient)
        returns (address, string memory)
    {
        bool access = hasReadAccess(_patient, linkIndex, recordIndex);
        if (!access)
            revert NoReadAccess(_patient, linkIndex, recordIndex, msg.sender);

        Record storage newRecord = patient[_patient].records[linkIndex][
            recordIndex
        ];
        return (newRecord.creator, newRecord.data);
    }

    // Used to add new records in existing links
    function addNewRecord(
        address _patient,
        uint linkIndex,
        string memory _data
    )
        public
        isDoctorOrPathologist(msg.sender)
        checkIndexOutOfBound(_patient, linkIndex)
        isPatient(_patient)
        returns (bool)
    {
        if (hasWriteAccess(_patient, linkIndex)) {
            uint newRecordIndex = patient[_patient].records[linkIndex].length;
            uint time = block.timestamp;
            uint accessTime = time + 1000000;
            patient[_patient].records[linkIndex].push();
            patient[_patient].records[linkIndex][newRecordIndex].data = _data;
            patient[_patient].records[linkIndex][newRecordIndex].creator = msg
                .sender;
            patient[_patient].records[linkIndex][newRecordIndex].readAccess[
                msg.sender
            ] = accessTime;
            return true;
        }
        return false;
    }

    function pathologistRegistration(
        string memory _name
    ) public isUnregistered {
        role[msg.sender] = Role.Pathologist;
        pathologist[msg.sender].name = _name;
    }
}
