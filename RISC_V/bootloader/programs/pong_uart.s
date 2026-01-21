# UART-based Pong Game for RISC-V
# Play via Putty: Use W/S for left pad, UP/DOWN for right pad
# Ball bounces off walls and pads; scores on miss


# Memory map
# 0x4000_0008 = UART TX/RX (bit 9 = rx_valid)
# 0x4000_0004 = 7-segment display (lower 3 digits = score)

_start:
    li sp, 0x20010000       # Stack at end of data RAM
    
    # Wait for button/switch press to start
    jal ra, wait_for_start
    
    jal ra, init_game
    j main_loop

# ============================================================================
# Wait for button/switch press
# ============================================================================
wait_for_start:
    li t0, 0x40000000      # GPIO address
    
wait_loop:
    lw t1, 0(t0)            # Read GPIO/switches
    beqz t1, wait_loop      # If zero (no button), keep waiting
    
    # Button pressed! Debounce with a small delay
    li t1, 10000
debounce:
    addi t1, t1, -1
    bnez t1, debounce
    
    ret

# ============================================================================
# Game State (stored in data memory, BASE = 0x2000_0000)
# ============================================================================
#
# Game field: 60 columns x 20 rows
#   Pads: left at x=1, right at x=58
#   Ball: starts at x=30, y=10
#
# Data offsets (all relative to BASE = 0x2000_0000):
#   +0:   ball_x (4 bytes)
#   +4:   ball_y (4 bytes)
#   +8:   ball_dx (4 bytes, -1 or +1)
#   +12:  ball_dy (4 bytes, -1 or +1)
#   +16:  left_pad_y (4 bytes, center row 0..19)
#   +20:  right_pad_y (4 bytes)
#   +24:  left_score (4 bytes)
#   +28:  right_score (4 bytes)
#   +32:  game_tick (4 bytes, frame counter)
#   +36:  render_flag (1 = needs redraw)
# ============================================================================

init_game:
    li t0, 0x20000000       # data BASE
    
    # ball_x = 30
    li t1, 30
    sw t1, 0(t0)
    
    # ball_y = 10
    li t1, 10
    sw t1, 4(t0)
    
    # ball_dx = 1
    li t1, 1
    sw t1, 8(t0)
    
    # ball_dy = 1
    li t1, 1
    sw t1, 12(t0)
    
    # left_pad_y = 9 (center)
    li t1, 9
    sw t1, 16(t0)
    
    # right_pad_y = 9
    li t1, 9
    sw t1, 20(t0)
    
    # left_score = 0
    sw x0, 24(t0)
    
    # right_score = 0
    sw x0, 28(t0)
    
    # game_tick = 0
    sw x0, 32(t0)
    
    # render_flag = 1 (force first redraw)
    li t1, 1
    sw t1, 36(t0)
    
    # Print welcome banner
    jal ra, print_welcome
    
    ret

# ============================================================================
# Main game loop
# ============================================================================
main_loop:
    li t0, 0x20000000
    
    # Increment tick counter
    lw t1, 32(t0)
    addi t1, t1, 1
    sw t1, 32(t0)
    
    # Every 20 ticks, update ball and render
    li t2, 20
    rem t3, t1, t2
    bnez t3, skip_update
    
    # Update ball position
    jal ra, update_ball
    
    # Check collisions with pads
    jal ra, check_collisions
    
    # Mark for redraw
    li t1, 1
    sw t1, 36(t0)
    
skip_update:
    # Check for input
    jal ra, read_input
    
    # If render_flag set, redraw screen
    lw t1, 36(t0)
    beqz t1, skip_render
    
    jal ra, render_screen
    
    li t1, 0
    sw t1, 36(t0)
    
skip_render:
    # Small delay (loop iterations)
    li t1, 1000
delay_loop:
    addi t1, t1, -1
    bnez t1, delay_loop
    
    j main_loop

# ============================================================================
# Update ball position
# ============================================================================
update_ball:
    li t0, 0x20000000
    
    lw t1, 0(t0)            # ball_x
    lw t2, 4(t0)            # ball_y
    lw t3, 8(t0)            # ball_dx
    lw t4, 12(t0)           # ball_dy
    
    # ball_x += ball_dx
    add t1, t1, t3
    
    # ball_y += ball_dy
    add t2, t2, t4
    
    # Bounce off top/bottom walls (y bounds: 1 to 18)
    li t5, 1
    li t6, 18
    
    blt t2, t5, bounce_top
    bgt t2, t6, bounce_bottom
    j skip_y_bounce
    
