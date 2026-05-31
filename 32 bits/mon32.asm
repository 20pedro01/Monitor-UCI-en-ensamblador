; =============================================================================
; PROYECTO FINAL: MONITOR DE PACIENTE UCI (TEMA 4: PROGRAMACION DE DISPOSITIVOS)
; ASIGNATURA: LENGUAJES DE INTERFAZ - GRUPO 6C
; INTEGRANTES DEL EQUIPO:
;   - Cauich Pat Pedro Antonio
;   - Chan Xooc Brenda Argelia
;   - Corona Noh Gabriel Danneshe
;   - Pat Canche Karla Cristina
; =============================================================================

.386
.model flat, stdcall
.stack 4096

; Incluir la biblioteca Irvine32 (incluye SmallWin.inc con APIs de Windows)
include Irvine32.inc

; Prototipo de la función Beep de la API de Windows (para compilar en Windows/Wine nativo)
Beep PROTO, dwFreq:DWORD, dwDuration:DWORD

; Prototipo de la función GetCurrentDirectory de la API de Windows
GetCurrentDirectoryA PROTO, nBufferLength:DWORD, lpBuffer:PTR BYTE
GetCurrentDirectory EQU <GetCurrentDirectoryA>

; =============================================================================
; SEGMENTO DE DATOS
; =============================================================================
.data

    ; Nombres de archivos físicos (Cadenas ASCIIZ terminadas en 0)
    file_lecturas       db "lecturas.txt", 0
    file_bitacora       db "bitacora.txt", 0

    ; Handles de archivos (32 bits)
    handle_lecturas     dd ?
    handle_bitacora     dd ?

    ; Variables auxiliares para parser de archivos
    char_temp           db ?
    val_acc             dd 0
    parser_index        dd 0
    eof_flag            db 0

    ; Estructuras de Captura de Datos (Buffers estructurados estilo DOS)
    paciente_id_buf     db 30, 0, 30 dup(0)
    nombre_paciente_buf db 60, 0, 60 dup(0)

    paciente_id         db 30 dup(' ')
    paciente_id_len     dd 0
    nombre_paciente     db 60 dup(' ')
    nombre_paciente_len dd 0

    ; Variables para complementar los 8 datos de entrada requeridos por la rúbrica
    edad_buf            db 5, 0, 5 dup(0)
    edad                db 5 dup(' ')
    edad_len            dd 0

    genero_buf          db 10, 0, 10 dup(0)
    genero              db 10 dup(' ')
    genero_len          dd 0

    peso_buf            db 6, 0, 6 dup(0)
    peso                db 6 dup(' ')
    peso_len            dd 0

    estatura_buf        db 6, 0, 6 dup(0)
    estatura            db 6 dup(' ')
    estatura_len        dd 0

    cama_buf            db 5, 0, 5 dup(0)
    cama                db 5 dup(' ')
    cama_len            dd 0

    medico_buf          db 50, 0, 50 dup(0)
    medico              db 50 dup(' ')
    medico_len          dd 0

    ; Variables de Signos Vitales (Almacenamiento de al menos 8 datos distintos en memoria)
    ritmo_cardiaco      dd 0                     ; Dato 1: Frecuencia Cardíaca (FC)
    presion_sistolica   dd 0                     ; Dato 2: Presión Sistólica (SIS)
    presion_diastolica  dd 0                     ; Dato 3: Presión Diastólica (DIA)
    oxigenacion         dd 0                     ; Dato 4: Oxigenación (SpO2)
    temperatura         dd 0                     ; Dato 5: Temperatura Celsius (TEMP_C)
    pam                 dd 0                     ; Dato 6: Presión Arterial Media
    temp_f              dd 0                     ; Dato 7: Temperatura Fahrenheit (TEMP_F)
    estado_salud        dd 0                     ; Dato 8: Estado clínico (0=Normal, 1=Alerta, 2=Critico)

    ; Constantes de estado (Texto exacto de 8 caracteres para la bitácora)
    str_normal          db "NORMAL  "
    str_alerta          db "ALERTA  "
    str_critico         db "CRITICO "

    ; Cadenas de texto para diseño de interfaz de consola
    msg_titulo          db "=============================================", 0
    msg_titulo2         db "    MONITOR DE PACIENTE UCI - SISTEMA V1.0   ", 0
    msg_titulo3         db "=============================================", 0
    
    msg_id              db "Ingrese No. Expediente: ", 0
    msg_nombre          db "Ingrese Nombre del paciente: ", 0
    msg_edad            db "Ingrese Edad del paciente: ", 0
    msg_genero          db "Ingrese Genero del paciente (M/F): ", 0
    msg_peso            db "Ingrese Peso del paciente (kg): ", 0
    msg_estatura        db "Ingrese Estatura del paciente (cm): ", 0
    msg_cama            db "Ingrese Numero de Cama: ", 0
    msg_medico          db "Ingrese Medico Responsable: ", 0
    msg_err_vacio       db "Error: Campo obligatorio. Intente de nuevo.", 0
    msg_err_numero      db "Error: Debe ingresar solo numeros enteros.", 0
    msg_err_genero      db "Error: Debe ingresar M (Masculino) o F (Femenino).", 0
    msg_err_decimal     db "Error: Debe ingresar un numero valido (entero o decimal).", 0
    msg_iniciando       db "Iniciando captura y lectura de sensores...", 0
    
    msg_paciente        db "NO. EXPEDIENTE: ", 0
    msg_nombre_lbl      db "NOMBRE: ", 0
    msg_lbl_edad        db " | EDAD: ", 0
    msg_lbl_genero      db " | GENERO: ", 0
    msg_lbl_peso        db "PESO: ", 0
    msg_lbl_estatura    db " kg | ESTATURA: ", 0
    msg_unit_estatura   db " cm", 0
    msg_lbl_cama        db " | CAMA: ", 0
    msg_lbl_medico      db "MEDICO: ", 0
    msg_sec_datos       db "Signos Vitales del Paciente:", 0
    msg_lbl_fc          db "  - Frecuencia Cardiaca:  ", 0
    msg_unit_fc         db " bpm", 0
    msg_lbl_presion     db "  - Presion Arterial:     ", 0
    msg_slash           db " / ", 0
    msg_unit_presion    db " mmHg", 0
    msg_lbl_pam         db "  - Presion Media (PAM):  ", 0
    msg_lbl_spo2        db "  - Oxigeno (SpO2):       ", 0
    msg_unit_spo2       db " %", 0
    msg_lbl_temp        db "  - Temperatura Corporal: ", 0
    msg_unit_temp       db " C (", 0
    msg_unit_temp_f     db " F)", 0
    
    msg_lbl_estado      db "---------------------------------------------", 0
    msg_lbl_estado2     db "ESTADO CLINICO: ", 0
    
    msg_txt_normal      db "NORMAL (Estable)", 0
    msg_txt_alerta      db "ALERTA (Bajo observacion)", 0
    msg_txt_critico     db "CRITICO (Emergencia de UCI - Alarma activada)", 0
    
    msg_separador       db "=============================================", 0
    msg_err_archivo     db "Error en la apertura o lectura de archivos.", 0
    msg_err_lecturas    db "Error: No se pudo abrir lecturas.txt", 0
    msg_err_bitacora    db "Error: No se pudo crear o abrir bitacora.txt", 0
    msg_fin_sim         db "Fin de la simulacion de lecturas de sensores.", 0
    msg_cur_dir         db "Directorio actual en Wine: ", 0
    buf_cur_dir         db 260 dup(0)

    ; Variables para el historial (Manejo de archivos: leer y modificar el mismo archivo)
    num_registros       dd 0
    msg_historial_1     db "Historial: Se detectaron ", 0
    msg_historial_2     db " registros previos en bitacora.txt.", 0

    ; Buffers para formatear números en memoria
    str_num3            db "   ", 0                 ; 3 caracteres para pantalla
    str_num2            db "  ", 0                  ; 2 caracteres para pantalla
    newline             db 13, 10, 0
    heart_state         db 0
    space_str           db "  ", 0

    ; Estructura de la Trama Serial Simulada (TX)
    trama               db "[TX:EXP="
    t_id                db "XXXX"
                        db ",PAM="
    t_pam               db "XXX"
                        db ",SPO2="
    t_spo2              db "XXX"
                        db ",TEMPF="
    t_tempf             db "XXX"
                        db ",CS="
    t_cs                db "XX"
                        db "]", 13, 10, 0
                        
    msg_tx              db " [TX-COM1]: Transmitiendo trama de telemetria...", 0
    msg_rx              db " [RX-COM1]: Comando central recibido -> [ACK: OK]", 0

    ; Buffer de línea de Log para escribir en bitacora.txt
    log_line            db "EXPEDIENTE: "
    l_id                db "XXXX"
                        db " | FC: "
    l_fc                db "XXX"
                        db " | PAM: "
    l_pam               db "XXX"
                        db " | SPO2: "
    l_spo2              db "XXX"
                        db " | TEMP: "
    l_tempc             db "XX"
                        db "C ("
    l_tempf             db "XXX"
                        db "F) | ESTADO: "
    l_est               db "XXXXXXXX"
                        db 13, 10
    log_line_len        equ $ - log_line

