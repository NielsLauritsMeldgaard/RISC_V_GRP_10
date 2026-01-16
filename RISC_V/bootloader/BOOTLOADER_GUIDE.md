# RISC-V Bootloader: UART Program Loader

## Overview

The bootloader is a small RISC-V program that runs from bootloader ROM at startup. It:
1. **Waits for UART input** from the testbench or external device
2. **Assembles bytes into 32-bit instructions** (little-endian format)
3. **Writes instructions to instruction memory** at address 0x1000_0000
4. **Jumps to the loaded program** when transmission is complete

## Architecture

### Memory Layout

```
┌─────────────────────────────────────────┐
│ 0x0000_0000 - 0x0000_FFFF              │
│ Bootloader ROM (4KB)                   │
│ • Reads UART                           │
│ • Writes to Instruction Memory         │
└─────────────────────────────────────────┘
         ↓ (LUIPC/JALR jump)
┌─────────────────────────────────────────┐
│ 0x1000_0000 - 0x1003_FFFF              │
│ Instruction Memory (128KB, writable)   │
│ • Port A: Write via Data Wishbone      │
│ • Port B: Read via Instr Wishbone      │
│ • Bootloader loads program here        │
│ • CPU executes from here               │
└─────────────────────────────────────────┘
         ↓ (Data load/store)
┌─────────────────────────────────────────┐
│ 0x2000_0000 - 0x2000_FFFF              │
│ Data Memory (64KB)                     │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ 0x4000_0000 - 0x4000_FFFF              │
│ I/O Peripherals (LEDs, UART, etc.)     │
└─────────────────────────────────────────┘
```

### UART Interface

**Memory-Mapped Register at 0x4000_0008:**

```
Bits [7:0]   - rx_data: Received byte from UART
Bit  [8]     - rx_valid: Data available (set by UART, clear after read)
Bit  [9]     - tx_busy: Transmitter busy
```

**Protocol:**
- Bootloader reads register at 0x4000_0008
- Checks if bit [8] (rx_valid) is set
- If set, extracts byte from bits [7:0]
- Repeats until 0xFF byte received (termination signal)

## Bootloader Code

### File: `bootloader.s`

The assembly bootloader implements:

1. **Initialization**
   - t0 = Instruction memory write pointer (0x1000_0000)
   - t1 = UART register address (0x4000_0008)
   - t2 = Instruction accumulator
   - t3 = Byte counter (0-3)

2. **Read Loop**
   ```assembly
   read_loop:
       lw      t5, 0(t1)          # Load UART status
       andi    t5, t5, 0x100      # Check rx_valid bit
       beq     t5, x0, read_loop  # Wait for data
       
       lw      t5, 0(t1)          # Get byte
       andi    t5, t5, 0xFF
   ```

3. **Byte Assembly**
   ```assembly
   # Assemble 4 bytes into 32-bit word (little-endian)
   # Byte order: [byte0 | byte1 | byte2 | byte3]
   sll     t5, t5, t3             # Shift to correct position
   or      t2, t2, t5             # Accumulate
   ```

4. **Memory Write**
   ```assembly
   # When 4 bytes collected:
   sw      t2, 0(t0)              # Write to instruction memory
   addi    t0, t0, 4              # Advance pointer
   ```

5. **Jump to Program**
   ```assembly
   boot_complete:
       li      t0, 0x10000000
       jalr    x0, 0(t0)          # Jump to loaded program
   ```

## Using the Bootloader

### Step 1: Compile Bootloader

```bash
riscv64-unknown-elf-as bootloader.s -o bootloader.o
riscv64-unknown-elf-objcopy -O binary bootloader.o bootloader.bin
riscv64-unknown-elf-objdump -d bootloader.o > bootloader.lst
```

Convert to Verilog hex for bootloader ROM:
```bash
python bin_to_mem.py bootloader.bin bootloader.mem
```

Update `bootloader_rom.sv` with generated `.mem` file.

### Step 2: Compile User Program

```bash
riscv64-unknown-elf-as program.s -o program.o
riscv64-unknown-elf-objcopy -O binary program.o program.bin
```

### Step 3: Convert Program to UART Bytes

```bash
python uart_loader.py program.bin -o program_uart
```

This generates `program_uart.uart` containing the byte sequence to inject via UART.

### Step 4: Run Simulation with UART Injection

In your testbench, inject bytes from `program_uart.uart`:

