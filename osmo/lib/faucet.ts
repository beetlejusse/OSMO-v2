// TESTNET funding helpers:
// 1) Friendbot — free testnet XLM (Aquarius docs recommend this as the entry faucet)
// 2) OSMO issuer drip — optional self-issued tst* basket tokens (needs secret)

import { Asset, Horizon, Keypair, Operation, TransactionBuilder } from "@stellar/stellar-sdk";
import {
  FAUCET_AMOUNTS,
  HORIZON_URL,
  NETWORK_PASSPHRASE,
  TEST_ISSUER_SECRET,
  TRUSTLINE_ASSETS,
} from "@/lib/config";

const horizon = new Horizon.Server(HORIZON_URL);

/** Fund an account with testnet XLM via SDF Friendbot (Aquarius's recommended faucet). */
export async function fundWithFriendbot(destination: string): Promise<void> {
  const res = await fetch(`https://friendbot.stellar.org?addr=${encodeURIComponent(destination)}`);
  if (!res.ok) {
    const body = await res.text().catch(() => "");
    // Already-funded accounts often return 400 — treat as soft success if account exists.
    try {
      await horizon.loadAccount(destination);
      return;
    } catch {
      throw new Error(`Friendbot failed (${res.status}): ${body.slice(0, 200)}`);
    }
  }
}

/** Send one drip of every basket asset (+ some XLM for fees) to `destination`. */
export async function dripTestTokens(destination: string): Promise<void> {
  if (!TEST_ISSUER_SECRET) {
    throw new Error(
      "Basket-token faucet secret not set. Use Friendbot for XLM, or set NEXT_PUBLIC_TEST_ISSUER_SECRET for tst* drips.",
    );
  }
  const issuer = Keypair.fromSecret(TEST_ISSUER_SECRET);
  const issuerAccount = await horizon.loadAccount(issuer.publicKey());

  let tx = new TransactionBuilder(issuerAccount, {
    fee: (100 * (TRUSTLINE_ASSETS.length + 1)).toString(),
    networkPassphrase: NETWORK_PASSPHRASE,
  }).addOperation(
    Operation.payment({ destination, asset: Asset.native(), amount: FAUCET_AMOUNTS.XLM }),
  );
  for (const a of TRUSTLINE_ASSETS) {
    tx = tx.addOperation(
      Operation.payment({
        destination,
        asset: new Asset(a.code, a.issuer),
        amount: FAUCET_AMOUNTS[a.code],
      }),
    );
  }

  const built = tx.setTimeout(60).build();
  built.sign(issuer);
  const res = await horizon.submitTransaction(built);
  if (!res.successful) throw new Error("faucet transaction failed");
}
