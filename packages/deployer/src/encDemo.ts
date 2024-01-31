import 'dotenv/config'
import { sleep, logger } from './utils'
import * as PC from './chain/pc'

async function main() {
    await PC.connect()
    // const [result, uri] = await PC.checkMinerDeployed('deployment-id-1')
    // await PC.deploy('0xABCDABCD', 'deployment-id-123', Date.now() + 3600_000)
}

main()
.then(() => process.exit(0))
.catch(err => console.error(err))
.finally(() => process.exit(-1))
