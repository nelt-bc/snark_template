import { delay, PromiseOptional } from ".";
import { Database } from "./file";
import { network, ethers } from "hardhat";

export class Web3Utils {
  constructor(
    private readonly delayTime: number = 500,
    private readonly isRedeploy: boolean = true,
    private readonly db: Database = new Database()
  ) {}

  async getContract<T>(name: string): PromiseOptional<T> {
    const contractAddress = this.db.read(network.name, name);
    if (!contractAddress) throw new Error("Contract not found/deployed");

    const factory = await ethers.getContractFactory(name)
    const contract = factory.attach(contractAddress)
    return contract as unknown as T;
  }

  async deployContract<T>(name: string, ...args: unknown[]): Promise<T> {
    const factory = await ethers.getContractFactory(name)

    if (this.delayTime > 0) await delay(this.delayTime)
    if (!this.isRedeploy) return await this.getContract<T>(name) as Promise<T>

    const contract = await factory.deploy(...args)
    this.db.write(network.name, name, contract.target as string)
    return contract as unknown as T
  }
}