; =============================================================================
; SEGMENTO DE CODIGO
; =============================================================================
.code

; Incluir archivos de código y macros externos (Modularidad física de 4 archivos)
include macs32.asm
include calc_his.asm
include eval_int.asm

main PROC
    ; Obtener y mostrar el directorio actual de Wine para depuración
    INVOKE GetCurrentDirectory, 260, offset buf_cur_dir
    MOSTRAR_CADENA msg_cur_dir
    MOSTRAR_CADENA buf_cur_dir
    MOSTRAR_CADENA newline
    RETARDO 1

    ; Cargar historial de bitacora.txt (mismo archivo que se modificará más tarde)
    call CargarHistorial

    LIMPIAR_PANTALLA
    MOSTRAR_CADENA msg_titulo
    MOSTRAR_CADENA newline
    MOSTRAR_CADENA msg_titulo2
    MOSTRAR_CADENA newline
    MOSTRAR_CADENA msg_titulo3
    MOSTRAR_CADENA newline

    ; Mostrar reporte de historial previo cargado
    mov eax, num_registros
    lea edi, str_num3
    call IntToString3
    MOSTRAR_COLOR msg_historial_1, 0Bh   ; Celeste
    MOSTRAR_COLOR str_num3, 0Eh          ; Amarillo
    MOSTRAR_COLOR msg_historial_2, 0Bh   ; Celeste
    MOSTRAR_CADENA newline
    MOSTRAR_CADENA newline
    RETARDO 2                            ; Pausa de 2 segundos para visualizarlo
    
    LIMPIAR_PANTALLA
    MOSTRAR_CADENA msg_titulo
    MOSTRAR_CADENA newline
    MOSTRAR_CADENA msg_titulo2
    MOSTRAR_CADENA newline
    MOSTRAR_CADENA msg_titulo3
    MOSTRAR_CADENA newline

    ; Captura de ID de Paciente (Dato 1 - Numerico)
