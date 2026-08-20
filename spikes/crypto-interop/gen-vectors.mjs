// Node/viem reference: generate authoritative vectors for the Dart<->viem
// crypto interop spike (ticket 10). Produces vectors.json, which the Dart
// spike reads and asserts against.
//
// Vectors mirror web3-api/packages/shared/src/__tests__/{mnemonic,siwe}.test.ts
// — same canonical BIP-39 mnemonic and the published Anvil/Hardhat account #0 key.
import { mnemonicToAccount, privateKeyToAccount, signMessage } from "viem/accounts";
import { writeFileSync } from "node:fs";

const CANONICAL_MNEMONIC =
  "legal winner thank year wave sausage worth useful legal winner thank yellow";
const TEST_PK =
  "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";
const FIXED_MSG = "flowing-water interop check: Dart<->viem EIP-191";

const acct = mnemonicToAccount(CANONICAL_MNEMONIC);
const testAcct = privateKeyToAccount(TEST_PK);
const sig = await signMessage({ privateKey: TEST_PK, message: FIXED_MSG });

const vectors = {
  note: "viem-generated reference vectors for Dart<->viem crypto interop spike (ticket 10)",
  mnemonic: CANONICAL_MNEMONIC,
  derivationPath: "m/44'/60'/0'/0/0",
  derivedAddress: acct.address, // viem mnemonicToAccount(m).address
  testPrivateKey: TEST_PK,
  testAddress: testAcct.address, // expected 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
  fixedMessage: FIXED_MSG,
  fixedSignatureViem: sig, // viem EIP-191 personal_sign over FIXED_MSG with TEST_PK
};

writeFileSync("./vectors.json", JSON.stringify(vectors, null, 2) + "\n");
console.log("vectors.json written");
console.log("derivedAddress :", acct.address);
console.log("testAddress    :", testAcct.address);
console.log("fixedSignature :", sig);
