# Minesweeper
# Author: Roberta Silva Dos Santos
# Description: Simple 5x5 Minesweeper game with a menu, fixed mines,
#              adjacent-mine counting, and victory detection.

.data
menu_prompt:                .asciiz "\n\n--- MINESWEEPER ---\n1. Play\n2. Exit\n3. About\nChoose an option: "
about_text:                 .asciiz "\n--- ABOUT ---\nGame: Minesweeper\nAuthor: Roberta Silva Dos Santos\nCourse: Computer Architecture and Organization I\nTutorial: Choose row and column coordinates to reveal cells.\nAvoid the mines and reveal all safe cells to win.\n\n"
row_prompt:                 .asciiz "Enter the row (0-4): "
column_prompt:              .asciiz "Enter the column (0-4): "
invalid_menu_message:       .asciiz "\nInvalid menu option. Choose 1, 2, or 3.\n"
invalid_coordinate_message: .asciiz "\nInvalid coordinate. Use a value from 0 to 4.\n"
loss_message:               .asciiz "\nYOU LOST! You stepped on a mine!\n"
win_message:                .asciiz "\nCONGRATULATIONS! YOU WON!\n"
repeated_move_message:      .asciiz "\nThat position was already revealed. Choose another one.\n"
board_label:                .asciiz "\nBoard:\n   0 1 2 3 4\n"
adjacent_mines_label:       .asciiz " adjacent mines\n"
space_string:               .asciiz " "
newline_string:             .asciiz "\n"
row_separator:              .asciiz " | "

.align 2
# Real 5x5 board: -1 = mine, 0 = safe cell.
minefield:
    .word -1,  0, 0, 0,  0
    .word  0,  0, 0, 0,  0
    .word  0, -1, 0, 0,  0
    .word  0,  0, 0, 0, -1
    .word  0,  0, 0, 0,  0

# Player visibility: 0 = hidden, 1 = revealed.
visible_cells:
    .word 0, 0, 0, 0, 0
    .word 0, 0, 0, 0, 0
    .word 0, 0, 0, 0, 0
    .word 0, 0, 0, 0, 0
    .word 0, 0, 0, 0, 0

.text
.globl main

main:
menu_loop:
    li $v0, 4
    la $a0, menu_prompt
    syscall

    li $v0, 5
    syscall
    move $t0, $v0

    li $t1, 1
    beq $t0, $t1, play_game
    li $t1, 2
    beq $t0, $t1, exit_program
    li $t1, 3
    beq $t0, $t1, show_about

    li $v0, 4
    la $a0, invalid_menu_message
    syscall
    j menu_loop

show_about:
    li $v0, 4
    la $a0, about_text
    syscall
    j menu_loop

exit_program:
    li $v0, 10
    syscall

play_game:
    # Reset visibility before starting a new game.
    la $t0, visible_cells
    li $t1, 0
    li $t2, 25

reset_visibility_loop:
    sw $t1, 0($t0)
    addiu $t0, $t0, 4
    addiu $t2, $t2, -1
    bgtz $t2, reset_visibility_loop

game_loop:
    jal print_board

    # Read and validate the row.
    li $v0, 4
    la $a0, row_prompt
    syscall

    li $v0, 5
    syscall
    move $t1, $v0

    blt $t1, 0, invalid_row
    bgt $t1, 4, invalid_row

    # Read and validate the column.
    li $v0, 4
    la $a0, column_prompt
    syscall

    li $v0, 5
    syscall
    move $t2, $v0

    blt $t2, 0, invalid_column
    bgt $t2, 4, invalid_column

    # Compute cell index: row * 5 + column.
    li $t3, 5
    mult $t1, $t3
    mflo $t4
    addu $t4, $t4, $t2

    # Reject a cell that was already revealed.
    la $t5, visible_cells
    sll $t6, $t4, 2
    addu $t5, $t5, $t6
    lw $t7, 0($t5)
    bnez $t7, repeated_move

    # Mark the selected cell as revealed.
    li $t8, 1
    sw $t8, 0($t5)

    # Check whether the selected cell contains a mine.
    la $t9, minefield
    addu $t9, $t9, $t6
    lw $s0, 0($t9)
    li $s1, -1
    beq $s0, $s1, lost_game

    # Print the number of adjacent mines for the selected safe cell.
    move $a0, $t1
    move $a1, $t2
    jal print_adjacent_mine_count

    # Check whether every safe cell has been revealed.
    jal check_victory
    j game_loop