```systemverilog
// Pseudo-code for testbench
logic [7:0] uart_byte;
int uart_file;

initial begin
    uart_file = $fopen("program_uart.uart", "r");
    
    while ($fscanf(uart_file, "%h", uart_byte) != -1) begin
        // Inject byte into UART receiver simulation
        inject_uart_byte(uart_byte);
        wait_for_rx_ready();
    end
    
    // Send termination byte
    inject_uart_byte(8'hFF);
    
    // Wait for bootloader to jump to program
    wait(bootloader_complete);
    
    // Program now running in instruction memory
end
```

Or use the existing `run_testbench.py` with UART injection capability.

## Byte Format (Little-Endian)

The bootloader assembles bytes in little-endian format:

**Example:** Instruction `0x12345678`

```
UART transmission order:
  Byte 0: 0x78  (bits [7:0])
  Byte 1: 0x56  (bits [15:8])
  Byte 2: 0x34  (bits [23:16])
  Byte 3: 0x12  (bits [31:24])

Assembled in memory:
  [0x12][0x34][0x56][0x78]  →  0x12345678 when read as word
```

## Termination Signal

Send **0xFF** (255) as the last byte to signal end of program. Bootloader will:
1. Stop reading
2. Jump to 0x1000_0000
3. Begin executing loaded program

## Debugging

### Check UART Status
```riscv
# Read UART register
li      t0, 0x40000008
lw      t1, 0(t0)
# Bit [8] should be 1 when data available
# Bits [7:0] contain the received byte
```

### Monitor Instruction Memory
In simulation, observe writes to 0x1000_0000:
```systemverilog
always @(posedge clk) begin
    if (dut.dwb_we && dut.dwb_adr[31:28] == 4'h1) begin
        $display("IRAM Write: [%08h] = %08h", dut.dwb_adr, dut.dwb_dat_o);
    end
end
```

### Verify Program Jumps Correctly
```systemverilog
always @(posedge clk) begin
    if (dut.if_stage.pc_w >= 32'h1000_0000) begin
        $display("✓ CPU jumped to loaded program at %08h", dut.if_stage.pc_w);
    end
end
```

## Limitations & Future Improvements

### Current Implementation
- ✓ Simple byte-by-byte protocol
- ✓ Little-endian assembly
- ✓ 8KB (2048 instruction) size limit
- ✓ Single magic terminator (0xFF)

### Potential Improvements
- [ ] Checksum/CRC validation
- [ ] Variable program size (use header byte for size)
- [ ] Compression (if bandwidth is limited)
- [ ] Progress indicator (echo back status)
- [ ] Hardware RX FIFO integration
- [ ] DMA-based bulk transfer

## Testing the Bootloader

### Simulation Test Flow

```
1. Load bootloader into bootloader ROM
2. Start simulation
3. Bootloader waits for UART data
4. Inject test program bytes via UART (or $readmemb simulation memory)
5. Send termination byte (0xFF)
6. Observe CPU PC jump to 0x1000_0000
7. Verify program execution (monitor register writes, ECALL)
8. Compare results with expected output
```

### Command Example
```bash
# Compile bootloader
python bin_to_mem.py bootloader.bin bootloader.mem

# Create test program UART bytes
python uart_loader.py tests/task1/addpos.bin -o task1_uart --hex

# Run simulation with injection
python run_testbench.py --task task1 --uart task1_uart.uart
```

## File Structure

```
RISC_V_GRP_10/
├── bootloader.s              ← Bootloader assembly source
├── uart_loader.py            ← Convert binary → UART bytes
│
├── RISC_V/RISC_V.srcs/sources_1/new/
│   ├── bootloader_rom.sv     ← Bootloader ROM (reads bootloader.bin)
│   ├── instruction_memory.sv ← Dual-port IRAM
│   ├── iwb_interconnect.sv   ← Routes instr bus
│   ├── wb_interconnect.sv    ← Routes data bus
│   ├── io_manager.sv         ← UART + peripherals
│   └── datapath.sv           ← Top-level
│
└── tests/
    ├── task1/
    │   ├── addpos.bin        ← Compiled program
    │   ├── addpos.uart       ← UART bytes
    │   └── addpos.res        ← Expected results
    └── ...
```

## Questions & Troubleshooting

**Q: Why little-endian?**
A: Follows RISC-V standard. Byte 0 (LSB) is transmitted first, matching how the bootloader shifts them into the word.

**Q: What if program size > 32KB?**
A: Currently limited to 32KB. Extend by modifying the limit in bootloader.s (line: `addi t6, x0, 8192`).

**Q: Can I send data while bootloader waits?**
A: Yes, the UART receiver is always active. Data frames are independent.

**Q: How do I know when loading completes?**
A: When PC jumps to 0x1000_0000 (observable in simulation or via LED indicator).

