# ============================================================================
# RISC-V Bootloader - UART to Instruction Memory Loader
# ============================================================================
# Purpose: Read bytecode from UART and write to instruction memory (0x1xxx)
# Memory Layout:
#   - Bootloader ROM executes from 0x0 (this code)
#   - Instruction Memory writable at 0x1000_0000
#   - UART Status/Data Register at 0x4000_0008
#     * Bit [0:7] = rx_data (received byte)
#     * Bit [8]   = rx_valid (data available)
#     * Bit [9]   = tx_busy
# ============================================================================

_start:
    # ========== Initialize Registers ==========
    # t0 = instruction memory write address (0x1000_0000)
    li      t0, 0x10000000
    
    # t1 = UART status register address (0x4000_0008)
    li      t1, 0x40000008
    
    # t2 = accumulated 32-bit instruction
    li     t2, 0          # t2 = 0
    
    # t3 = byte counter within word (0-3)
    li     t3, 0          # t3 = 0
    
    # t4 = instruction counter (for debugging/timeout)
    li     t4, 0          # t4 = 0
    
    # ========== Main Loop: Read Bytes and Assemble Instructions ==========
read_loop:
    # ---- Wait for UART data available ----
    lw      t5, 0(t1)           # Load UART status register
    andi    t5, t5, 0x100       # Check rx_valid bit [8]
    beq     t5, x0, read_loop   # If no data, loop back
    
    # ---- Read the received byte ----
    lw      t5, 0(t1)           # Load UART status register again
    andi    t5, t5, 0xFF        # Extract rx_data [7:0]
    
    # ---- Check for bootloader termination sequence ----
    # Magic bytes: 0xFF triggers bootloader completion
    li    t6, 0xFF
    beq     t5, t6, boot_complete
    
    # ---- Assemble 4 bytes into 32-bit word (little-endian) ----
    # Byte 0 goes to bits [7:0], Byte 1 to [15:8], etc.
    sll     t5, t5, t3          # Shift byte to correct position (t3 * 8 bits)
    or      t2, t2, t5          # Accumulate byte into instruction
    
    # ---- Check if we have 4 bytes ----
    addi    t3, t3, 1           # Increment byte counter
    li      t6, 4
    bne     t3, t6, read_loop   # If not 4 bytes yet, read next byte
    
    # ========== Write 32-bit Instruction to Memory ==========
    sw      t2, 0(t0)           # Write instruction to current memory address
    
    # ---- Prepare for next instruction ----
    addi    t0, t0, 4           # Advance write address by 4 bytes
    li      t2, 0               # Reset instruction accumulator
    li      t3, 0               # Reset byte counter
    addi    t4, t4, 1           # Increment instruction counter
    
    # Safety limit: max 8192 instructions (32KB) to prevent infinite loop
    li    t6, 8192
    blt     t4, t6, read_loop   # Continue loading if under limit
    
    # ========== Bootloader Complete: Jump to Loaded Program ==========
boot_complete:
    # Calculate jump address (loaded program starts at 0x1000_0000)
    li      t0, 0x10000000      # Load program entry point
    jalr    x0, t0, 0           # Jump to loaded program (pc = t0, link register unused)
    
    # Infinite loop (should never reach here)
infinite_loop:
    j       infinite_loop