invalid_row:
    li $v0, 4
    la $a0, invalid_coordinate_message
    syscall
    j game_loop

invalid_column:
    li $v0, 4
    la $a0, invalid_coordinate_message
    syscall
    j game_loop

repeated_move:
    li $v0, 4
    la $a0, repeated_move_message
    syscall
    j game_loop

lost_game:
    jal print_full_board

    li $v0, 4
    la $a0, loss_message
    syscall
    j menu_loop

won_game:
    jal print_board

    li $v0, 4
    la $a0, win_message
    syscall
    j menu_loop

print_board:
    # Preserve saved registers and return address.
    addiu $sp, $sp, -24
    sw $ra, 20($sp)
    sw $s0, 16($sp)
    sw $s1, 12($sp)
    sw $s2, 8($sp)
    sw $s3, 4($sp)

    li $v0, 4
    la $a0, board_label
    syscall

    li $s1, 0

print_board_row:
    li $v0, 1
    move $a0, $s1
    syscall

    li $v0, 4
    la $a0, row_separator
    syscall

    li $s2, 0

print_board_column:
    # Compute the current cell index.
    li $t0, 5
    mult $s1, $t0
    mflo $t1
    addu $t1, $t1, $s2

    # Check whether the current cell is visible.
    la $t2, visible_cells
    sll $t3, $t1, 2
    addu $t2, $t2, $t3
    lw $t4, 0($t2)

    beqz $t4, print_hidden_cell

    # The cell is visible. Print a mine or its adjacent-mine count.
    la $t2, minefield
    addu $t2, $t2, $t3
    lw $t5, 0($t2)

    li $t6, -1
    beq $t5, $t6, print_visible_mine

    move $a0, $s1
    move $a1, $s2
    jal count_adjacent_mines

    li $v0, 1
    move $a0, $v1
    syscall
    j print_next_cell

print_hidden_cell:
    li $v0, 11
    li $a0, '.'
    syscall
    j print_next_cell

print_visible_mine:
    li $v0, 11
    li $a0, '*'
    syscall

print_next_cell:
    li $v0, 4
    la $a0, space_string
    syscall

    addiu $s2, $s2, 1
    blt $s2, 5, print_board_column

    li $v0, 4
    la $a0, newline_string
    syscall

    addiu $s1, $s1, 1
    blt $s1, 5, print_board_row

    lw $ra, 20($sp)
    lw $s0, 16($sp)
    lw $s1, 12($sp)
    lw $s2, 8($sp)
    lw $s3, 4($sp)
    addiu $sp, $sp, 24
    jr $ra

print_full_board:
    # Preserve saved registers and return address.
    addiu $sp, $sp, -24
    sw $ra, 20($sp)
    sw $s0, 16($sp)
    sw $s1, 12($sp)
    sw $s2, 8($sp)
    sw $s3, 4($sp)

    li $v0, 4
    la $a0, board_label
    syscall

    li $s1, 0

print_full_board_row:
    li $v0, 1
    move $a0, $s1
    syscall

    li $v0, 4
    la $a0, row_separator
    syscall

    li $s2, 0

print_full_board_column:
    # Compute the current cell index.
    li $t0, 5
    mult $s1, $t0
    mflo $t1
    addu $t1, $t1, $s2

    la $t2, minefield
    sll $t3, $t1, 2
    addu $t2, $t2, $t3
    lw $t5, 0($t2)

    li $t6, -1
    beq $t5, $t6, print_full_board_mine

    move $a0, $s1
    move $a1, $s2
    jal count_adjacent_mines

    li $v0, 1
    move $a0, $v1
    syscall
    j print_next_full_cell

print_full_board_mine:
    li $v0, 11
    li $a0, '*'
    syscall

