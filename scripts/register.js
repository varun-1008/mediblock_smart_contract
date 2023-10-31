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

    const p1Info = "bafkreiatqmhlpl3zwhydl5ocpyfn7cfawblnrwrx44csl37gto7lplwbqe";
    const p2Info = "bafkreifny27dagptpuicq5gjsbg2jgasi7zdgljaqsplde63l5av6tcb5a";
    const d1Info = "bafkreibmyfnztss2pgllxmrz3r3gezuflln464yyks2n3duuqbwou6gx3i";
    const d2Info = "bafkreiaxm7oz5rqfwwhegmo3f3n4o4uyfubmk6j77vvv3eluitsmyd7pti";

    await contract.connect(p1).patientRegistration(p1Info);
    await contract.connect(p2).patientRegistration(p2Info);
    await contract.connect(d1).doctorRegistration(d1Info);
    await contract.connect(d2).doctorRegistration(d2Info);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
