let { LineaSDK } = require("@consensys/linea-sdk");


const sdk = new LineaSDK({
    l1RpcUrl: "https://goerli.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161", // L1 rpc url
    l2RpcUrl: "https://rpc.goerli.linea.build", // L2 rpc url
    l1SignerPrivateKey: process.env.PRIVATE_KEY, // L1 account private key (optional if you use mode = read-only)
    l2SignerPrivateKey: process.env.PRIVATE_KEY, // L2 account private key (optional if you use mode = read-only)
    network: "linea-goerli", // network you want to interact with (either linea-mainnet or linea-goerli)
    mode: "read-write", // contract wrapper class mode (read-only or read-write), read-only: only read contracts state, read-write: read contracts state and claim messages 
});

const l1Contract = sdk.getL1Contract(); // get the L1 contract wrapper instance
const l2Contract = sdk.getL2Contract();

let hash = "0x6969f227ac2c7a71527a1e65c8cfddc0f12e6bdc0e22cc79e121f7efcdfd9130"

async function t() {
	let message = (await l1Contract.getMessagesByTransactionHash(hash))[0];
	console.log(message)

	status = await l2Contract.getMessageStatus(message.messageHash)
	console.log(status);
	let claimMessage = await l2Contract.claim(message);  
	console.log(claimMessage)  
}


t()