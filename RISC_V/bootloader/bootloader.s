# ============================================================================
# Simple UART Bootloader with Magic Terminator
# - UART base: 0x4000_0008 (status/data)
# - instr RAM write port: 0x1000_0000 (data-bus access)
# - Terminates on magic word 0xDEADBEEF (LE stream); magic is NOT stored.
# ============================================================================

_start:
    li      t0, 0x40000008      # UART status/data
    li      t1, 0x10000000      # Instr RAM write pointer
    li      t6, 0xDEADBEEF      # Magic terminator word
    li      t4, 0               # shift amount in bits (0,8,16,24)
    li      t3, 0               # word accumulator
    li      a0, 0

read_byte:
    # Wait for rx_valid (bit 9 = 0x200)
wait_valid:
    lw      t5, 0(t0)
    andi    t5, t5, 0x200
    beq     t5, x0, wait_valid

    # Read byte and insert at current shift
    lw      t2, 0(t0)           # data in [7:0]
    li      a0, 0xFF
    and     t2, t2, a0
    sll     t2, t2, t4          # shift by 0/8/16/24
    or      t3, t3, t2          # accumulate

    addi    t4, t4, 8           # shift += 8
    bne     t4, zero, check_full  # if t4 != 0 (after increment), fall through check_full

check_full:
    # When shift == 32 (i.e., t4 == 32), we have a full word
    li      t5, 32
    bne     t4, t5, read_byte   # not full yet -> continue reading

    # Full word in t3
    beq     t3, t6, jump_run    # magic? -> done, don't store
    sw      t3, 0(t1)           # store word to instruction RAM
    addi    t1, t1, 4           # advance pointer

    # reset accumulator
    li      t3, 0
    li      t4, 0
    beq     zero, zero, read_byte

jump_run:
    li      t3, 0x10000000
    jalr    x0, t3, 0           # jump to loaded program