.globl _start

_start:
    li t0, 0x40000000      # switches and leds
    li t3, 0x4000000c      # buttons

main:
    lw t4, 0(t3)           # load buttons status register
    
    # Extract UP button (bit 0 of d_buttons = bit 18 of t4)
    srli t5, t4, 9          # Shift right 9 positions to get d_buttons in lower bits
    andi t5, t5, 0xF       # Mask to get just bit 0 (UP button)
    
    beqz t5, skip_led      # If UP not pressed, skip LED write
    
    # UP button is pressed - write 0x01 to LEDs
    sw t5, 0(t0)
    j main
    
skip_led:
    # UP not pressed - turn off LEDs
    li t5, 0x00
    sw t5, 0(t0)
    j main

end:
    j end