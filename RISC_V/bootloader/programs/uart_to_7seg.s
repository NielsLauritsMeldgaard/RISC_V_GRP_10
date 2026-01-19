# ============================================================================
# UART to 7-Segment Display
# ============================================================================
# Reads incoming UART bytes and displays them on 7-segment display
# ============================================================================

_start:
    li      t0, 0x40000004      # 7-Segment display register
    li      t1, 0x40000008      # UART status/data register
    
main_loop:
    # ---- Wait for UART data ----
    lw      t2, 0(t1)           # Load UART status register
    andi    t2, t2, 0x200       # Check rx_valid bit [9]
    beq     t2, x0, main_loop   # If no data, loop back
    
    # ---- Read the received byte ----
    lw      t3, 0(t1)           # Load UART status/data
    andi    t3, t3, 0xFF        # Extract rx_data bits [7:0]
    
    # ---- Display byte on 7-segment ----
    sw      t3, 0(t0)           # Write byte to 7-segment display
    
    # ---- Loop back ----
    beq     zero, zero, main_loop
