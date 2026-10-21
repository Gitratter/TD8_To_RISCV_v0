# TD8_To_RISCV_v0

A small, non-pipelined RISC-V processor in Verilog for the Digilent Basys 3. The design replaces the TD8 instruction set with a 12-instruction RV32I subset while retaining the switch input, LED output, and seven-segment display.

The RTL uses `V1` in module names; the repository name is `TD8_To_RISCV_v0`. The FPGA top is `TD4_TOP`.

## Processor

The core has a 32-bit program counter, 32 general-purpose registers, a 32-bit ALU, a 64-word instruction ROM, and 256 bytes of data RAM. Instruction and data memory are separate. Register `x0` always reads as zero.

Each clock-enable pulse executes one instruction. The board logic runs from the 100 MHz oscillator and selects either one or ten enable pulses per second. These are instruction rates, not separate clock domains.

Supported instructions:

```text
ADD  SUB  AND  OR  SLT
ADDI ANDI ORI SLTI
LW   SW   BEQ
```

Loads and stores require four-byte alignment. Illegal instructions, invalid data accesses, invalid instruction fetches, and taken branches to invalid targets assert `fault` and suppress instruction side effects. There is no trap handler or interrupt support.

## Data address map

| Address | Access | Function |
|---|---|---|
| `0x00000000`–`0x000000ff` | Aligned `LW` / `SW` | 256-byte RAM, stored in four byte banks |
| `0x00000100` | `LW` | Zero-extended eight-bit switch input |
| `0x00000104` | `LW` / `SW` | Eight-bit output register; writes use the low byte |

Other data addresses cause a fault. The instruction ROM occupies a separate 256-byte address space beginning at PC zero.

## FPGA setup

1. Create a Vivado project for the Basys 3 (`xc7a35tcpg236-1`).
2. Add the Verilog files in [sources_1/new](sources_1/new) as design sources.
3. Add [TD8_RAM_TO_RISCV_V1.xdc](constrs_1/new/TD8_RAM_TO_RISCV_V1.xdc) as the constraint file.
4. Select `TD4_TOP` as the top module, then run synthesis and implementation.
5. Inspect the timing and implementation reports before generating and loading a bitstream.

`reset` is active high. `clksel=0` selects one instruction per second; `clksel=1` selects ten. The ROM repeatedly reads the switches, adds one, passes the result through RAM, and writes the low byte to the LEDs. Input `0xff` therefore produces `0x00`. The rightmost seven-segment digit displays `out[3:0]`; `clk_ind` counts completed instructions modulo 16. An output update takes several instructions.

## Simulation

With PowerShell, Icarus Verilog, and `vvp` available, run from the repository root:

```powershell
pwsh -File sim_1/run_tests.ps1
```

| Testbench | Checks |
|---|---|
| `tb_v1_io` | ROM program, RAM round trip, MMIO, eight-bit wraparound |
| `tb_v1_instruction_set` | All 12 instructions, branch outcomes, negative immediates |
| `tb_v1_faults` | Invalid instructions and accesses; suppression of side effects |
| `tb_v1_board` | Board wrapper, clock enables, LEDs, and seven-segment output |

[sim_1](sim_1) also contains Yosys synthesis and bounded SAT scripts. These checks do not establish FPGA timing closure.

## License

[MIT](LICENSE).
