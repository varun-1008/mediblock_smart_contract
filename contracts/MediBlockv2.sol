// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
pragma abicoder v2;

import { IterableMappingPatient } from "./IterableMapping.sol";
import "hardhat/console.sol";

contract MediBlockv2 {
  using IterableMappingPatient for IterableMappingPatient.Map;

  IterableMappingPatient.Map patients;

  constructor(){
    console.log("In constructor");
    patients.set(msg.sender,"Varun");
  }
}