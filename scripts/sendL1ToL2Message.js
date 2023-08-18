const { BigNumber } = require('ethers')
const { Wallet, Provider, Contract, utils } = require('zksync-web3')
let fs = require("fs")
let deployed = JSON.parse(fs.readFileSync("./deployed.json"))
console.log(deployed)
require('dotenv').config()
const hre = require('hardhat')
async function main2() {
  const zkSyncProvider = new Provider('https://zksync2-testnet.zksync.dev')
  const ethereumProvider = new ethers.providers.StaticJsonRpcProvider('https://goerli.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161')
  const wallet = new Wallet(privateKey, zkSyncProvider, ethereumProvider)
  const zkSyncAddress = await zkSyncProvider.getMainContractAddress()
  console.log(zkSyncAddress)
  const gasPrice = await wallet.providerL1.getGasPrice()
  // const
  const ergsLimit = BigNumber.from(100000)

  const l2ContractAbi = require('../artifacts/contracts/L2Contract.sol/L2Contract.json').abi
  const iface = new ethers.utils.Interface(l2ContractAbi)
  const message = iface.encodeFunctionData('setGreeting', [greeting])

  const zkSyncContract = new Contract(zkSyncAddress, utils.ZKSYNC_MAIN_ABI, ethereumProvider)
  // const baseCost = await zkSyncContract.l2TransactionBaseCost(gasPrice, ergsLimit, ethers.utils.hexlify(message).length)
  const baseCost = await wallet.getBaseCost({
    // L2 computation
    gasLimit: ergsLimit,
    // L1 gas price
    gasPrice: l1GasPrice,
  });


  const tx = await l1Contract.sendGreetingMessageToL2(zkSyncAddress, l2ContractAddress, greeting, {
    value: baseCost,
    gasPrice
  })

  await tx.wait()
  console.log(`sent tx hash ${tx.hash}`)
  console.log(`https://goerli.etherscan.io/tx/${tx.hash}`)

  // Getting the TransactionResponse object for the L2 transaction corresponding to the execution call
  const l2Response = await zkSyncProvider.getL2TransactionFromPriorityOp(tx)

  // The receipt of the L2 transaction corresponding to the call to the counter contract's Increment method
  const l2Receipt = await l2Response.wait()
  console.log(l2Receipt)
}

async function main() {
  const privateKey = process.env.PRIVATE_KEY
  const greeting = "hello world"
  const l1ContractAddress = deployed.L1
  const l2ContractAddress = deployed.L2

  // const L1Contract = await hre.ethers.getContractAt("L1Contract", deployed.L1);
  // const L1Contract = await hre.ethers.getContractFactory('ZKPayRollL1')
  // const l1Contract = L1Contract.attach(l1ContractAddress)
  // await l1Contract.deployed()


  const l1provider = new Provider("https://goerli.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161");
  const l2provider = new Provider("https://zksync2-testnet.zksync.dev");
  const wallet = new Wallet(privateKey, l2provider, l1provider)

  console.log(`L2 Balance is ${await wallet.getBalance()}`);
  const l1GasPrice = await l1provider.getGasPrice();
  const l2GasPrice = await l2provider.getGasPrice();
  console.log(`L1 gasPrice ${hre.ethers.utils.formatEther(l1GasPrice)} ETH, ${l1GasPrice} ${l2GasPrice}`);

  const l2ContractAbi = require('../artifacts/contracts/L2Contract.sol/L2Contract.json').abi
  const contract = new Contract(deployed.L2, l2ContractAbi, wallet);


  const msg = await contract.greet();
  console.log(`Message in contract is ${msg}`)

  const message = `Updated at ${new Date().toUTCString()}`;
  const tx = await contract.populateTransaction.setGreeting(message);
  const l2GasLimit = await l2provider.estimateGasL1(tx);
  console.log(`L2 gasLimit ${l2GasLimit.toString()}`);


  const baseCost = await wallet.getBaseCost({
    // L2 computation
    gasLimit: l2GasLimit,
    // L1 gas price
    gasPrice: l1GasPrice,
  });

  console.log(`Executing this transaction will cost ${ethers.utils.formatEther(baseCost)} ETH`);
  // const iface = new ethers.utils.Interface(l2ContractAbi);
  // const calldata = iface.encodeFunctionData("setGreeting", [message]);
  // const txReceipt = await wallet.requestExecute({
  //   contractAddress: deployed.L2,
  //   calldata,
  //   l2GasLimit: l2GasLimit,
  //   refundRecipient: wallet.address,
  //   overrides: {
  //     // send the required amount of ETH
  //     value: baseCost,
  //     gasPrice: l1GasPrice,
  //   },
  // });
  // console.log("L1 tx hash is :>> ", txReceipt.hash);
  // txReceipt.wait();
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
