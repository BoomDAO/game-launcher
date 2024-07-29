import {
    JsonResponse,
    JsonRPC,
    JsonResponseResult,
    JsonRequest
} from "./transport";
import { useMemo, useCallback, useState, useEffect } from "react";
import {
    type Channel,
    type Connection,
    type Transport,
    Signer,
    createAccountsPermissionScope,
    createDelegationPermissionScope,
    createCallCanisterPermissionScope
  } from "@slide-computer/signer";


export class WalletChannel implements Channel {
    closed = false;

    #listeners: ((response: JsonResponse) => void)[] = [];
    public sendMethod: (data: JsonRPC) => Promise<JsonResponse>;

    constructor(options: any) {
        this.sendMethod = options.sendMethod
    }

    addEventListener(
        ...[event, listener]:
            | [event: "close", listener: () => void]
            | [event: "response", listener: (response: JsonResponse) => void]
    ): () => void {
        switch (event) {
            case 'close':
                return () => { }
            case 'response':
                this.#listeners.push(listener)
                return () => {
                    this.#listeners = this.#listeners.filter(list => list !== listener)
                }
        }
    }

    async send(request: JsonRequest): Promise<void> {
        const response = await this.sendMethod(request)
        this.#listeners.forEach(listener => listener(response))
    }

    close(): Promise<void> {
        return Promise.resolve()
    }

}

export class PlugTransport implements Transport {
    establishChannel(): Promise<Channel> {
        const plugChannel = new WalletChannel({ sendMethod: (data : any) => (window as any).ic.plug.request(data) })
        return Promise.resolve(plugChannel)
    }
}

export default function Index() {
    const [actor, setActor] = useState()

    const signer = useMemo(() => {
        const transport = new PlugTransport()

        return new Signer({ transport });
    }, [])

    const requestPermissions = useCallback(async () => {
        const permissions = await signer.requestPermissions([createAccountsPermissionScope(), createDelegationPermissionScope({})])
    }, [signer])
}