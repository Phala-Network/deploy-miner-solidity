export function sleep(ms: number): Promise<void> {
    return new Promise(resolve => {
        setTimeout(resolve, ms)
    })
}

function logPrefix(): string {
    const now = new Date()
    return `[${now.toISOString()}] `
}

export const logger = {
    warn(...args) {
        console.warn(logPrefix(), ...args)
    },
    log(...args) {
        console.log(logPrefix(), ...args)
    },
    error(...args) {
        console.error(logPrefix(), ...args)
    },
    debug(...args) {
        console.error(logPrefix(), ...args)
    },
}