bounce_top:
    li t2, 1
    li t4, 1                # ball_dy = 1
    sw t4, 12(t0)
    j skip_y_bounce
    
bounce_bottom:
    li t2, 18
    li t4, -1               # ball_dy = -1
    sw t4, 12(t0)
    
skip_y_bounce:
    # Check left/right boundaries for scoring
    # Left pad at x=1, right pad at x=58
    # Ball goes off left (x < 1) -> right player scores
    # Ball goes off right (x > 58) -> left player scores
    
    li t5, 1
    li t6, 58
    
    bge t1, t5, skip_left_score
    # Left miss -> right scores
    lw t5, 28(t0)
    addi t5, t5, 1
    sw t5, 28(t0)
    li t1, 30                # reset ball to center
    li t2, 10
    li t3, 1
    li t4, 1
    li t5, 1                 # trigger render
    sw t5, 36(t0)
    j score_done
    
skip_left_score:
    ble t1, t6, score_done
    # Right miss -> left scores
    lw t5, 24(t0)
    addi t5, t5, 1
    sw t5, 24(t0)
    li t1, 30                # reset ball to center
    li t2, 10
    li t3, -1
    li t4, 1
    li t5, 1                 # trigger render
    sw t5, 36(t0)
    
score_done:
    sw t1, 0(t0)            # ball_x
    sw t2, 4(t0)            # ball_y
    sw t3, 8(t0)            # ball_dx
    sw t4, 12(t0)           # ball_dy
    
    ret

# ============================================================================
# Check collisions with pads
# ============================================================================
check_collisions:
    li t0, 0x20000000
    
    lw t1, 0(t0)            # ball_x
    lw t2, 4(t0)            # ball_y
    lw t3, 16(t0)           # left_pad_y
    lw t4, 20(t0)           # right_pad_y
    
    # Left pad: x=1, y = left_pad_y-1 to left_pad_y+1 (3 rows)
    li t5, 1
    bne t1, t5, skip_left_pad
    
    addi t5, t3, -1         # top of pad
    addi t6, t3, 1          # bottom of pad
    
    blt t2, t5, skip_left_pad
    bgt t2, t6, skip_left_pad
    
    # Collision! Bounce right
    li t5, 1
    sw t5, 8(t0)            # ball_dx = 1
    li t1, 2                # push ball right
    sw t1, 0(t0)
    j check_done
    
skip_left_pad:
    # Right pad: x=58, y = right_pad_y-1 to right_pad_y+1
    li t5, 58
    bne t1, t5, check_done
    
    addi t5, t4, -1
    addi t6, t4, 1
    
    blt t2, t5, check_done
    bgt t2, t6, check_done
    
    # Collision! Bounce left
    li t5, -1
    sw t5, 8(t0)            # ball_dx = -1
    li t1, 57               # push ball left
    sw t1, 0(t0)
    
check_done:
    ret

# ============================================================================
# Read input from UART
# ============================================================================
read_input:
    # Poll UART status register (0x4000_0008)
    # Bit 9 = rx_valid (character received)
    
    li t0, 0x40000008
    lw t1, 0(t0)            # Read status + data
    
    # Check rx_valid (bit 9)
    li t2, 512              # 2^9
    and t3, t1, t2
    beqz t3, no_input
    
    # Character in lower 8 bits
    li t2 0xFF
    and t4, t1, t2
    
    li t0, 0x20000000
    
    # Check for 'w' or 'W' (move left pad up)
    li t2, 0x77             # w
    beq t4, t2, move_left_up
    li t2, 0x57             # W
    beq t4, t2, move_left_up
    
    # Check for 's' or 'S' (move left pad down)
    li t2, 0x73             # s
    beq t4, t2, move_left_down
    li t2, 0x53             # S
    beq t4, t2, move_left_down
    
    # Check for up arrow (special code: call separate handler)
    # For simplicity, use arrow key ASCII approximations
    # Or check ESC sequence... for now just use different chars
    
    # For terminal, up arrow in escape sequence is complex
    # Workaround: use 'i'/'k' for right pad up/down
    
    li t2, 0x69             # i
    beq t4, t2, move_right_up
    li t2, 0x49             # I
    beq t4, t2, move_right_up
    
    li t2, 0x6B             # k
    beq t4, t2, move_right_down
    li t2, 0x4B             # K
    beq t4, t2, move_right_down
    
    # Mark for redraw on any input
    li t2, 1
    sw t2, 36(t0)
    
    j no_input
    