captura_id:
    MOSTRAR_CADENA msg_id
    LEER_CADENA paciente_id_buf
    MOSTRAR_CADENA newline
    lea esi, paciente_id_buf
    call ValidarNumerico
    or al, al
    jz id_ok
    MOSTRAR_COLOR msg_err_numero, 0Ch   ; Imprimir error en Rojo Claro
    MOSTRAR_CADENA newline
    jmp captura_id
id_ok:
    COPIAR_BUFFER paciente_id_buf, paciente_id, paciente_id_len

    ; Captura de Nombre de Paciente (Dato 2 - Obligatorio no vacio)
captura_nombre:
    MOSTRAR_CADENA msg_nombre
    LEER_CADENA nombre_paciente_buf
    MOSTRAR_CADENA newline
    lea esi, nombre_paciente_buf
    call ValidarVacio
    or al, al
    jz nombre_ok
    MOSTRAR_COLOR msg_err_vacio, 0Ch
    MOSTRAR_CADENA newline
    jmp captura_nombre
nombre_ok:
    COPIAR_BUFFER nombre_paciente_buf, nombre_paciente, nombre_paciente_len

    ; Captura de Edad (Dato 3 - Numerico)
captura_edad:
    MOSTRAR_CADENA msg_edad
    LEER_CADENA edad_buf
    MOSTRAR_CADENA newline
    lea esi, edad_buf
    call ValidarNumerico
    or al, al
    jz edad_ok
    MOSTRAR_COLOR msg_err_numero, 0Ch
    MOSTRAR_CADENA newline
    jmp captura_edad
edad_ok:
    COPIAR_BUFFER edad_buf, edad, edad_len

    ; Captura de Género (Dato 4 - M/F)
