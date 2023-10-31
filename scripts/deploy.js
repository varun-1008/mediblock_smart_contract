const {
    updateAbi,
    updateContractAddresses,
} = require("../utils/update-frontend");
const fs = require("fs");
const path = require("path");

async function main() {
    const mappingContractPatient = await hre.ethers.deployContract(
        "IterableMappingPatient",
    );
    await mappingContractPatient.waitForDeployment();
    const mappingContractAddressPatient =
        await mappingContractPatient.getAddress();

    const mappingContractDoctor = await hre.ethers.deployContract(
        "IterableMappingDoctor",
    );
    await mappingContractDoctor.waitForDeployment();
    const mappingContractAddressDoctor =
        await mappingContractDoctor.getAddress();

    const mediblockContractFactory = await ethers.getContractFactory("MediBlockv2", {
        libraries: {
            IterableMappingPatient: mappingContractAddressPatient,
            IterableMappingDoctor: mappingContractAddressDoctor,
        },
    });
    const mediblock = await mediblockContractFactory.deploy();
    await mediblock.waitForDeployment();
    const address = await mediblock.getAddress();

    console.log(address);

    const addressFile = path.join(
        "constants",
        "address.txt",
      );
    fs.writeFileSync(addressFile, address, "utf8");
    updateAbi(address);
    updateContractAddresses(address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
