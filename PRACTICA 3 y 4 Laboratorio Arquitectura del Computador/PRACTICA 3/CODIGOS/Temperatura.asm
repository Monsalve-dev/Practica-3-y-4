.data
# Registros del módulo de Tensión (aunque no se usan en este main, los mantengo por contexto)
TensionControl:  .word 0x0
TensionEstado:   .word 0x0
TensionSistol:   .word 0x0
TensionDiastol:  .word 0x0

# Registros del Sensor de Temperatura
SensorControl:  .word 0x0
SensorEstado:   .word 0x0
SensorDatos:    .word 0x0

# Mensajes para la salida (opcional, para depuración visual)
msg_temp_val:   .asciiz "Temperatura leida: "
msg_status_ok:  .asciiz " (Estado: OK)\n"
msg_status_err: .asciiz " (Estado: ERROR)\n"
msg_init_ok:    .asciiz "Sensor inicializado correctamente.\n"
msg_init_err:   .asciiz "Error al inicializar el sensor.\n"
msg_temp_err:   .asciiz "Error al leer la temperatura.\n"
msg_newline:    .asciiz "\n"


.text
.globl main               # ¡Declarar 'main' como global para que el simulador lo encuentre!
.globl InicializarSensor  # Declarar tus procedimientos también como globales
.globl LeerTemperatura

# --------------------------------------------------------------------------
# Procedimiento: InicializarSensor
# Descripción:   Intenta inicializar el sensor de temperatura.
# Retorna:       $v0 = Código de estado (0 = éxito, -1 = error/timeout)
# --------------------------------------------------------------------------
InicializarSensor:
    li      $t0, 0x2            # Carga el valor 0x2
    sw      $t0, SensorControl  # Escribe 0x2 en el registro de control

    li      $t3, 1000000        # Número máximo de iteraciones para el timeout

Wait_for_Sensor_Ready:
    lw      $t1, SensorEstado   # Carga el estado actual del sensor
    
    beq     $t1, 1, Sensor_Initialized_Success # Si $t1 == 1, salta a éxito

    li      $t2, -1             # Cargar -1 para comparar
    beq     $t1, $t2, Sensor_Error # Si $t1 == -1, salta a error

    subi    $t3, $t3, 1         # Decrementar el contador de iteraciones
    beq     $t3, $zero, Sensor_Timeout_Error # Si el contador es 0, ocurrió un timeout
    
    j       Wait_for_Sensor_Ready

Sensor_Timeout_Error:
    li      $v0, -1             # Retorna -1 para indicar error/timeout
    jr      $ra                 # Retornar

Sensor_Error:
    li      $v0, -1             # Retorna -1 para indicar error
    jr      $ra                 # Retornar

Sensor_Initialized_Success:
    li      $v0, 0              # Retorna 0 para indicar éxito
    jr      $ra                 # Retornar

# --------------------------------------------------------------------------
# Procedimiento: LeerTemperatura
# Descripción:   Lee el valor de temperatura del sensor.
# Retorna:       $v0 = Valor de temperatura (o 0 si hay error)
#                $a0 = Código de estado (0 = éxito, -1 = error/timeout)
# --------------------------------------------------------------------------
LeerTemperatura:
    li      $t3, 10       # Número máximo de iteraciones para el timeout

Wait_for_Data:
    lw      $t1, SensorEstado   # Carga el estado actual del sensor
    
    beq     $t1, 1, Data_Ready # Si $t1 == 1, salta a Data_Ready

    li      $t2, -1             # Cargar -1 para comparar
    beq     $t1, $t2, Temperature_Sensor_Error # Si $t1 == -1, salta a error

    subi    $t3, $t3, 1         # Decrementar el contador de iteraciones
    beq     $t3, $zero, Temperature_Timeout_Error # Si el contador es 0, ocurrió un timeout
    
    j       Wait_for_Data

Temperature_Timeout_Error:
    li      $v0, 0              # Retorna 0 como valor de temperatura (por defecto en error)
    li      $a0, -1             # Retorna -1 como código de error
    jr      $ra                 # Retornar

Temperature_Sensor_Error:
    li      $v0, 0              # Retorna 0 como valor de temperatura (por defecto en error)
    li      $a0, -1             # Retorna -1 como código de error
    jr      $ra                 # Retornar

Data_Ready:
    lw      $v0, SensorDatos    # Carga el valor de temperatura en $v0
    li      $a0, 0              # Retorna 0 como código de éxito

    jr      $ra                 # Retornar


# --------------------------------------------------------------------------
# PROGRAMA PRINCIPAL (MAIN)
# Aquí es donde el simulador MIPS empezará a ejecutar.
# --------------------------------------------------------------------------
main:
    # 1. Llamar a InicializarSensor
    jal     InicializarSensor
    
    # 2. Comprobar el resultado de InicializarSensor (está en $v0)
    move    $s0, $v0            # Guarda el código de retorno de InicializarSensor en $s0

    # Imprimir mensaje de inicialización
    beq     $s0, $zero, Init_Success_Print
    # Si no es 0 (es -1), entonces hubo error
    li      $v0, 4              # Código de servicio para imprimir string
    la      $a0, msg_init_err   # Carga la dirección del mensaje de error
    syscall                     # Imprime el mensaje
    j       End_Program         # Termina si la inicialización falló

Init_Success_Print:
    li      $v0, 4              # Código de servicio para imprimir string
    la      $a0, msg_init_ok    # Carga la dirección del mensaje de éxito
    syscall                     # Imprime el mensaje

    # 3. Llamar a LeerTemperatura si la inicialización fue exitosa
    jal     LeerTemperatura
    
    # 4. Comprobar los resultados de LeerTemperatura
    # $v0 tiene el valor de la temperatura
    # $a0 tiene el código de estado (0=OK, -1=ERROR)

    move    $s1, $v0            # Guarda el valor de la temperatura en $s1
    move    $s2, $a0            # Guarda el código de estado de lectura en $s2

    # Imprimir el valor de temperatura y su estado
    li      $v0, 4              # Código de servicio para imprimir string
    la      $a0, msg_temp_val   # Carga la dirección "Temperatura leida: "
    syscall                     # Imprime

    li      $v0, 1              # Código de servicio para imprimir entero
    move    $a0, $s1            # Carga el valor de temperatura ($s1) para imprimir
    syscall                     # Imprime la temperatura

    beq     $s2, $zero, Read_Success_Print
    # Si no es 0 (es -1), entonces hubo error en la lectura
    li      $v0, 4              # Código de servicio para imprimir string
    la      $a0, msg_status_err # Carga la dirección del mensaje " (Estado: ERROR)\n"
    syscall                     # Imprime el mensaje
    j       End_Program         # Termina si la lectura falló

Read_Success_Print:
    li      $v0, 4              # Código de servicio para imprimir string
    la      $a0, msg_status_ok  # Carga la dirección del mensaje " (Estado: OK)\n"
    syscall                     # Imprime el mensaje

End_Program:
    # Terminar el programa de forma limpia
    li      $v0, 10             # Código de servicio para terminar el programa (exit)
    syscall                     # Ejecuta el exit