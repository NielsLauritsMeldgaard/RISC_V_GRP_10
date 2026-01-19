.text
.globl _start

_start:
    li t0, 0x40000008      # UART register base address

# ---- Set terminal color to GREEN ----
    li t2, 0x1B    # ESC
    jal send_char

    li t2, 0x5B    # [          ] 
    jal send_char

    li t2, 0x33    # '3'
    jal send_char

    li t2, 0x32    # '2'  -> 32 = green
    jal send_char

    li t2, 0x6D    # 'm'
    jal send_char


# ---- Print "Hello World!" ----

    li t2, 0x48 # H
    jal send_char

    li t2, 0x65 # e
    jal send_char

    li t2, 0x6C # l
    jal send_char

    li t2, 0x6C # l
    jal send_char

    li t2, 0x6F # o
    jal send_char

    li t2, 0x20 # space
    jal send_char

    li t2, 0x57 # W
    jal send_char

    li t2, 0x6F # o
    jal send_char

    li t2, 0x72 # r
    jal send_char

    li t2, 0x6C # l
    jal send_char

    li t2, 0x64 # d
    jal send_char

    li t2, 0x21 # !
    jal send_char

    li t2, 0x0A # newline
    jal send_char


# ---- Reset terminal color back to default ----
    li t2, 0x1B
    jal send_char

    li t2, 0x5B
    jal send_char

    li t2, 0x30   # '0'
    jal send_char

    li t2, 0x6D   # 'm'
    jal send_char


done:
    j done


# --------------------------------------------------
send_char:
check_busy:
    lw   t3, 0(t0)
    andi t3, t3, 0x100
    bne  t3, zero, check_busy

    sw   t2, 0(t0)
    ret
