// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require('hardhat')
require('dotenv').config()

const { BigNumber } = require('ethers')
const { Wallet, Provider, Contract, utils } = require('zksync-web3')
const { Deployer } = require("@matterlabs/hardhat-zksync-deploy");
const 

async function main() {
  console.log(`Running deploy script`);

  // Initialize the wallet.
  const wallet = new Wallet(process.env.PRIVATE_KEY);

  // Create deployer object and load the artifact of the contract we want to deploy.
  const deployer = new Deployer(hre, wallet);
  // Load contract
  const artifact = await deployer.loadArtifact("L2Contract");

  // Deploy this contract. The returned object will be of a `Contract` type,
  // similar to the ones in `ethers`.
  // const greeting = "Hi there!";
  // `greeting` is an argument for contract constructor.
  const greeterContract = await deployer.deploy(artifact, []);

  // Show the contract info.
  console.log(`${artifact.contractName} was deployed to ${greeterContract.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
