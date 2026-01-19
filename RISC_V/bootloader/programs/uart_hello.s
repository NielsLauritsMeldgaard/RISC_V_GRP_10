# ============================================================================
# Hello World via UART
# ============================================================================
# Transmits "Hello World!" one character at a time over UART (115200, 8N1)
# ============================================================================

_start:
    # Initialize IO register addresses
    li      t0, 0x40000008      # UART status/data register
    li      t1, msg_start       # Pointer to string start (address of msg)
    
main_loop:
    # ---- 1. Load next character ----
    lb      t2, 0(t1)           # Load byte from message
    beq     t2, x0, done        # If null terminator, jump to done
    
    # ---- 2. Wait for UART to be ready ----
check_busy:
    lw      t3, 0(t0)           # Load UART status
    andi    t3, t3, 0x100       # Check Busy Bit [8]
    bne     t3, x0, check_busy  # If Busy (t3 != 0), loop and check again
    
    # ---- 3. Send character ----
    sw      t2, 0(t0)           # Write character to UART TX
    
    # ---- 4. Move to next character ----
    addi    t1, t1, 1           # Increment string pointer
    beq     zero, zero, main_loop # Loop back
    
done:
    # Halt by returning to done
    beq     zero, zero, done

# ---- Message String (Null-terminated) ----
.data
msg_start:
    .string "Hello World!"

# ---- Program Terminator ----
_end:
    ecall                       # End of program marker
