    .data
prompt:       .asciiz "Teclea texto (Enter para terminar): "
msgResult:    .asciiz "\nTexto ingresado: "
msgTime:      .asciiz "\nTiempo en ciclos: "
msgIters:     .asciiz "\nIteraciones de bucle: "
newline:      .asciiz "\n"
buffer:       .space 256        # Buffer circular (256 bytes)

    .text
    .globl main
main:
    # 1) Reiniciar CP0 Count y guardar inicio
    mtc0   $zero, $9            # Count ? 0
    mfc0   $t0, $9              # t0 = Count inicial
    move   $s3, $t0             # s3 = start_count

    # 2) Inicializar contadores y punteros
    li     $s0, 0               # s0 = iteraciones
    li     $s1, 0               # s1 = head (inserción)
    li     $s2, 0               # s2 = tail (lectura)

    # 3) Mostrar prompt
    la     $a0, prompt
    li     $v0, 4
    syscall

input_loop:
    # 4) Leer carácter sin eco automático
    li     $v0, 12              # syscall read_char
    syscall                     # resultado en $v0

    # 5) Almacenar en buffer[head]
    la     $t5, buffer
    addu   $t6, $t5, $s1
    sb     $v0, 0($t6)

    # 6) Avanzar head, módulo 256
    addiu  $s1, $s1, 1
    andi   $s1, $s1, 0xFF

    # 7) Si head alcanzó tail (buffer lleno), mover tail también
    beq    $s1, $s2, bump_tail
    nop
    j      count_it
bump_tail:
    addiu  $s2, $s2, 1
    andi   $s2, $s2, 0xFF

count_it:
    # 8) Contar iteración
    addiu  $s0, $s0, 1

    # 9) Salir si el carácter fue Enter (ASCII 10)
    li     $t7, 10
    beq    $v0, $t7, finish
    nop

    j      input_loop
    nop

finish:
    # 10) Leer CP0 Count final y calcular diferencia
    mfc0   $t8, $9              # t8 = Count final
    subu   $t8, $t8, $s3        # t8 = ciclos usados

    # 11) Salto de línea antes del resultado
    la     $a0, newline
    li     $v0, 4
    syscall

    # 12) Imprimir “Texto ingresado: ”
    la     $a0, msgResult
    li     $v0, 4
    syscall

    # 13) Mostrar buffer de tail hasta head
    move   $t9, $s2             # t9 = índice de lectura
print_loop:
    beq    $t9, $s1, after_print
    la     $t5, buffer
    addu   $t6, $t5, $t9
    lb     $a0, 0($t6)
    li     $v0, 11
    syscall

    addiu  $t9, $t9, 1
    andi   $t9, $t9, 0xFF
    j      print_loop
    nop

after_print:
    # 14) Salto de línea
    la     $a0, newline
    li     $v0, 4
    syscall

    # 15) Imprimir tiempo en ciclos
    la     $a0, msgTime
    li     $v0, 4
    syscall

    move   $a0, $t8
    li     $v0, 1
    syscall

    # 16) Salto de línea
    la     $a0, newline
    li     $v0, 4
    syscall

    # 17) Imprimir iteraciones
    la     $a0, msgIters
    li     $v0, 4
    syscall

    move   $a0, $s0
    li     $v0, 1
    syscall

    # 18) Salto final y salida
    la     $a0, newline
    li     $v0, 4
    syscall

    li     $v0, 10
    syscall