move_left_up:
    lw t1, 16(t0)
    addi t1, t1, -1
    li t2, 0
    blt t1, t2, move_left_up_clamp
    li t2, 17
    ble t1, t2, move_left_up_done
move_left_up_clamp:
    li t1, 0
move_left_up_done:
    sw t1, 16(t0)
    li t1, 1
    sw t1, 36(t0)
    j no_input
    
move_left_down:
    lw t1, 16(t0)
    addi t1, t1, 1
    li t2, 19
    ble t1, t2, move_left_down_done
    li t1, 19
move_left_down_done:
    sw t1, 16(t0)
    li t1, 1
    sw t1, 36(t0)
    j no_input
    
move_right_up:
    lw t1, 20(t0)
    addi t1, t1, -1
    li t2, 0
    blt t1, t2, move_right_up_clamp
    li t2, 17
    ble t1, t2, move_right_up_done
move_right_up_clamp:
    li t1, 0
move_right_up_done:
    sw t1, 20(t0)
    li t1, 1
    sw t1, 36(t0)
    j no_input
    
move_right_down:
    lw t1, 20(t0)
    addi t1, t1, 1
    li t2, 19
    ble t1, t2, move_right_down_done
    li t1, 19
move_right_down_done:
    sw t1, 20(t0)
    li t1, 1
    sw t1, 36(t0)
    
no_input:
    ret

# ============================================================================
# Render game screen to UART
# ============================================================================
render_screen:
    # Print clear screen 
    li t0, 0x40000008
    
    li t1, 0x1B             # ESC
    sw t1, 0(t0)
    li t1, 0x5B             # leftbracket
    sw t1, 0(t0)
    li t1, 0x32             # 2
    sw t1, 0(t0)
    li t1, 0x4A             # J
    sw t1, 0(t0)
    
    # Render 20 rows of game field
    li s0, 0                # row counter
    li s1, 0x20000000       # data base
    
render_row_loop:
    li t1, 20
    bge s0, t1, render_done
    
    # Render one row
    jal ra, render_one_row
    
    # Newline
    li t1, 0x0A             # newline
    sw t1, 0(t0)
    
    addi s0, s0, 1
    j render_row_loop
    
render_done:
    # Print score line
    jal ra, print_score_line
    
    # Print instructions
    jal ra, print_instructions
    
    ret

# ============================================================================
# Render one row of the game field
# ============================================================================
render_one_row:
    li t0, 0x40000008       # UART address
    li s2, 0                # col counter
    
row_loop:
    li t1, 60
    bge s2, t1, row_done
    
    # Determine what to draw at (s2, s0)
    # Walls at x=0 and x=59
    # Pads at x=1 and x=58
    # Ball at ball_x, ball_y
    
    beqz s2, draw_wall
    li t1, 59
    beq s2, t1, draw_wall
    
    # Check for ball
    lw t1, 0(s1)            # ball_x
    lw t2, 4(s1)            # ball_y
    
    beq s2, t1, check_ball_y
    j check_left_pad
    
check_ball_y:
    beq s0, t2, draw_ball
    j check_left_pad
    
    # Check for left pad (x=1, y = left_pad_y-1 to left_pad_y+1)
check_left_pad:
    li t1, 1
    bne s2, t1, check_right_pad
    
    lw t2, 16(s1)           # left_pad_y
    addi t3, t2, -1
    addi t4, t2, 1
    
    blt s0, t3, draw_space
    bgt s0, t4, draw_space
    j draw_pad
    
    # Check for right pad (x=58, y = right_pad_y-1 to right_pad_y+1)
check_right_pad:
    li t1, 58
    bne s2, t1, draw_space
    
    lw t2, 20(s1)           # right_pad_y
    addi t3, t2, -1
    addi t4, t2, 1
    
    blt s0, t3, draw_space
    bgt s0, t4, draw_space
    j draw_pad
    
draw_wall:
    li t1, 0x7C             # pipe
    sw t1, 0(t0)
    j next_col
    
draw_ball:
    li t1, 0x6F             # o
    sw t1, 0(t0)
    j next_col
    
draw_pad:
    li t1, 0x5B             # leftbracket
    sw t1, 0(t0)
    j next_col
    
draw_space:
    li t1, 0x20             # space
    sw t1, 0(t0)
    
next_col:
    addi s2, s2, 1
    j row_loop
    
