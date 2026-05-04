# ============================================================================
# LED Blink - Hardware "Hello World"
# ============================================================================
# Blinks LED 0 on the FPGA board indefinitely
# LED register at 0x4000_0000, lower 16 bits control LEDs
# ============================================================================

_start:
    # Initialize LED register address
    li      t0, 0x40000000      # t0 = LED register base address
    
    # LED blink value (LED 0 = bit 0)
    li      t1, 0x0001          # t1 = LED pattern (0000_0001 = LED 0 on)
    li      t2, 0x0000          # t2 = LED off pattern
    
    # Delay counter
    li      t3, 25000000         # ~1 second delay at 100MHz clock
    
blink_loop:
    # Turn LED ON
    sw      t1, 0(t0)           # Write 0x0001 to LED register
    
    # Delay
    li      t4, 0               # Counter = 0
delay_on:
    addi    t4, t4, 1           # Increment counter
    blt     t4, t3, delay_on    # Loop if counter < 2000000
    
    # Turn LED OFF
    sw      t2, 0(t0)           # Write 0x0000 to LED register
    
    # Delay
    li      t4, 0               # Counter = 0
delay_off:
    addi    t4, t4, 1           # Increment counter
    blt     t4, t3, delay_off   # Loop if counter < 2000000
    
    # Loop back to ON
    beq zero, zero     blink_loop