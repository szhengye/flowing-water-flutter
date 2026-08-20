// Node/viem reference: verify a signature produced by the Dart spike over the
// fixed message, using viem's verifyMessage (the exact function the relay uses
// in web3-api/packages/relay-server/src/ws/auth.ts). This is the cross-impl
// interop check — Dart signs, viem must accept.
import { verifyMessage } from "viem";
import { readFileSync } from "node:fs";

const v = JSON.parse(readFileSync("./vectors.json", "utf8"));
const dartSig = readFileSync("./dart-signature.txt", "utf8").trim();

const ok = await verifyMessage({
  address: v.testAddress,
  message: v.fixedMessage,
  signature: dartSig,
});

console.log("viem.verifyMessage(Dart signature) =", ok);
process.exit(ok ? 0 : 1);
