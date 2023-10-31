1. To run local node, run this in terminal 1
  - `yarn hardhat node`
2. To deploy the smart contract, run this in terminal 2
  - `yarn hardhat run scripts/deploy.js --network localhost`
3. To compile smart contract
  - `yarn hardhat compile`
4. To run tests
  - `yarn hardhat test`

5. To format code
  - `yarn prettier --write --plugin=prettier-plugin-solidity 'contracts/**/*.sol'`