row_done:
    ret

# ============================================================================
# Print score line
# ============================================================================
print_score_line:
    li t0, 0x40000008
    
    # Print blank line
    li t1, 0x0A             # newline
    sw t1, 0(t0)
    
    # Print left score
    li t1, 0x4C             # L
    sw t1, 0(t0)
    li t1, 0x3A             # colon
    sw t1, 0(t0)
    li t1, 0x20             # space
    sw t1, 0(t0)
    
    lw t2, 24(s1)           # left_score
    jal ra, print_number
    
    # Spacer
    li t1, 0x20             # space
    sw t1, 0(t0)
    li t1, 0x20             # space
    sw t1, 0(t0)
    li t1, 0x20             # space
    sw t1, 0(t0)
    
    # Print right score
    li t1, 0x52             # R
    sw t1, 0(t0)
    li t1, 0x3A             # colon
    sw t1, 0(t0)
    li t1, 0x20             # space
    sw t1, 0(t0)
    
    lw t2, 28(s1)           # right_score
    jal ra, print_number
    
    li t1, 0x0A             # newline
    sw t1, 0(t0)
    
    ret

# ============================================================================
# Print a number (0-99) to UART
# Input: t2 = number
# ============================================================================
print_number:
    # Divide by 10 to get tens digit
    li t3, 10
    div t4, t2, t3          # t4 = tens digit
    rem t5, t2, t3          # t5 = ones digit
    
    # Print tens digit
    li t1, 0x30             # 0
    add t1, t1, t4
    sw t1, 0(t0)
    
    # Print ones digit
    li t1, 0x30             # 0
    add t1, t1, t5
    sw t1, 0(t0)
    
    ret

# ============================================================================
# Print instructions
# ============================================================================
print_instructions:
    li t0, 0x40000008
    
    # Print instruction text
    li t1, 0x0A             # newline
    sw t1, 0(t0)
    
    # "W/S=Left, I/K=Right"
    li t1, 0x57             # W
    sw t1, 0(t0)
    li t1, 0x2F             # slash
    sw t1, 0(t0)
    li t1, 0x53             # S
    sw t1, 0(t0)
    li t1, 0x3D             # equals
    sw t1, 0(t0)
    li t1, 0x4C             # L
    sw t1, 0(t0)
    li t1, 0x65             # e
    sw t1, 0(t0)
    li t1, 0x66             # f
    sw t1, 0(t0)
    li t1, 0x74             # t
    sw t1, 0(t0)
    li t1, 0x2C             # comma
    sw t1, 0(t0)
    li t1, 0x20             # space
    sw t1, 0(t0)
    li t1, 0x49             # I
    sw t1, 0(t0)
    li t1, 0x2F             # slash
    sw t1, 0(t0)
    li t1, 0x4B             # K
    sw t1, 0(t0)
    li t1, 0x3D             # equals
    sw t1, 0(t0)
    li t1, 0x52             # R
    sw t1, 0(t0)
    li t1, 0x69             # i
    sw t1, 0(t0)
    li t1, 0x67             # g
    sw t1, 0(t0)
    li t1, 0x68             # h
    sw t1, 0(t0)
    li t1, 0x74             # t
    sw t1, 0(t0)
    li t1, 0x0A             # newline
    sw t1, 0(t0)
    
    ret

# ============================================================================
# Print welcome banner
# ============================================================================
print_welcome:
    li t0, 0x40000008
    
    li t1, 0x0A             # newline
    sw t1, 0(t0)
    li t1, 0x3D             # equals
    sw t1, 0(t0)
    li t1, 0x3D             # equals
    sw t1, 0(t0)
    li t1, 0x3D             # equals
    sw t1, 0(t0)
    li t1, 0x20             # space
    sw t1, 0(t0)
    li t1, 0x50             # P
    sw t1, 0(t0)
    li t1, 0x4F             # O
    sw t1, 0(t0)
    li t1, 0x4E             # N
    sw t1, 0(t0)
    li t1, 0x47             # G
    sw t1, 0(t0)
    li t1, 0x20             # space
    sw t1, 0(t0)
    li t1, 0x3D             # equals
    sw t1, 0(t0)
    li t1, 0x3D             # equals
    sw t1, 0(t0)
    li t1, 0x3D             # equals
    sw t1, 0(t0)
    li t1, 0x0A             # newline
    sw t1, 0(t0)
    li t1, 0x0A             # newline
    sw t1, 0(t0)
    
    ret
