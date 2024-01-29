import fs from 'fs'
const FILE = process.env.DB || './tmp/data.json'

function open(): object {
    let db = {};
    try {
        const f = fs.readFileSync(FILE, {encoding: 'utf8'})
        db = JSON.parse(f)
    } catch (err) {
        console.error(err)
        console.log('creating new')
    }
    return db
}

function save(db: object) {
    const json = JSON.stringify(db, undefined, 2)
    fs.writeFileSync(FILE, json, {encoding: 'utf8'})
} 

export function put(key: string, value: any) {
    const db = open()
    db[key] = value
    save(db)
}

export function get(key: string): any {
    const db = open()
    return db[key]
}

export function getAll(): [string, object][] {
    const db = open()
    return Object.entries(db)
}