print_next_full_cell:
    li $v0, 4
    la $a0, space_string
    syscall

    addiu $s2, $s2, 1
    blt $s2, 5, print_full_board_column

    li $v0, 4
    la $a0, newline_string
    syscall

    addiu $s1, $s1, 1
    blt $s1, 5, print_full_board_row

    lw $ra, 20($sp)
    lw $s0, 16($sp)
    lw $s1, 12($sp)
    lw $s2, 8($sp)
    lw $s3, 4($sp)
    addiu $sp, $sp, 24
    jr $ra

# Input: $a0 = row, $a1 = column.
# Prints the number of adjacent mines for one safe cell.
print_adjacent_mine_count:
    addiu $sp, $sp, -16
    sw $ra, 12($sp)
    sw $s0, 8($sp)
    sw $s1, 4($sp)

    move $s0, $a0
    move $s1, $a1

    jal count_adjacent_mines

    li $v0, 1
    move $a0, $v1
    syscall

    li $v0, 4
    la $a0, adjacent_mines_label
    syscall

    lw $ra, 12($sp)
    lw $s0, 8($sp)
    lw $s1, 4($sp)
    addiu $sp, $sp, 16
    jr $ra

# Input:  $a0 = row, $a1 = column.
# Output: $v1 = number of adjacent mines.
count_adjacent_mines:
    addiu $sp, $sp, -24
    sw $ra, 20($sp)
    sw $s0, 16($sp)
    sw $s1, 12($sp)
    sw $s2, 8($sp)
    sw $s3, 4($sp)
    sw $s4, 0($sp)

    move $s0, $a0
    move $s1, $a1
    li $s2, 0
    li $s3, -1

adjacent_row_loop:
    li $s4, -1

adjacent_column_loop:
    addu $t0, $s0, $s3
    addu $t1, $s1, $s4

    # Ignore neighbors outside the 5x5 board.
    bltz $t0, next_adjacent_column
    bltz $t1, next_adjacent_column
    bge $t0, 5, next_adjacent_column
    bge $t1, 5, next_adjacent_column

    # Compute neighbor index and check for a mine.
    li $t2, 5
    mult $t0, $t2
    mflo $t3
    addu $t3, $t3, $t1

    la $t4, minefield
    sll $t5, $t3, 2
    addu $t4, $t4, $t5
    lw $t6, 0($t4)

    li $t7, -1
    bne $t6, $t7, next_adjacent_column

    addiu $s2, $s2, 1

next_adjacent_column:
    addiu $s4, $s4, 1
    ble $s4, 1, adjacent_column_loop

    addiu $s3, $s3, 1
    ble $s3, 1, adjacent_row_loop

    move $v1, $s2

    lw $ra, 20($sp)
    lw $s0, 16($sp)
    lw $s1, 12($sp)
    lw $s2, 8($sp)
    lw $s3, 4($sp)
    lw $s4, 0($sp)
    addiu $sp, $sp, 24
    jr $ra

check_victory:
    addiu $sp, $sp, -16
    sw $ra, 12($sp)
    sw $s0, 8($sp)
    sw $s1, 4($sp)

    li $s0, 0
    li $s1, 0

victory_check_loop:
    # Mines do not count toward the number of safe cells that must be revealed.
    la $t0, minefield
    sll $t1, $s1, 2
    addu $t0, $t0, $t1
    lw $t2, 0($t0)

    li $t3, -1
    beq $t2, $t3, next_victory_cell

    la $t0, visible_cells
    addu $t0, $t0, $t1
    lw $t4, 0($t0)
    addu $s0, $s0, $t4

next_victory_cell:
    addiu $s1, $s1, 1
    blt $s1, 25, victory_check_loop

    # There are 25 cells and 3 mines, so 22 safe cells must be revealed.
    li $t5, 22
    beq $s0, $t5, victory_found

    lw $ra, 12($sp)
    lw $s0, 8($sp)
    lw $s1, 4($sp)
    addiu $sp, $sp, 16
    jr $ra

victory_found:
    lw $ra, 12($sp)
    lw $s0, 8($sp)
    lw $s1, 4($sp)
    addiu $sp, $sp, 16
    j won_game
