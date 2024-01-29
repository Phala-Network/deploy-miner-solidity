import * as db from './db'

async function main() {
    let v
    v = db.get('nonexisting')
    console.assert(v === undefined)
    db.put('test', 'ok')
    v = db.get('test')
    console.assert(v == 'ok')
}

main()
.then(() => process.exit(0))
.catch(err => console.error(err))
.finally(() => process.exit(-1))
