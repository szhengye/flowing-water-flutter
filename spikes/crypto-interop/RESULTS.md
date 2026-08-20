# Crypto 互通 spike — 结果(ticket 10)

Dart(`web3dart` + `eth_sig_util` + `bip39` + `bip32`)<-> Node/viem 加密互通验证。

## 结论:全通 ✅

| # | 检查 | 结果 |
|---|---|---|
| 1 | 助记词→地址(BIP-39 + BIP-32 `m/44'/60'/0'/0/0` + web3dart)== viem | ✅ `0x58A57ed9d8d624cBD12e2C467D34787555bB1b25` |
| 2 | Anvil #0 私钥→地址 == 已知地址 | ✅ `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266` |
| 3 | EIP-191 签名:Dart sign → recover 自洽 | ✅ |
| 4 | **Dart 签名 == viem 签名(逐字节相同)** | ✅ 同 `0xfd592fb8…1c`(两端均 RFC6979 确定性 ECDSA) |
| 5 | `viem.verifyMessage(Dart 签名)` | ✅ true |

01 列出的已知坑(keccak≠SHA3、v 值、BIP-39 校验、EIP-44 路径)均**未触发**。

## 向量来源

- 助记词:`legal winner thank year wave sausage worth useful legal winner thank yellow`(BIP-39 Trezor 标准向量,同 `web3-api/packages/shared/src/__tests__/mnemonic.test.ts`)。
- 测试私钥:Anvil/Hardhat account #0 `0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80`(公开测试键,同 `siwe.test.ts`)。
- 由 `node gen-vectors.mjs`(viem)生成 `vectors.json` 作权威基准。

## 复现

```bash
cd spikes/crypto-interop
npm install                 # viem
node gen-vectors.mjs        # 产 vectors.json
cd dart-spike && dart pub get
dart run bin/interop.dart   # Dart 三项自验 + 写 dart-signature.txt
cd .. && node verify-dart.mjs   # viem 反验 Dart 签名
```

## 未做(待 ticket 04)

真实中转站 WS 握手联调(Dart 签 challenge → `auth_ack` success)——需中转站可达。

## 文件

- `gen-vectors.mjs` / `verify-dart.mjs` — Node/viem 对照侧。
- `vectors.json` — viem 权威向量(助记词、派生地址、Anvil #0、固定消息+签名)。
- `dart-spike/bin/interop.dart` — Dart 对拍脚本。
- `dart-signature.txt` — Dart 产出的签名,供 viem 反验。
