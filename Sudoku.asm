.data

# --- TABULEIROS (DIFICULDADES) ---
# Facil
board_easy:
.byte 5,3,4,6,7,8,9,1,2
.byte 6,7,2,1,9,5,3,4,8
.byte 1,9,8,3,4,2,5,6,7
.byte 8,5,9,7,6,1,4,2,3
.byte 4,2,6,8,5,3,7,9,1
.byte 7,1,3,9,2,4,8,5,6
.byte 9,6,1,5,3,7,2,8,4
.byte 2,8,7,4,1,9,6,3,5
.byte 3,4,5,2,8,6,1,7,0 # Falta apenas o numero 9

# Medio
board_med:
.byte 5,3,0,0,7,0,0,0,0
.byte 6,0,0,1,9,5,0,0,0
.byte 0,9,8,0,0,0,0,6,0
.byte 8,0,0,0,6,0,0,0,3
.byte 4,0,0,8,0,3,0,0,1
.byte 7,0,0,0,2,0,0,0,6
.byte 0,6,0,0,0,0,2,8,0
.byte 0,0,0,4,1,9,0,0,5
.byte 0,0,0,0,8,0,0,7,9

# Dificil
board_hard:
.byte 0,0,0,0,0,0,0,1,2
.byte 0,0,0,0,3,5,0,0,0
.byte 0,0,0,6,0,0,0,7,0
.byte 7,0,0,0,0,0,3,0,0
.byte 0,0,0,4,0,0,8,0,0
.byte 1,0,0,0,0,0,0,0,0
.byte 0,0,0,1,2,0,0,0,0
.byte 0,8,0,0,0,0,0,4,0
.byte 0,5,0,0,0,0,6,0,0

# Espacos de memoria na RAM para o jogo atual
board: .space 81
initial_board: .space 81

# --- STRINGS DE INTERFACE ---
msg_menu: .asciiz "\n=== SUDOKU MIPS ===\nEscolha a dificuldade:\n1. Facil (Teste de Vitoria)\n2. Medio\n3. Dificil\nOpcao: "
msg_win:  .asciiz "\n\n*** PARABENS! VOCE COMPLETOU O SUDOKU! ***\n"
prompt_row:  .asciiz "\nLinha (0-8) [-1 para sair]: "
prompt_col:  .asciiz "Coluna (0-8): "
prompt_val:  .asciiz "Valor (1-9) [0 para APAGAR]: "
msg_invalid_input: .asciiz "Entrada invalida!\n"
msg_immutable: .asciiz "Nao pode alterar numero inicial!\n"
msg_invalid_move: .asciiz "Jogada invalida (regras do Sudoku)!\n"

# --- STRINGS VISUAIS DO TABULEIRO ---
newline:   .asciiz "\n"
dot:       .asciiz " . "   
spc_num:   .asciiz " "     
v_bar:     .asciiz "|"     
h_line:    .asciiz " ---------+---------+---------\n"

.text
.globl main

main:

menu_loop:
    # Mostra Menu
    li $v0, 4
    la $a0, msg_menu
    syscall

    # Le opcao
    li $v0, 5
    syscall
    move $t0, $v0

    # Seleciona tabuleiro
    li $t1, 1
    beq $t0, $t1, load_easy
    li $t1, 2
    beq $t0, $t1, load_med
    li $t1, 3
    beq $t0, $t1, load_hard
    j menu_loop # Se digitar errado, volta pro menu

load_easy:
    la $s3, board_easy
    j copy_boards
load_med:
    la $s3, board_med
    j copy_boards
load_hard:
    la $s3, board_hard
    j copy_boards

copy_boards:
    # Copia o tabuleiro escolhido para 'board' e 'initial_board'
    la $t1, board
    la $t2, initial_board
    li $t3, 0

copy_loop:
    beq $t3, 81, start_game
    lb $t4, 0($s3)
    sb $t4, 0($t1)     # Salva no board jogavel
    sb $t4, 0($t2)     # Salva no board de referencia (imutavel)
    addi $s3, $s3, 1
    addi $t1, $t1, 1
    addi $t2, $t2, 1
    addi $t3, $t3, 1
    j copy_loop

start_game:
    li $v0, 4
    la $a0, newline
    syscall

game_loop:
    jal print_board

check_win:
    # Verifica se ainda existe algum '0' no board
    la $t0, board
    li $t1, 0
win_loop:
    beq $t1, 81, player_won  # Se olhou os 81 e nao achou '0', ganhou!
    lb $t2, 0($t0)
    beqz $t2, ask_input      # Achou um '0', o jogo continua (vai pedir input)
    addi $t0, $t0, 1
    addi $t1, $t1, 1
    j win_loop

