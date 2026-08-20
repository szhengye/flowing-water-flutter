# 10 — 加密互通验证 spike

Type: task
Status: resolved

## Question

写一个最小 Dart spike,用 Node/viem 产出的已知向量对拍,实证 [01](01-dart-crypto-feasibility.md) 的可行性结论:

1. **助记词→地址对拍**:同一 12 词助记词,Dart 派生地址 == Node(viem `mnemonicToAccount`)派生地址,逐字节一致。
2. **EIP-191 签名对拍**:Dart 对固定消息 personal_sign → recover 恢复出同地址;再用 Node `verifyMessage` 复核通过。
3. **(联调,依赖 04)中转站握手**:Dart 生成 keypair → 连中转站 → 收 challenge → EIP-191 签名 → `auth_ack` success。

## Context

- 01 结论:可行,但落地前必须用真实向量验证(keccak≠SHA3、v 值、BIP-39 校验、EIP-44 路径等坑)。
- 上游向量源:`../web3-api/packages/shared/src/__tests__/`(若有 crypto 测试向量)或现场用 Node 跑 viem 生成。
- 推荐库见 [01 结论资产](../assets/01-dart-crypto-findings.md)。
- 第 3 步依赖 [04](04-relay-connection-and-handshake.md)(中转站可达);前两步现在就能做。

## Done looks like

可跑的 Dart spike(资产链接)+ 三项对拍结果(通过 / 不通过 + 原因)。这是所有"用供应商身份连中转站"的实现前提。

## Answer

**实测通过 ✅(第 1、2 项;第 3 项握手待 04)。** spike 在 `../../../spikes/crypto-interop/`(Dart + Node/viem 对照),完整结果见 [RESULTS.md](../../../spikes/crypto-interop/RESULTS.md)。

对拍结果(viem 权威向量):

1. **助记词→地址**:Dart(BIP-39 seed + BIP-32 `m/44'/60'/0'/0/0` + web3dart)派生地址 == viem `0x58A57ed9d8d624cBD12e2C467D34787555bB1b25`。✅
2. **私钥→地址**:Anvil #0 私钥 → `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`。✅
3. **EIP-191 签名互通**:Dart(eth_sig_util)对固定消息签名 → `recoverPersonalSignature` 恢复出同地址 ✅;且 **Dart 签名与 viem 签名逐字节相同**(两端均 RFC6979 确定性 ECDSA)→ `viem.verifyMessage(Dart sig) = true`。✅

**结论**:`web3dart + eth_sig_util + bip39 + bip32` 这组库与中转站(viem)**完全互通**;01 列的已知坑均未触发。可用库栈锁定。

**未做(待 04)**:真实中转站 WS 握手联调(Dart 签 challenge → `auth_ack` success)——需中转站可达。
