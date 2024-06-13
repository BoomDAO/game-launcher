import { AuthClientStorage } from "@dfinity/auth-client/lib/cjs/storage";

export class MyStorage implements AuthClientStorage 
{
    myState : string = "";
 
    async get(key: string): Promise<string | null> {
        return this.myState;
    } 
 
    async set(key: string, value: string): Promise<void> {
       this.myState = value;
    }
 
    async remove(key: string): Promise<void> {
       this.myState = undefined;
    }
 }