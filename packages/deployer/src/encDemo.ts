import 'dotenv/config'
import { sleep, logger } from './utils'
import * as PC from './chain/pc'
import crypto from "node:crypto"

const KEY = <`0x${string}`> process.env.PC_PRIVKEY

async function main() {
    await PC.connect()
    // const [result, uri] = await PC.checkMinerDeployed('deployment-id-1')
    // await PC.deploy('0xABCDABCD', 'deployment-id-123', Date.now() + 3600_000)

    const sender_sk = '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80'
    const sender_pk = '0x384de7d40bbac77b5c98bef672d9cb1ac06759b03666386faa9cc301f1ad0d74'
    const receiver_sk = '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff81'
    const receiver_pk = '0x70f0a3059bd820eefb2df892d9ac16272ce7ab3fba5a742b24844ac0723c7006'
    const nonce = 0
    const mid = 'test-deploy-0'

    const text = 'email contents'

    let senderKey = await PC.senderGetKey(mid, sender_sk, receiver_pk, nonce)
    const iv = new Uint8Array(16);
    const cipher = crypto.createCipheriv('aes-256-cbc', senderKey, iv);
    const encrypted = cipher.update(text, 'utf8', 'hex') + cipher.final('hex');

    let receiverKey = await PC.receiverGetKey(mid, receiver_sk, sender_pk, nonce)
    const decipher = crypto.createDecipheriv('aes-256-cbc', receiverKey, iv);
    const decrypted = decipher.update(encrypted, 'hex', 'utf8') + decipher.final('utf8');

    logger.log(`decrypted mail: "${decrypted}"`)
}

main()
.then(() => process.exit(0))
.catch(err => console.error(err))
.finally(() => process.exit(-1))
