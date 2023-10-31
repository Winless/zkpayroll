const { Provider } = require('zksync-web3')
require('dotenv').config()

let txHash = "0x1172b829f0b5746cd585925dfa1da44e3da572892fac3398cb20c097d89abb05"

async function main() {
  const zkSyncProvider = new Provider('https://zksync2-testnet.zksync.dev')
  const receipt = await provider.getTransactionReceipt(txHash);

// Get the L2 transaction index
  const _l2TxNumberInBlock = receipt.transactionIndex;

  // Get the L2 message index and Merkle proof
  const logProof = await zksyncProvider.zks_getL2ToL1LogProof(txHash, logIndex);
  const _l2MessageIndex = logProof.id;
  const _merkleProof = logProof.proof;

  console.log(receipt,_l2TxNumberInBlock, logProof, _l2MessageIndex, _merkleProof);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