ask_input:
    # ---- INPUT ROW ----
    li $v0, 4
    la $a0, prompt_row
    syscall

    li $v0, 5
    syscall
    move $s0, $v0   # $s0 = Linha

    li $t0, -1
    beq $s0, $t0, exit

    blt $s0, 0, invalid_input
    bgt $s0, 8, invalid_input

    # ---- INPUT COL ----
    li $v0, 4
    la $a0, prompt_col
    syscall

    li $v0, 5
    syscall
    move $s1, $v0   # $s1 = Coluna

    blt $s1, 0, invalid_input
    bgt $s1, 8, invalid_input

    # ---- INPUT VAL ----
    li $v0, 4
    la $a0, prompt_val
    syscall

    li $v0, 5
    syscall
    move $s2, $v0   # $s2 = Valor

    blt $s2, 0, invalid_input  # Aceita 0 (Para apagar)
    bgt $s2, 9, invalid_input

    # --- VERIFICA SE E FIXO ---
    li $t0, 9
    mul $t1, $s0, $t0
    add $t1, $t1, $s1

    la $t2, initial_board
    add $t2, $t2, $t1
    lb $t3, 0($t2)
    bnez $t3, immutable_error

    # --- VALIDAR JOGADA (PULA SE FOR 0/APAGAR) ---
    beqz $s2, save_to_board  # Se for 0, nao precisa validar regras
    jal validate_move
    beqz $v0, invalid_move_error

save_to_board:
    # --- SALVAR NO BOARD ---
    li $t0, 9
    mul $t1, $s0, $t0
    add $t1, $t1, $s1

    la $t4, board
    add $t4, $t4, $t1
    sb $s2, 0($t4)

    j game_loop

# --- MENSAGENS E ESTADOS ---
player_won:
    li $v0, 4
    la $a0, msg_win
    syscall
    j exit

invalid_input:
    li $v0, 4
    la $a0, msg_invalid_input
    syscall
    j ask_input 

immutable_error:
    li $v0, 4
    la $a0, msg_immutable
    syscall
    j ask_input

invalid_move_error:
    li $v0, 4
    la $a0, msg_invalid_move
    syscall
    j ask_input

exit:
    li $v0, 10
    syscall

# IMPRESSAO DO TABULEIRO 
print_board:
    li $t0, 0  # LINHA

print_row_loop:
    beq $t0, 9, end_print_board
    li $t1, 0  # COLUNA
    
    li $v0, 4
    la $a0, spc_num
    syscall

print_col_loop:
    beq $t1, 9, end_col_loop
    
    li $t2, 9
    mul $t3, $t0, $t2
    add $t3, $t3, $t1
    
    # Valor do board atual
    la $t4, board
    add $t4, $t4, $t3
    lb $t5, 0($t4)
    
    beqz $t5, print_dot_cell
    
print_num_cell:
    li $v0, 4
    la $a0, spc_num
    syscall
    
    li $v0, 1
    move $a0, $t5
    syscall
    
    li $v0, 4
    la $a0, spc_num
    syscall
    
    j after_print_cell

print_dot_cell:
    li $v0, 4
    la $a0, dot
    syscall

after_print_cell:
    li $t6, 2
    beq $t1, $t6, print_v_bar
    li $t6, 5
    beq $t1, $t6, print_v_bar
    j next_col

print_v_bar:
    li $v0, 4
    la $a0, v_bar
    syscall

next_col:
    addi $t1, $t1, 1
    j print_col_loop

end_col_loop:
    li $v0, 4
    la $a0, newline
    syscall
    
    li $t6, 2
    beq $t0, $t6, print_h_line
    li $t6, 5
    beq $t0, $t6, print_h_line
    j next_row

print_h_line:
    li $v0, 4
    la $a0, h_line
    syscall

next_row:
    addi $t0, $t0, 1
    j print_row_loop

end_print_board:
    jr $ra

# VALIDACAO (Linha, Coluna e Bloco 3x3)
validate_move:
    li $t0, 0
row_loop_val:
    beq $t0, 9, row_ok
    li $t1, 9
    mul $t2, $s0, $t1
    add $t2, $t2, $t0
    la $t3, board
    add $t3, $t3, $t2
    lb $t4, 0($t3)
    beq $t4, $s2, invalid
    addi $t0, $t0, 1
    j row_loop_val
row_ok:

    li $t0, 0
col_loop_val:
    beq $t0, 9, col_ok
    li $t1, 9
    mul $t2, $t0, $t1
    add $t2, $t2, $s1
    la $t3, board
    add $t3, $t3, $t2
    lb $t4, 0($t3)
    beq $t4, $s2, invalid
    addi $t0, $t0, 1
    j col_loop_val
col_ok:

    li $t9, 3
    div $s0, $t9
    mflo $t5
    mul $t5, $t5, 3

    div $s1, $t9
    mflo $t6
    mul $t6, $t6, 3

    li $t0, 0
box_outer:
    beq $t0, 3, valid
    li $t1, 0

box_inner:
    beq $t1, 3, next_row_box
    add $t7, $t5, $t0
    add $t8, $t6, $t1
    li $t9, 9
    mul $t2, $t7, $t9
    add $t2, $t2, $t8
    la $t3, board
    add $t3, $t3, $t2
    lb $t4, 0($t3)
    beq $t4, $s2, invalid
    addi $t1, $t1, 1
    j box_inner

next_row_box:
    addi $t0, $t0, 1
    j box_outer

valid:
    li $v0, 1
    jr $ra

invalid:
    li $v0, 0
    jr $ra