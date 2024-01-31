import 'dotenv/config'
import * as db from './db'
import * as PC from './chain/pc'
import * as EVM from './chain/evm'

function testDb() {
    let v
    v = db.get('nonexisting')
    console.assert(v === undefined)
    db.put('test', 'ok')
    v = db.get('test')
    console.assert(v == 'ok')
}

async function testEvm() {
    const r = await EVM.checkMinerDeployed('0x0000000000000000000000000000000000000000000000000000000000000000')
    console.log('checkMinerDeployed', r)
}

async function testPC() {
    await PC.connect()
    const result = await PC.checkMinerDeployed('test-deploy-0')
    console.log(result)
}

async function main() {
    // testDb()
    // await testPC()
    await testEvm()
}

main()
.then(() => process.exit(0))
.catch(err => console.error(err))
.finally(() => process.exit(-1))
