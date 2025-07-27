.data
TensionControl:  .word 0x0   # Registro de control para iniciar la medición
TensionEstado:   .word 0x0   # Registro de estado (0: midiendo, 1: resultados listos)
TensionSistol:   .word 0x0   # Registro para la tensión sistólica
TensionDiastol:  .word 0x0   # Registro para la tensión diastólica

.text
.globl controlador_tension
.globl main   # ¡Declara main como global!

main:
    # Llama a tu procedimiento controlador_tension
    jal     controlador_tension

    # Después de que controlador_tension retorne, los resultados estarán en $v0, $v1, $a0
    # Puedes imprimir los resultados o hacer algo con ellos aquí.
    # Por ejemplo, imprimir la tensión sistólica ($v0)
    li      $v0, 1          # Código de servicio para imprimir entero (syscall)
    move    $a0, $v0        # Mueve el valor sistólico a $a0 para imprimir
    syscall                 # Ejecuta la impresión

    # Imprimir la tensión diastólica ($v1)
    li      $v0, 1          # Código de servicio para imprimir entero
    move    $a0, $v1        # Mueve el valor diastólico a $a0 para imprimir
    syscall                 # Ejecuta la impresión

    # Imprimir el código de estado ($a0)
    li      $v0, 1          # Código de servicio para imprimir entero
    # $a0 ya tiene el código de estado (0 o -1) de la llamada anterior, si no se sobreescribió
    # Si no lo tienes en $a0, tendrías que haberlo guardado:
    # move $a0, $s0  # Si guardaste el $a0 de retorno en $s0

    syscall                 # Ejecuta la impresión


    # Terminar el programa de forma limpia
    li      $v0, 10         # Código de servicio para terminar el programa (exit)
    syscall      

# --------------------------------------------------------------------------
# Procedimiento: controlador_tension
# Descripción:   Inicia la medición de la tensión arterial, espera con un
#                timeout, y retorna los valores y un código de estado.
# Retorna:       $v0 = Valor de la tensión sistólica (o 0 si hay error)
#                $v1 = Valor de la tensión diastólica (o 0 si hay error)
#                $a0 = Código de estado (0 = éxito, -1 = error por timeout)
# --------------------------------------------------------------------------
controlador_tension:
    # 1. Iniciar la medición
    li      $t0, 1              # Cargar el valor 1 en $t0
    sw      $t0, TensionControl # Escribir 1 en TensionControl para iniciar la medición

    li      $t3, 10     # Número máximo de iteraciones para el timeout (ajustar según necesidad)

Wait_for_Results:
    # 2. Esperar a que TensionEstado se convierta en 1
    lw      $t1, TensionEstado  # Cargar el valor actual de TensionEstado en $t1
    
    # Comprobar si el estado es 1 (resultados listos)
    beq     $t1, 1, Results_Ready # Si $t1 == 1, saltar a Results_Ready

    # Comprobar el timeout
    subi    $t3, $t3, 1         # Decrementar el contador de iteraciones
    beq     $t3, $zero, Timeout_Error # Si el contador es 0, ocurrió un timeout
    
    j       Wait_for_Results    # Continuar esperando

Timeout_Error:
    # Manejar el timeout: retornar código de error
    li      $v0, 0              # Sistólica = 0 (valor por defecto en caso de error)
    li      $v1, 0              # Diastólica = 0 (valor por defecto en caso de error)
    
    li      $a0, -1             # Cargar -1 en $a0 (¡ESTA ES LA CORRECCIÓN CLAVE!)
    
    jr      $ra                 # Retornar del procedimiento

Results_Ready:
    # 3. Cargar y retornar los resultados
    lw      $v0, TensionSistol  # Cargar la tensión sistólica en $v0
    lw      $v1, TensionDiastol # Cargar la tensión diastólica en $v1
    
    li      $a0, 0              # Cargar 0 en $a0 (¡ESTA ES LA CORRECCIÓN CLAVE!)

    jr      $ra                 # Retornar del procedimiento