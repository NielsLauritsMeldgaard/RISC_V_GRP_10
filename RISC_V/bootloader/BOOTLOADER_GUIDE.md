# RISC-V UART Bootloader

## Overview

The bootloader loads RISC-V programs into instruction memory over UART at startup. It:
1. Reads bytes from UART (0x4000_0008)
2. Assembles them into 32-bit words (little-endian)
3. Writes words to instruction memory (0x1000_0000)
4. Detects magic terminator (0xDEADBEEF) and jumps to program start

## Memory Map

| Address Range | Description |
|--------------|-------------|
| 0x0000_0000 - 0x0000_FFFF | Bootloader ROM (read-only, runs at reset) |
| 0x1000_0000 - 0x1001_FFFF | Instruction Memory (128KB, dual-port, writable) |
| 0x2000_0000 - 0x2000_FFFF | Data Memory (64KB) |
| 0x4000_0000 - 0x4FFF_FFFF | I/O Peripherals (UART at 0x4000_0008) |

## UART Protocol

**Register: 0x4000_0008**
- Bits [7:0]: `rx_data` (received byte)
- Bit [8]: `tx_busy` (transmitter busy)
- Bit [9]: `rx_valid` (new data available, cleared on read)

**Upload Format:**
- Send program bytes in little-endian order
- Append 4-byte magic terminator: `0xDEADBEEF` (as `EF BE AD DE` on wire)
- Bootloader stops loading and jumps to 0x1000_0000 when magic is detected

**Example:** Instruction `0x12345678` → Send bytes: `78 56 34 12`

## Usage

### 1. Compile Your Program

```bash
riscv64-unknown-elf-as program.s -o program.o
riscv64-unknown-elf-objcopy -O binary program.o program.bin
```

### 2. Upload via UART

```bash
python uart_loader.py program.bin --port COM10 --baud 115200
```

The script automatically:
- Pads binary to 4-byte boundary
- Appends magic terminator (0xDEADBEEF)
- Shows progress bar during upload

### 3. Quick Upload with Batch Script

Edit `upload_program.bat` to set your program path and port:
```bat
set "PROGRAM=programs/hello_world.bin"
set "PORT=COM10"
set "BAUD=115200"
```

Then run:
```bash
upload_program.bat
```

## Bootloader Source

**File: `bootloader.s`**

Key steps:
1. Initialize registers (UART=0x4000_0008, IRAM_PTR=0x1000_0000)
2. Wait for UART byte (poll bit 9 of 0x4000_0008)
3. Accumulate 4 bytes into 32-bit word (little-endian)
4. Write word to instruction memory, increment pointer
5. Compare word to magic (0xDEADBEEF); if match, jump to 0x1000_0000
6. Repeat until magic detected

## Files

```
bootloader/
├── bootloader.s           # Bootloader assembly source
├── bootloader.bin         # Compiled bootloader binary
├── bootloader.mem         # Hex format for bootloader ROM
├── uart_loader.py         # Python upload script
├── upload_program.bat     # Windows batch upload script
└── programs/              # User programs to upload
    ├── hello_world.bin
    └── ...
```

## Troubleshooting

**Program doesn't run after upload:**
- Verify UART baud rate matches (115200)
- Check that magic word is appended (uart_loader.py does this automatically)
- Confirm program starts at 0x1000_0000 in your linker script

**Upload stalls:**
- Check COM port number (Windows Device Manager)
- Verify FPGA is programmed with bootloader ROM
- Reset FPGA before uploading

**Incorrect execution:**
- Verify little-endian byte order in .bin file
- Check instruction memory size (max 128KB)
- Examine bootloader.mem in simulation for proper loading

## Technical Details

**Dual-Port Instruction Memory:**
- Port A (Data Wishbone): Write access for bootloader at 0x1000_0000
- Port B (Instruction Wishbone): Read access for CPU instruction fetch

**Magic Word:** `0xDEADBEEF` chosen to be unlikely in normal code. Not stored in memory.

**Maximum Program Size:** 128KB (32,768 instructions)


