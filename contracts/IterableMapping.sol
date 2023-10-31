// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library IterableMappingPatient {
    struct Access {
        address addr;
        uint time;
    }

    struct Record {
        address creator;
        string title;
        string date;
        string data;
    }

    struct Patient {
        string info;
        uint linkLength;
        mapping(uint => Access[]) access;
        mapping(uint => Record[]) records;
        Record[] emergencyRecords;
        address[] appointedDoctors;
    }

    struct Map {
        address[] keys;
        mapping(address => Patient) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    function find(Map storage map, address key) public view returns (bool) {
        if (map.inserted[key]) return true;
        return false;
    }

    function get(
        Map storage map,
        address key
    ) public view returns (Patient storage) {
        return map.values[key];
    }

    function getKeyAtIndex(
        Map storage map,
        uint index
    ) public view returns (address) {
        return map.keys[index];
    }

    function size(Map storage map) public view returns (uint) {
        return map.keys.length;
    }

    function set(Map storage map, address key, string memory _info) public {
        if (map.inserted[key]) {
            map.values[key].info = _info;
        } else {
            map.inserted[key] = true;
            map.values[key].info = _info;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }
}

library IterableMappingDoctor {
    struct Doctor {
        string info;
        address[] appointments;
    }

    struct Map {
        address[] keys;
        mapping(address => Doctor) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    function find(Map storage map, address key) public view returns (bool) {
        if (map.inserted[key]) return true;
        return false;
    }

    function get(
        Map storage map,
        address key
    ) public view returns (Doctor storage) {
        return map.values[key];
    }

    function getKeyAtIndex(
        Map storage map,
        uint index
    ) public view returns (address) {
        return map.keys[index];
    }

    function size(Map storage map) public view returns (uint) {
        return map.keys.length;
    }

    function set(Map storage map, address key, string memory _info) public {
        if (map.inserted[key]) {
            map.values[key].info = _info;
        } else {
            map.inserted[key] = true;
            map.values[key].info = _info;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }
}