captura_genero:
    MOSTRAR_CADENA msg_genero
    LEER_CADENA genero_buf
    MOSTRAR_CADENA newline
    lea esi, genero_buf
    call ValidarGenero
    or al, al
    jz genero_ok
    MOSTRAR_COLOR msg_err_genero, 0Ch
    MOSTRAR_CADENA newline
    jmp captura_genero
genero_ok:
    COPIAR_BUFFER genero_buf, genero, genero_len

    ; Captura de Peso (Dato 5 - Decimal/Numerico)
captura_peso:
    MOSTRAR_CADENA msg_peso
    LEER_CADENA peso_buf
    MOSTRAR_CADENA newline
    lea esi, peso_buf
    call ValidarDecimal
    or al, al
    jz peso_ok
    MOSTRAR_COLOR msg_err_decimal, 0Ch
    MOSTRAR_CADENA newline
    jmp captura_peso
peso_ok:
    COPIAR_BUFFER peso_buf, peso, peso_len

    ; Captura de Estatura (Dato 6 - Numerico)
captura_estatura:
    MOSTRAR_CADENA msg_estatura
    LEER_CADENA estatura_buf
    MOSTRAR_CADENA newline
    lea esi, estatura_buf
    call ValidarNumerico
    or al, al
    jz estatura_ok
    MOSTRAR_COLOR msg_err_numero, 0Ch
    MOSTRAR_CADENA newline
    jmp captura_estatura
estatura_ok:
    COPIAR_BUFFER estatura_buf, estatura, estatura_len

    ; Captura de Número de Cama (Dato 7 - Obligatorio no vacio)
captura_cama:
    MOSTRAR_CADENA msg_cama
    LEER_CADENA cama_buf
    MOSTRAR_CADENA newline
    lea esi, cama_buf
    call ValidarVacio
    or al, al
    jz cama_ok
    MOSTRAR_COLOR msg_err_vacio, 0Ch
    MOSTRAR_CADENA newline
    jmp captura_cama
cama_ok:
    COPIAR_BUFFER cama_buf, cama, cama_len

    ; Captura de Médico Responsable (Dato 8 - Obligatorio no vacio)
captura_medico:
    MOSTRAR_CADENA msg_medico
    LEER_CADENA medico_buf
    MOSTRAR_CADENA newline
    lea esi, medico_buf
    call ValidarVacio
    or al, al
    jz medico_ok
    MOSTRAR_COLOR msg_err_vacio, 0Ch
    MOSTRAR_CADENA newline
    jmp captura_medico
medico_ok:
    COPIAR_BUFFER medico_buf, medico, medico_len

    MOSTRAR_CADENA msg_iniciando
    MOSTRAR_CADENA newline
    RETARDO 1

    ; Apertura de Archivos
    call AbrirArchivos
    cmp eax, -1
    je fin_con_error

    mov eof_flag, 0

; -----------------------------------------------------------------------------
; CICLO PRINCIPAL
; -----------------------------------------------------------------------------
sim_loop:
    call ParserMuestra
    cmp eax, 1
    jne check_end_sim

    call CalcularPAM
    call CalcularFahrenheit
    call EvaluarEstado

    call DibujarConsola
    call SimularComunicacion
    call EscribirBitacora

    mov eax, estado_salud
    cmp eax, 2
    jne no_sonar
    SONAR_ALARMA
no_sonar:
    
    RETARDO 3           ; Espera de 3 segundos para poder apreciar los datos en pantalla
    jmp sim_loop

check_end_sim:
    mov al, eof_flag
    cmp al, 1
    je fin_exito
    MOSTRAR_CADENA msg_err_archivo
    MOSTRAR_CADENA newline
    jmp cerrar_y_salir

fin_exito:
    MOSTRAR_CADENA msg_fin_sim
    MOSTRAR_CADENA newline

cerrar_y_salir:
    CERRAR_ARCHIVO handle_lecturas
    CERRAR_ARCHIVO handle_bitacora
    jmp salir

fin_con_error:
    MOSTRAR_CADENA msg_err_archivo
    MOSTRAR_CADENA newline

salir:
    exit
main ENDP

; =============================================================================
; PROCEDIMIENTOS DE VALIDACIÓN DE ENTRADAS DE TECLADO
; =============================================================================

; Verifica si el búfer de entrada está vacío
; Entrada: ESI = Dirección del búfer estructurado estilo DOS
; Salida:  AL = 0 (Válido), AL = 1 (Vacío)
ValidarVacio PROC
    push ebx
    xor eax, eax
    mov al, [esi+1]      ; Obtener longitud real ingresada
    or al, al
    jz es_vacio
    mov al, 0           ; No vacío (válido)
    jmp done_vacio
