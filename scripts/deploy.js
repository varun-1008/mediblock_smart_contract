const {updateAbi, updateContractAddresses} = require("../utils/update-frontend");
const {network} = require("hardhat");

async function main() {
  const mediblock = await hre.ethers.deployContract("MediBlock");
  await mediblock.waitForDeployment();

  const address = await mediblock.getAddress();
  console.log(address);
  updateAbi(address);
  updateContractAddresses(address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

