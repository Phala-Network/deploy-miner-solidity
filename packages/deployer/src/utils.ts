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
    warn(...args: any[]) {
        console.warn(logPrefix(), ...args)
    },
    log(...args: any[]) {
        console.log(logPrefix(), ...args)
    },
    error(...args: any[]) {
        console.error(logPrefix(), ...args)
    },
    debug(...args: any[]) {
        console.error(logPrefix(), ...args)
    },
}