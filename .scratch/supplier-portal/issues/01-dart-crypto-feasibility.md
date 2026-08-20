# 01 — Dart 加密栈可行性

Type: research
Status: resolved

## Question

在 Dart/Flutter 中能否完整复刻 provider-server 的加密栈,且**与中转站(Node/viem)互通**?具体四项:

1. BIP-39 12 词助记词生成 + secp256k1 keypair 派生(得供应商地址)。
2. EIP-191 `personal_sign` 签名(WS 的 SIWE 鉴权 + `llm_response`/`llm_stream_end` 的 `providerSignature`)。
3. 由签名恢复 / 校验地址(确保与 Node 侧 `verifyMessage` 等价)。
4. AES-256-GCM 加密存储助记词(口令派生 key)——替换方可自定格式,无需与 Node 互通。

## Context

- 上游实现:`../web3-api/packages/shared/src/crypto/`(sign/verify/keypair/加密)、provider-server 的 keypair 管理(`POST /import`、`/load`)。
- 中转站校验侧:`web3-api/packages/relay-server/src/ws/auth.ts`(normalize address / verifyMessage / nonce 防重放 / 60s 过期)。
- **这是最高风险项**:若 Dart 加密与 viem 不互通,WS 鉴权过不了,整个"嵌入 provider-server"前提崩。

## Done looks like

一份 markdown 总结:每项 yes/no + 推荐 Dart 库(web3dart / walletconnect / pointycastle / `cryptography` 等)+ 互通验证(同一助记词→同一地址;同一消息→中转站验签通过)+ 已知坑。若某项 no,给替代 / 规避方案。资产链接挂本 ticket。

## Answer

**结论:可行 ✅。** 所有算法(BIP-39 / EIP-44 / secp256k1 / keccak256 / EIP-191 personal_sign / AES-256-GCM+PBKDF2)均为业界标准,Dart 有成熟实现(`web3dart` + `eth_sig_util` + `bip39` + `hdkey` + `cryptography`/`pointycastle`)。互通要求窄:① 同一助记词→同一地址(迁移现有供应商必需);② 标准 EIP-191 签名能被中转站 `verifyMessage` 通过。

**两个关键利好,大幅降风险:**

- `providerSignature`(llm_response / llm_stream_end)在上游**恒为 `""`**(Ed25519 遗留,结算改锚定链上 `Settled`)→ **无需任何签名**,解除 ticket 09 对 01 的签名依赖。
- AES 助记词存储是**本地格式**(Dart 取代 Node,不读 Node 密文)→ 格式自定,非互通项。

**关键约束(迁移):** 老供应商链上地址不可变 → 必须用**同一助记词**在 Dart 重新导入(Dart 自有格式重新加密),不迁移密文。

详见 [加密栈可行性结论](../assets/01-dart-crypto-findings.md)。落地前需一个对拍 spike(见 [10 — 加密互通验证 spike](10-crypto-interop-spike.md))。
