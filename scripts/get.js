const { Provider } = require('zksync2-js')
require('dotenv').config()

let txHash = "0x821f9c4780c158421921aece1b6b6d25d9f95829a2f99a8e07f1cb89d868dc68"
const hre = require('hardhat')
async function main() {
  const zksyncProvider = new Provider('https://zksync2-testnet.zksync.dev')
  
  const ethereumProvider = new hre.ethers.providers.StaticJsonRpcProvider('https://goerli.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161')
  // const logIndex = receipt.logs[0].logIndex;
  const receipt = await ethereumProvider.getTransactionReceipt(txHash);
// Get the L2 transaction index
  // const _l2TxNumberInBlock = receipt.transactionIndex;

  // Get the L2 message index and Merkle proof
  const l2Hash = zksyncProvider.getL2TransactionFromPriorityOp(receipt);

  console.log(receipt, l2Hash);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})


// ["0xa4669936893f35b26cea48e1823b526b534bb9ef5ec6c8e267d86acc48482c85","0xc3d03eebfd83049991ea3d3e358b6712e7aa2e2e63dc2d4b438987cec28ac8d0","0xe3697c7f33c31a9b0f0aeb8542287d0d21e8c4cf82163d0c44c7a98aa11aa111","0x199cc5812543ddceeddd0fc82807646a4899444240db2c0d2f20c3cceb5f51fa","0xe4733f281f18ba3ea8775dd62d2fcd84011c8c938f16ea5790fd29a03bf8db89","0x1798a1fd9c8fbb818c98cff190daa7cc10b6e5ac9716b4a2649f7c2ebcef2272","0x66d7c5983afe44cf15ea8cf565b34c6c31ff0cb4dd744524f7842b942d08770d","0xb04e5ee349086985f74b73971ce9dfe76bbed95c84906c5dffd96504e1e5396c","0xac506ecb5465659b3a927143f6d724f91d8d9c4bdb2463aee111d9aa869874db"]

// [0xa4669936893f35b26cea48e1823b526b534bb9ef5ec6c8e267d86acc48482c85,0xc3d03eebfd83049991ea3d3e358b6712e7aa2e2e63dc2d4b438987cec28ac8d0,0xe3697c7f33c31a9b0f0aeb8542287d0d21e8c4cf82163d0c44c7a98aa11aa111,0x199cc5812543ddceeddd0fc82807646a4899444240db2c0d2f20c3cceb5f51fa,0xe4733f281f18ba3ea8775dd62d2fcd84011c8c938f16ea5790fd29a03bf8db89,0x1798a1fd9c8fbb818c98cff190daa7cc10b6e5ac9716b4a2649f7c2ebcef2272,0x66d7c5983afe44cf15ea8cf565b34c6c31ff0cb4dd744524f7842b942d08770d,0xb04e5ee349086985f74b73971ce9dfe76bbed95c84906c5dffd96504e1e5396c,0xac506ecb5465659b3a927143f6d724f91d8d9c4bdb2463aee111d9aa869874db]
// // curl https://zksync2-testnet.zksync.dev \
// //   -X POST \
// //   -H "Content-Type: application/json" \
// //   --data '{"method":"zks_getL2ToL1LogProof","params":["0x1172b829f0b5746cd585925dfa1da44e3da572892fac3398cb20c097d89abb05" ],"id":1,"jsonrpc":"2.0"}'