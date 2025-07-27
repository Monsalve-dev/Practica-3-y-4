########################################################################
#              Simulación de Semáforo con retardo “busy?wait”          #
#  - Pulsar 's' en VERDE para iniciar el ciclo                         #
#  - Pulsar 'q' en VERDE para salir del programa                        #
#  - Tras ‘s’: 20 s ? AMARILLO, 10 s ? ROJO, 30 s ? VERDE                #
#  - Mide y muestra ciclos consumidos en cada fase                     #
#  - Al salir muestra resumen de eficiencia global                     #
########################################################################

        .data
msg_start:        .asciiz "Presione 's' para solicitar cambio de semáforo\n"
msg_verde:        .asciiz "Semáforo en VERDE, esperando pulsador...\n"
msg_btn:          .asciiz "Pulsador OK: en 20 segundos cambia a AMARILLO\n"
msg_amar:         .asciiz "Semáforo en AMARILLO, en 10 segundos cambia a ROJO\n"
msg_rojo:         .asciiz "Semáforo en ROJO, en 30 segundos cambia a VERDE\n"

str_ciclos_v:     .asciiz "Ciclos consumidos en VERDE: "
str_ciclos_a:     .asciiz "Ciclos consumidos en AMARILLO: "
str_ciclos_r:     .asciiz "Ciclos consumidos en ROJO: "
newline:          .asciiz "\n"

# Cadenas para resumen final
str_summary:      .asciiz "=== Resumen de Eficiencia ===\n"
str_tot_ciclos:   .asciiz "Ciclos totales consumidos: "
str_tot_time:     .asciiz "Tiempo total simulado (s): "
str_avg_fps:      .asciiz "Ciclos por segundo promedio: "

        .text
        .globl main

main:
    # Inicializar CP0 Count a 0
    mtc0    $zero, $9

    # Inicializar acumuladores
    move    $s0, $zero      # s0 = suma total de ciclos
    move    $s1, $zero      # s1 = suma total de segundos

    # Mensaje inicial
    la      $a0, msg_start
    li      $v0, 4
    syscall

ciclo:
    # --------- VERDE & espera 's'/'q' -------------
    la      $a0, msg_verde
    li      $v0, 4
    syscall

wait_s:
    li      $v0, 12        # read_char
    syscall                # $v0 <- tecla
    li      $t0, 's'
    beq     $v0, $t0, do_verde
    li      $t1, 'q'
    beq     $v0, $t1, exit_prog
    j       wait_s

do_verde:
    # ---------- Fase VERDE (20 s) ----------
    la      $a0, msg_btn
    li      $v0, 4
    syscall

    # Medir ciclos VERDE
    mfc0    $t3, $9         # t3 = CP0 Count inicio
    li      $a0, 20
    jal     delay_busy
    mfc0    $t4, $9         # t4 = CP0 Count fin
    subu    $t5, $t4, $t3   # t5 = ciclos consumidos

    # Mostrar ciclos VERDE
    li      $v0, 4
    la      $a0, str_ciclos_v
    syscall
    move    $a0, $t5
    li      $v0, 1
    syscall
    li      $v0, 4
    la      $a0, newline
    syscall

    # Acumular totales
    addu    $s0, $s0, $t5   # suma ciclos
    addi    $s1, $s1, 20    # suma segundos

    # ---------- Fase AMARILLO (10 s) ----------
    la      $a0, msg_amar
    li      $v0, 4
    syscall

    mfc0    $t3, $9
    li      $a0, 10
    jal     delay_busy
    mfc0    $t4, $9
    subu    $t5, $t4, $t3

    li      $v0, 4
    la      $a0, str_ciclos_a
    syscall
    move    $a0, $t5
    li      $v0, 1
    syscall
    li      $v0, 4
    la      $a0, newline
    syscall

    addu    $s0, $s0, $t5
    addi    $s1, $s1, 10

    # ---------- Fase ROJO (30 s) ----------
    la      $a0, msg_rojo
    li      $v0, 4
    syscall

    mfc0    $t3, $9
    li      $a0, 30
    jal     delay_busy
    mfc0    $t4, $9
    subu    $t5, $t4, $t3

    li      $v0, 4
    la      $a0, str_ciclos_r
    syscall
    move    $a0, $t5
    li      $v0, 1
    syscall
    li      $v0, 4
    la      $a0, newline
    syscall

    addu    $s0, $s0, $t5
    addi    $s1, $s1, 30

    # Volver a empezar
    j       ciclo

exit_prog:
    # --------- Resumen de eficiencia global ----------
    li      $v0, 4
    la      $a0, str_summary
    syscall

    # Total ciclos
    li      $v0, 4
    la      $a0, str_tot_ciclos
    syscall
    move    $a0, $s0
    li      $v0, 1
    syscall
    li      $v0, 4
    la      $a0, newline
    syscall

    # Total tiempo
    li      $v0, 4
    la      $a0, str_tot_time
    syscall
    move    $a0, $s1
    li      $v0, 1
    syscall
    li      $v0, 4
    la      $a0, newline
    syscall

    # Frecuencia promedio (ciclos/segundo)
    div     $s0, $s1       # LO = s0/s1
    mflo    $t6
    li      $v0, 4
    la      $a0, str_avg_fps
    syscall
    move    $a0, $t6
    li      $v0, 1
    syscall
    li      $v0, 4
    la      $a0, newline
    syscall

    # Salida limpia
    li      $v0, 10
    syscall

#---------------------------------------------------------------------------#
# delay_busy: retardo aproximado de $a0 segundos usando busy?wait            #
#---------------------------------------------------------------------------#
delay_busy:
    li      $t2, 400000      # iteraciones ? 1 s (ajustar según tu simulador)
sec_loop:
    li      $t0, 0
inner_loop:
    addi    $t0, $t0, 1
    blt     $t0, $t2, inner_loop
    subi    $a0, $a0, 1
    bgtz    $a0, sec_loop
    jr      $ra
