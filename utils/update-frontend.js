const fs = require("fs");
const path = require("path");

async function updateAbi(address) {
  const frontEndAbiFile = path.join(
    "..",
    "mediblock_frontend",
    "constants",
    "abi.json",
  );

  const jsonPath = path.join(
    "artifacts",
    "contracts",
    "MediBlock.sol",
    "MediBlock.json",
  );
  const data = fs.readFileSync(jsonPath, "utf8");
  const json = JSON.parse(data);
  const abi = JSON.stringify(json.abi);
  fs.writeFileSync(frontEndAbiFile, abi);
}

async function updateContractAddresses(address) {
  const frontEndContractsFile = path.join(
    "..",
    "mediblock_frontend",
    "constants",
    "contractAddresses.json",
  );

  const contractAddresses = JSON.parse(
    fs.readFileSync(frontEndContractsFile, "utf8"),
  );

  if (network.config.chainId.toString() in contractAddresses) {
    if (
      !contractAddresses[network.config.chainId.toString()].includes(address)
    ) {
      contractAddresses[network.config.chainId.toString()] = address;
    }
  } else {
    contractAddresses[network.config.chainId.toString()] = [address];
  }
  fs.writeFileSync(frontEndContractsFile, JSON.stringify(contractAddresses));
}

module.exports = {updateAbi, updateContractAddresses};