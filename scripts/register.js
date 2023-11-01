const fs = require("fs");
const path = require("path");

async function main() {
    const addressFile = path.join("constants", "address.txt");

    const address = fs.readFileSync(addressFile, "utf8");
    const contract = await ethers.getContractAt(
        "MediBlockv2",
        address,
    );

    const [p1, p2, p3, d1, d2, d3] = await ethers.getSigners();

    const p1Info = "bafybeicvmgsphp3xus2422zso7u7b32yol5iu2locxxrxoif5cupl4iw4q";
    const p2Info = "bafybeigx5szf5sln4o6ftoyhg2pmcw3uwrbwm5v7ee6uje2mc6rnfo44ii";
    const d1Info = "bafybeig46uxtckbvo5gw2f6gnndhxwffqpgeary3cfz7k77l56idrjjg6e";
    const d2Info = "bafybeih2lg66iq2hq462ogn5thar5m75yzi5qtp2t2ole3tnkj5hgkvihq";
    const d3Info = "bafybeidv6ip4nd5yppk35rltbezuxkxxfconifdyqiqhz5meggut7ppo64";

    await contract.connect(p1).patientRegistration(p1Info);
    await contract.connect(p2).patientRegistration(p2Info);
    await contract.connect(d1).doctorRegistration(d1Info);
    await contract.connect(d2).doctorRegistration(d2Info);
    await contract.connect(d3).doctorRegistration(d3Info);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
