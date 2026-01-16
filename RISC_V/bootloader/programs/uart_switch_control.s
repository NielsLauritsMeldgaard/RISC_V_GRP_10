# ============================================================================
# UART & Switch Controller
# ============================================================================
# Reads:
#   - Incoming UART bytes ? display on 7-segment
#   - Switch inputs ? light up corresponding LEDs
# ============================================================================


_start:
    # Initialize IO register addresses
    li      t0, 0x40000000      # LED/Switch register
    li      t1, 0x40000004      # 7-Segment display register
    li      t2, 0x40000008      # UART status/data register
    
main_loop:
    # ---- Read switches and update LEDs ----
    lw      t3, 0(t0)           # Load switch/LED register
    li      t6, 0xFFFF0000    
    and     t3, t3, t6           # Extract switches (upper 16 bits)
    srli    t3, t3, 16          # Shift switches down to lower 16 bits
    sw      t3, 0(t0)           # Write switch value to LEDs (lower 16 bits)
    
    # ---- Wait for UART data ----
    lw      t4, 0(t2)           # Load UART status register
    andi    t4, t4, 0x100       # Check rx_valid bit [8]
    beq     t4, x0, main_loop   # If no data, loop back
    
    # ---- Read the received byte ----
    lw      t5, 0(t2)           # Load UART status/data again
    andi    t5, t5, 0xFF        # Extract rx_data bits [7:0]
    
    # ---- Display byte on 7-segment ----
    sw      t5, 0(t1)           # Write byte to 7-segment display (0x4000_0004)
    
    # ---- Loop back ----
    beq    zero, zero, main_loop