###############################################################################
# GCD Calculator + UART Output (Working Version)
# - Uses switches for input
# - Button UP to latch A, then B
# - Computes GCD
# - Prints result over UART
###############################################################################

.globl _start

_start:
    # IO base addresses
    li a0, 0x40000000      # switches/LEDs
    li a1, 0x4000000c      # buttons
    li a2, 0x40000004      # seven-seg
    li a3, 0x40000008      # UART TX/RX

    # Initialize registers
    li s0, 0               # operand A
    li s1, 0               # operand B
    li s2, 0               # GCD result
    li s3, 0               # state: 0=selA,1=selB,2=done
    li s4, 0               # LED shadow
    li s5, 0               # button edge tracker

    li sp, 0x2000FFC       # stack pointer

main:
    # Read switches for display (upper 16 bits)
    lw t0, 0(a0)
    srli t0, t0, 16

    # Display logic
    beq s3, zero, disp_sw
    li t1, 1
    beq s3, t1, disp_sw

    # State 2: show result
    sw s2, 0(a2)
    j poll_btn

disp_sw:
    # State 0 or 1: show current switches
    sw t0, 0(a2)

poll_btn:
    # Read UP button (bit 9)
    lw t1, 0(a1)
    srli t1, t1, 9
    andi t1, t1, 1

    # Edge detect: trigger only on 0->1
    beq s5, t1, main       # no change
    mv s5, t1
    beq t1, zero, main     # only act on press

    # Read switches NOW at the moment of press
    lw t0, 0(a0)
    srli t0, t0, 16

    # Branch based on state
    beq s3, zero, latch_A
    li t2, 1
    beq s3, t2, latch_B

    # State 2: restart
    li s0, 0
    li s1, 0
    li s2, 0
    li s3, 0
    li s4, 0
    sw x0, 0(a0)
    j main

latch_A:
    mv s0, t0
    ori s4, s4, 0x0001     # LED0
    sw s4, 0(a0)
    li s3, 1               # next: select B
    j main

latch_B:
    mv s1, t0
    ori s4, s4, 0x0002     # LED1
    sw s4, 0(a0)

    # Compute GCD(s0,s1) via Euclidean algorithm
    mv t3, s0
    mv t4, s1

gcd_loop:
    beq t3, t4, gcd_done
    beq t3, zero, gcd_store_b
    beq t4, zero, gcd_store_a
    bgeu t3, t4, sub_a
    sub t4, t4, t3
    j gcd_loop

sub_a:
    sub t3, t3, t4
    j gcd_loop

gcd_store_a:
    mv s2, t3
    j gcd_done

gcd_store_b:
    mv s2, t4

gcd_done:
    mv s2, t3
    ori s4, s4, 0x0004     # LED2
    sw s4, 0(a0)
    sw s2, 0(a2)

    # Print result over UART
    jal print_msg

    li s3, 2               # done
    j main

###############################################################################
# UART Helpers
###############################################################################

# Send character in t2 via UART
uart_putc:
check_busy:
    li a3, 0x40000008      # guard UART base each call
    li t4, 200000          # busy-wait timeout
check_busy_loop:
    lw t5, 0(a3)
    andi t5, t5, 0x100
    beqz t5, uart_ready    # if not busy, send
    addi t4, t4, -1
    bnez t4, check_busy_loop
    # timeout reached: proceed to send anyway
uart_ready:
    sw t2, 0(a3)
    # tiny settling delay
    li t5, 256
post_tx_delay:
    addi t5, t5, -1
    bnez t5, post_tx_delay
    ret

# Print 16-bit value in t0 as 0xHHHH
print_hex16:
    mv s7, ra                 # save return address (no stack)

    mv t6, t0                 # value to print

    li t2, 0x30               # '0'
    jal uart_putc
    li t2, 0x78               # 'x'
    jal uart_putc

    srli t1, t6, 12
    jal print_hex_nibble
    srli t1, t6, 8
    jal print_hex_nibble
    srli t1, t6, 4
    jal print_hex_nibble
    mv t1, t6
    jal print_hex_nibble

    mv ra, s7                 # restore return address
    ret

# Print 4-bit nibble in t1 as hex
print_hex_nibble:
    mv s8, ra                 # save return address (no stack)

    andi t1, t1, 0xF
    li t3, 10
    blt t1, t3, hex_digit_num

    addi t2, t1, 0x37         # 'A'-'F'
    jal uart_putc
    mv ra, s8
    ret

hex_digit_num:
    addi t2, t1, 0x30         # '0'-'9'
    jal uart_putc
    mv ra, s8
    ret

# Print full message: "The GCD of 0xXXXX and 0xXXXX is: 0xXXXX\n"
print_msg:
    mv s6, ra                 # save return address (no stack)

    # Print fixed string
    li t2, 0x54  # 'T'
    jal uart_putc
    li t2, 0x68  # 'h'
    jal uart_putc
    li t2, 0x65  # 'e'
    jal uart_putc
    li t2, 0x20
    jal uart_putc
    li t2, 0x47  # 'G'
    jal uart_putc
    li t2, 0x43  # 'C'
    jal uart_putc
    li t2, 0x44  # 'D'
    jal uart_putc
    li t2, 0x20
    jal uart_putc
    li t2, 0x6F  # 'o'
    jal uart_putc
    li t2, 0x66  # 'f'
    jal uart_putc
    li t2, 0x20
    jal uart_putc

    # Operand A
    mv t0, s0
    jal print_hex16

    li t2, 0x20
    jal uart_putc
    li t2, 0x61
    jal uart_putc
    li t2, 0x6E
    jal uart_putc
    li t2, 0x64
    jal uart_putc
    li t2, 0x20
    jal uart_putc

    # Operand B
    mv t0, s1
    jal print_hex16

    li t2, 0x20
    jal uart_putc
    li t2, 0x69
    jal uart_putc
    li t2, 0x73
    jal uart_putc
    li t2, 0x3A
    jal uart_putc
    li t2, 0x20
    jal uart_putc

    # Result
    mv t0, s2
    jal print_hex16

    li t2, 0x0A    # newline
    jal uart_putc

    li t2, 0x0D    # carriage return
    jal uart_putc

    mv ra, s6
    ret
