import fs from "fs";
import path from "path";
import { Maybe } from ".";

export class Database {
  read(network: string, name: string): Maybe<string> {
    const filePath = path.join(__dirname, `./db/${network}.json`);
    if (fs.existsSync(filePath)) {
      const rawData = fs.readFileSync(filePath, "utf-8");
      const contracts = JSON.parse(rawData) as Record<string, string>;
      return contracts[name];
    }
  }

  write(network: string, name: string, address: string) {
    const filePath = path.join(__dirname, `./db/${network}.json`);
    if (fs.existsSync(filePath)) {
      const rawData = fs.readFileSync(filePath, "utf-8");
      const contracts = JSON.parse(rawData) as Record<string, string>;
      fs.writeFileSync(
        filePath,
        JSON.stringify({ ...contracts, [name]: address })
      );
    }

    fs.writeFileSync(filePath, JSON.stringify({[name]: address}))
  }
}
