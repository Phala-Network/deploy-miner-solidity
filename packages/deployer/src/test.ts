import 'dotenv/config'
import * as db from './db'
import * as PC from './chain/pc'

function testDb() {
    let v
    v = db.get('nonexisting')
    console.assert(v === undefined)
    db.put('test', 'ok')
    v = db.get('test')
    console.assert(v == 'ok')
}

async function testPC() {
    await PC.connect()
    const result = await PC.checkMinerDeployed('test-deploy-0')
    console.log(result)
}

async function main() {
    // testDb()
    await testPC()
}

main()
.then(() => process.exit(0))
.catch(err => console.error(err))
.finally(() => process.exit(-1))
