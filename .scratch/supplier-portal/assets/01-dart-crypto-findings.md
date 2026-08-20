# 加密栈可行性结论(Research 01)

> ticket:[01 — Dart 加密栈可行性](../issues/01-dart-crypto-feasibility.md)
> 结论:**可行 ✅**。所有算法均为业界标准,Dart 有成熟实现。互通要求窄。

## 上游契约(必须对齐的)

| 项 | 上游实现(Node/viem) | 互通要求 |
|---|---|---|
| 助记词 | BIP-39,128bit = 12 词,英文 wordlist(`@scure/bip39`) | 标准 ✅ |
| 派生 | EIP-44 `m/44'/60'/0'/0/0`(viem `mnemonicToAccount` 默认) | 标准 ✅ |
| 私钥 | secp256k1,32 字节,0x hex | 标准 ✅ |
| 地址 | `keccak256(pubkey[1:])` 末 20 字节 + EIP-55 checksum | 标准 ✅ |
| WS 鉴权签名 | EIP-191 `personal_sign`(`\x19Ethereum Signed Message:\n`+len+msg → keccak256 → secp256k1),r‖s‖v 65 字节 | 标准 ✅ |
| `providerSignature` | **恒为 `""`**(Ed25519 遗留,结算锚定链上 `Settled`) | **无需实现** ✅ |
| 助记词加密存储 | AES-256-GCM + PBKDF2-SHA256/100k/32B,salt16B,IV12B,authTag16B 拼密文尾 | **非互通项**(Dart 自定格式) ✅ |

### SIWE challenge(中转站构造,provider 直接签收到的字符串)

`buildChallenge` 逐字节格式:`${domain} wants you to sign in with your Ethereum account:\n${address}\n\n` + `\n` + `Nonce: ${nonce}\nExpiration Time: ${iso}`。签发时 `address` 是 `zeroAddress` 占位。provider 侧**无需重建**——收 `auth_ack.challenge` 字符串,对其 UTF-8 字节做 EIP-191 签名即可;中转站 `verifyMessage` 从签名恢复地址并比对 claimed address。

## Dart 实现方案(推荐库)

| 需要 | 推荐包 | 说明 |
|---|---|---|
| BIP-39 助记词生成/校验/→seed | `bip39` | 含 wordlist + checksum 校验(关键:别只派生 seed 而不校验) |
| BIP-32 HD 派生 secp256k1 | `hdkey` / `bip32`(secp256k1 变体) | 派生 `m/44'/60'/0'/0/0` |
| 私钥 / 地址 / 交易 | `web3dart` | `EthPrivateKey.fromHex`、`credentials.address.hexEip55`、`sendTransaction` |
| EIP-191 sign + recover | `eth_sig_util` | `signMessage` / `recoverPersonalSignature`(personal_sign 标准) |
| keccak256 | `web3dart/crypto`(或 `keccak`) | 注意是 **Keccak-256,不是 NIST SHA3-256** |
| AES-256-GCM + PBKDF2(本地存储) | `cryptography`(原生)或 `pointycastle` | `AesGcm.with256bits()` + `Pbkdf2(Hmac.sha256, 100000, 256)` |

> 包名为业界常用,实现前在 pub.dev 核对最新版与 API(见"必须做的验证")。

## 已知坑(必须验证)

1. **keccak-256 ≠ SHA3-256**:以太坊用原始 Keccak。务必用 web3dart 自带或 `keccak` 包,别用 NIST SHA3。
2. **EIP-191 v 值**:Dart 签名产 v∈{27,28};用已知向量验证 viem `verifyMessage` 能恢复(eth_sig_util 产出 27/28,正常)。
3. **BIP-39 校验**:必须校验 wordlist 成员 + checksum(像上游 `@scure/bip39`),否则拼错词会派生出"幽灵地址"。
4. **EIP-44 路径精确**:`m/44'/60'/0'/0/0`,确认 HD 库对 `'` 段做硬化派生。
5. **地址用 EIP-55**:`.hexEip55`;中转站 `isAddress(strict:false)` 接受小写/EIP-55,拒全大写。
6. **迁移现有供应商**:链上地址不可变 → 老供应商需用**同一助记词**在 Dart 重新导入(Dart 自有格式重新加密),而非迁移密文。关键迁移约束。

## 必须做的验证(spike)

写最小 Dart spike,用 Node 产出的已知向量对拍:

- 同一助记词 → Dart 派生地址 == Node 派生地址(逐字节)。
- Dart 对固定消息 EIP-191 签名 → Dart recover 恢复出同地址;最好再用 Node/viem `verifyMessage` 复核。
- (联调)Dart 握手签名 → 中转站 `auth_ack` success(依赖 04 中转站可达)。

→ 见 ticket [10 — 加密互通验证 spike](../issues/10-crypto-interop-spike.md)。

## 对 map 的影响

- **`providerSignature` 无需签名** → ticket 09(forwarder)对 01 的签名依赖**解除**,09 只剩 blocked by 03。
- 核心可行性绿灯 → "嵌入 provider-server"前提成立,下游可推进。