es_vacio:
    mov al, 1           ; Vacío (inválido)
done_vacio:
    pop ebx
    ret
ValidarVacio ENDP

; Verifica si el búfer contiene únicamente dígitos numéricos y no está vacío
; Entrada: ESI = Dirección del búfer estructurado estilo DOS
; Salida:  AL = 0 (Válido), AL = 1 (Contiene caracteres no numéricos o vacío)
ValidarNumerico PROC
    push ecx
    push esi
    
    xor eax, eax
    movzx ecx, byte ptr [esi+1]      ; ECX = longitud ingresada
    or ecx, ecx
    jz num_invalido     ; Si está vacío, es inválido
    
    add esi, 2           ; ESI apunta al inicio de los caracteres
chk_num_loop:
    mov al, [esi]
    cmp al, '0'
    jl num_invalido
    cmp al, '9'
    jg num_invalido
    inc esi
    loop chk_num_loop
    
    mov al, 0           ; Todo numérico (válido)
    jmp done_num_chk
    
num_invalido:
    mov al, 1           ; Inválido
done_num_chk:
    pop esi
    pop ecx
    ret
ValidarNumerico ENDP

; Verifica si el género ingresado es válido (M, m, F, f)
; Entrada: ESI = Dirección del búfer estructurado estilo DOS
; Salida:  AL = 0 (Válido), AL = 1 (Inválido)
ValidarGenero PROC
    push ebx
    xor eax, eax
    mov al, [esi+1]      ; Obtener longitud
    cmp al, 1
    jne gen_invalido    ; Debe ser de longitud 1
    
    mov al, [esi+2]      ; Obtener el carácter ingresado
    cmp al, 'M'
    je gen_valido
    cmp al, 'm'
    je gen_valido
    cmp al, 'F'
    je gen_valido
    cmp al, 'f'
    je gen_valido
    
gen_invalido:
    mov al, 1
    jmp done_gen_chk
gen_valido:
    mov al, 0
done_gen_chk:
    pop ebx
    ret
ValidarGenero ENDP

; Verifica si el búfer contiene un número decimal o entero válido (con un punto opcional y máx 3 decimales)
; Entrada: ESI = Dirección del búfer estructurado estilo DOS
; Salida:  AL = 0 (Válido), AL = 1 (Inválido)
ValidarDecimal PROC
    push ecx
    push esi
    push ebx
    push edx
    
    xor eax, eax
    movzx ecx, byte ptr [esi+1]      ; ECX = longitud ingresada
    or ecx, ecx
    jz dec_invalido     ; Si está vacío, es inválido
    
    xor ebx, ebx          ; BH = contador de puntos (0 o 1), BL = índice actual (0-based)
    xor edx, edx          ; DH = contador de decimales
    add esi, 2           ; ESI apunta al inicio de los caracteres
    
chk_dec_loop:
    mov al, [esi]
    cmp al, '.'
    je es_punto
    
    ; Verificar si es dígito
    cmp al, '0'
    jl dec_invalido
    cmp al, '9'
    jg dec_invalido
    
    ; Si ya pasamos el punto decimal, contar decimales
    cmp bh, 1
    jne next_char
    inc dh              ; Incrementar dígitos decimales
    cmp dh, 3
    jg dec_invalido     ; Más de 3 decimales -> inválido
    jmp next_char
    
es_punto:
    inc bh              ; Incrementar contador de puntos (BH)
    cmp bh, 1
    jg dec_invalido     ; Más de un punto -> inválido
    
    ; El punto no puede ser el primer ni el último carácter
    cmp bl, 0
    je dec_invalido     ; Primer carácter -> inválido
    
    mov al, cl
    dec al              ; AL = longitud - 1 (último índice)
    cmp bl, al
    je dec_invalido     ; Último carácter -> inválido
    
next_char:
    inc esi
    inc bl              ; Incrementar índice actual
    loop chk_dec_loop
    
    mov al, 0           ; Válido
    jmp done_dec_chk
    
dec_invalido:
    mov al, 1           ; Inválido
done_dec_chk:
    pop edx
    pop ebx
    pop esi
    pop ecx
    ret
ValidarDecimal ENDP

END main
