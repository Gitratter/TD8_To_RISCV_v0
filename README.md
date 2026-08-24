# TD8_RAM_TO_RISCV_v1

TD8由来の8bit CPUを基盤に、最小限のRV32Iサブセットへ移行した最初の動作基準版です。VGA、PS/2、テトリス、キャッシュ、パイプラインはまだ追加していません。

## v1の位置づけ

```text
TD8 board shell
├─ 1 Hz / 10 Hz clock enable
├─ 8-bit switch input
├─ 8-bit LED + seven-segment output
└─ TD8_RISCV_V1_Core
   ├─ 32-bit PC / 64-word instruction ROM
   ├─ strict RV32I-subset decoder
   ├─ 32 x 32-bit Register File
   ├─ 32-bit ALU / Immediate Generator
   └─ four 8-bit RAM banks (64 x 32-bit)
```

対応命令は次の12命令です。

```text
ADD SUB AND OR SLT
ADDI ANDI ORI SLTI
LW SW BEQ
```

詳細は[`docs/V1_SCOPE.md`](docs/V1_SCOPE.md)、[`docs/MIGRATION_NOTES.md`](docs/MIGRATION_NOTES.md)、[`docs/VERIFICATION.md`](docs/VERIFICATION.md)、[`docs/ROADMAP.md`](docs/ROADMAP.md)を参照してください。

## FPGAでの使用

1. `sources_1/new/*.v`をVivadoプロジェクトへ追加する。
2. Top moduleを`TD4_TOP`に設定する。
3. `constrs_1/new/TD8_RAM_TO_RISCV_V1.xdc`を追加する。
4. Basys 3の100 MHzクロックを使用して合成・実装する。

`clksel=0`で1命令/秒、`clksel=1`で10命令/秒です。既定ROMでは、8bitスイッチ値に1を加えた値がLEDと7セグへ表示されます。`0xFF + 1`は`0x00`へ折り返します。

## シミュレーション

自己検査テストは以下です。

- `tb_v1_io`: 既定ROM、RAM round-trip、MMIO、8bit wrap
- `tb_v1_instruction_set`: v1の全12命令、分岐成立／不成立、負即値
- `tb_v1_faults`: 未対応命令、misalignedデータアクセス／分岐先の副作用禁止
- `tb_v1_board`: TD4_TOP互換I/O、clock-enable、LED、7セグ

Icarus Verilogによる全テストの実行（リポジトリルートから）:

```powershell
pwsh -File sim_1/run_tests.ps1
```

Yosys用の合成前チェックと既定ROMのSAT smoke proofも`sim_1`に収録しています。

## 将来版の予定

1. v2: RV32I命令範囲、分岐・ジャンプ、byte/halfword accessの拡張
2. v3: 5段パイプライン、Forwarding、Stall、Flush
3. v4: VGA、VRAM、PS/2をメモリマップドI/Oとして統合し、映像・入力単体試験
4. v5: RISC-Vプログラムとしてテトリスを実行し、ゲーム動作を検証

## License

MIT License。参照元と同じライセンスを維持しています。
