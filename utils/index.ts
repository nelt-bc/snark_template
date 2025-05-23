export type anyObject = Record<string, unknown>

export type Optional<T> = T | null
export type Maybe <T> = Optional<T> | undefined

export type PromiseOptional <T> = Promise<Optional<T>>
export type PromiseMaybe <T> = Promise<Maybe<T>>

export function delay(ms: number) {
    return new Promise( resolve => setTimeout(resolve, ms) );
}