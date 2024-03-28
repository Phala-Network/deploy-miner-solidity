import 'dotenv/config'
import { sleep, logger } from './utils'
import * as PC from './chain/pc'
import crypto from "node:crypto"

const KEY = <`0x${string}`> process.env.PC_PRIVKEY

async function main() {
    await PC.connect()
    // const [result, uri] = await PC.checkMinerDeployed('deployment-id-1')
    // await PC.deploy('0xABCDABCD', 'deployment-id-123', Date.now() + 3600_000)

    const workerAddress = '0x994ad7c0de8bac6c89813a9f0827ba0618b077c479af3fb34ae3d1b1b6906d70';
    const worker = await PC.connectWorkerWithAddress(workerAddress);

    // Email metadata.
    // Everyone including sender and all the receivers can get the key from the DePIN worker.
    const metadata = {
        sender: '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266',
        receivers: [
            '0x70997970C51812dc3A010C7d01b50e0d17dc79C8'
        ],
        nonce: '1234',
    }

    // To create the hash:
    const metadataObject = worker.abi.registry.createType('DmailWorkerMailMetadata', metadata);
    const hash = PC.keccak256(metadataObject.toHex());
    console.log('Metadata Hash:', hash);

    // Sign with Ethers.js. Use a private key, or injected browser wallet:
    // const wallet = new Wallet('0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80');\
    // const sig = wallet.signMessageSync(hash);

    const sigSender = '0xacdfa30b99b862dc232e520259daebf16abe647c60932aea222e9de772f1d69f1263108990f1a1ec030482c12bc0e509f1aaec8dce06e69382f575e6a626b29c1c';
    const sigReceiver = '0x529d3bc68478045e367c75168ec0135b165ee32de3c01931cb109759bb8abe8a73618425ce7cf4c355d64a745a63b9b072f01bba6472f5a5458281780a7f515a1b';

    const text = 'email contents'

    logger.log('------------')
    logger.log('Sender side:')
    let senderKey = await PC.getKey(worker, metadata, sigSender)
    const iv = new Uint8Array(16);
    const cipher = crypto.createCipheriv('aes-256-cbc', senderKey, iv);
    const encrypted = cipher.update(text, 'utf8', 'hex') + cipher.final('hex');
    logger.log('Encrypted:', encrypted)

    logger.log('------------')
    logger.log('Receiver side:')
    let receiverKey = await PC.getKey(worker, metadata, sigReceiver)
    const decipher = crypto.createDecipheriv('aes-256-cbc', receiverKey, iv);
    const decrypted = decipher.update(encrypted, 'hex', 'utf8') + decipher.final('utf8');
    logger.log('Decrypted:', decrypted)
}

main()
.then(() => process.exit(0))
.catch(err => console.error(err))
.finally(() => process.exit(-1))
