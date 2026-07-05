// Thin wrapper around the dynamic Soroban contract client.
// contract.Client.from fetches the contract spec from the chain, so there is
// no codegen bindings package to maintain (ADR-013).

import {
  getAddress,
  requestAccess,
  signTransaction,
} from "@stellar/freighter-api";
import { contract } from "@stellar/stellar-sdk";
import { FOLIO_ID, NETWORK_PASSPHRASE, RPC_URL } from "../config";

export interface AssetInfo {
  token: string;
  weight_bps: number;
  decimals: number;
}
export interface NavInfo {
  total_value: bigint;
  per_share: bigint;
}

type AnyClient = contract.Client & Record<string, any>;

let readClient: AnyClient | undefined;

async function getReadClient(): Promise<AnyClient> {
  if (!readClient) {
    readClient = (await contract.Client.from({
      contractId: FOLIO_ID,
      networkPassphrase: NETWORK_PASSPHRASE,
      rpcUrl: RPC_URL,
    })) as AnyClient;
  }
  return readClient;
}

/** Client bound to the connected wallet, for state-changing calls. */
async function getWriteClient(publicKey: string): Promise<AnyClient> {
  return (await contract.Client.from({
    contractId: FOLIO_ID,
    networkPassphrase: NETWORK_PASSPHRASE,
    rpcUrl: RPC_URL,
    publicKey,
    signTransaction: (xdr: string, opts?: any) =>
      signTransaction(xdr, {
        networkPassphrase: opts?.networkPassphrase ?? NETWORK_PASSPHRASE,
        address: publicKey,
      }),
  })) as AnyClient;
}

// --- wallet ---

export async function connectWallet(): Promise<string> {
  const access = await requestAccess();
  if (access.error) throw new Error(access.error);
  const addr = await getAddress();
  if (addr.error) throw new Error(addr.error);
  return addr.address;
}

// --- reads ---

export async function fetchAssets(): Promise<AssetInfo[]> {
  const c = await getReadClient();
  return (await c.get_assets()).result as AssetInfo[];
}

export async function fetchNav(): Promise<NavInfo> {
  const c = await getReadClient();
  return (await c.nav()).result as NavInfo;
}

export async function fetchBalances(): Promise<bigint[]> {
  const c = await getReadClient();
  return (await c.balances()).result as bigint[];
}

export async function fetchShareBalance(account: string): Promise<bigint> {
  const c = await getReadClient();
  return (await c.balance({ account })).result as bigint;
}

export async function fetchTotalSupply(): Promise<bigint> {
  const c = await getReadClient();
  return (await c.total_supply()).result as bigint;
}

// --- writes ---

const BIG_MAX = (1n << 100n).toString();

/** Simulate a mint to learn the required per-asset deposits (ratio helper). */
export async function quoteMint(
  publicKey: string,
  sharesOut: bigint,
  nAssets: number,
): Promise<bigint[]> {
  const c = await getWriteClient(publicKey);
  const tx = await c.mint({
    user: publicKey,
    shares_out: sharesOut,
    max_deposits: Array(nAssets).fill(BIG_MAX),
  });
  return tx.result as bigint[];
}

/** Execute a mint with a 0.5% buffer over the quoted deposits. */
export async function sendMint(
  publicKey: string,
  sharesOut: bigint,
  quoted: bigint[],
): Promise<bigint[]> {
  const c = await getWriteClient(publicKey);
  const max = quoted.map((d) => (d * 1005n) / 1000n + 1n);
  const tx = await c.mint({
    user: publicKey,
    shares_out: sharesOut,
    max_deposits: max,
  });
  const { result } = await tx.signAndSend();
  return result as bigint[];
}

export async function sendRedeem(
  publicKey: string,
  shares: bigint,
): Promise<bigint[]> {
  const c = await getWriteClient(publicKey);
  const tx = await c.redeem({ user: publicKey, shares });
  const { result } = await tx.signAndSend();
  return result as bigint[];
}

// --- formatting ---

export function fmtUnits(v: bigint, decimals: number, dp = 4): string {
  const base = 10n ** BigInt(decimals);
  const whole = v / base;
  const frac = (v < 0n ? -v : v) % base;
  const fracStr = frac.toString().padStart(decimals, "0").slice(0, dp);
  return `${whole.toString()}.${fracStr}`;
}

export function parseUnits(s: string, decimals: number): bigint {
  const [whole, frac = ""] = s.trim().split(".");
  const fracPadded = (frac + "0".repeat(decimals)).slice(0, decimals);
  return BigInt(whole || "0") * 10n ** BigInt(decimals) + BigInt(fracPadded || "0");
}
