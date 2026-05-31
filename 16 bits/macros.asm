; =============================================================================
; ARCHIVO DE MACROS: macros.asm
; INTEGRANTE: Karla Cristina Pat Canche
; PROYECTO FINAL: MONITOR DE PACIENTE UCI
; =============================================================================

; Macro 1: Desplegar una cadena de texto en pantalla terminada en '$'
MOSTRAR_CADENA macro cad
    push ax
    push dx
    mov ah, 09h
    lea dx, cad
    int 21h
    pop dx
    pop ax
endm

; Macro 1.5: Desplegar una cadena de texto terminada en '$' con un color específico (vía ImprimirConColor)
MOSTRAR_COLOR macro cad, color
    push bx
    push dx
    lea dx, cad
    mov bl, color
    call ImprimirConColor
    pop dx
    pop bx
endm

; Macro 1.6: Copiar búfer de entrada de DOS a una variable destino
COPIAR_BUFFER macro buf_in, var_out, len_out
    local copy_done, copy_loop
    push ax
    push cx
    push si
    push di
    
    xor cx, cx
    mov cl, buf_in[1]       ; Obtener longitud leída por DOS
    mov len_out, cx         ; Almacenar longitud
    or cx, cx
    jz copy_done
    
    lea si, buf_in[2]
    lea di, var_out
    rep movsb               ; Copiar cadena
copy_done:
    pop di
    pop si
    pop cx
    pop ax
endm

; Macro 1.7: Mostrar una variable de longitud dinámica temporalmente terminada en '$' con color
MOSTRAR_VAR_COLOR macro var, length, color
    push bx
    
    mov bx, length
    mov var[bx], '$'        ; Terminar temporalmente con '$'
    
    lea dx, var
    mov bl, color
    call ImprimirConColor
    
    mov bx, length
    mov byte ptr var[bx], ' ' ; Restaurar espacio original
    
    pop bx
endm

; Macro 2: Capturar entrada de texto por teclado usando buffer estructurado DOS
LEER_CADENA macro buffer_in
    push ax
    push dx
    mov ah, 0Ah
    lea dx, buffer_in
    int 21h
    pop dx
    pop ax
endm

; Macro 3: Limpiar la pantalla de la consola y mover cursor a 0,0
LIMPIAR_PANTALLA macro
    push ax
    push bx
    push cx
    push dx
    mov ax, 0600h       ; Limpiar pantalla
    mov bh, 07h         ; Blanco sobre Negro
    mov cx, 0000h       ; Inicio
    mov dx, 184Fh       ; Fin
    int 10h
    mov ah, 02h         ; Mover cursor
    mov bh, 00h
    mov dx, 0000h
    int 10h
    pop dx
    pop cx
    pop bx
    pop ax
endm

; Macro 4: Cerrar un archivo abierto en el sistema a partir de su handler
CERRAR_ARCHIVO macro handle
    push ax
    push bx
    mov ah, 3Eh
    mov bx, handle
    int 21h
    pop bx
    pop ax
endm

; Macro 5: Sonar el altavoz interno (PC Speaker) en DOSBox (puerto 61h)
; Genera una secuencia de alarma con 3 pitidos cortos (beep-beep-beep)
SONAR_ALARMA macro
    local beep_loop
    push ax
    push cx
    push dx
    
    mov cx, 3           ; Número de pitidos de la alarma
beep_loop:
    push cx             ; Guardar contador del loop externo
    
    ; 1. Configurar frecuencia en el PIT Canal 2 (~1200 Hz para tono agudo de alarma)
    mov al, 0B6h        ; Palabra de control: canal 2, LSB/MSB, onda cuadrada
    out 43h, al
    mov ax, 994         ; Divisor para ~1200 Hz (1,193,180 / 1200)
    out 42h, al         ; Enviar LSB
    mov al, ah
    out 42h, al         ; Enviar MSB

    ; 2. Encender altavoz
    in al, 61h          ; Obtener estado del puerto
    or al, 03h          ; Encender bocina
    out 61h, al         ; Escribir al puerto
    
    ; 3. Duración del pitido: 150 ms (000249F0h microsegundos) usando BIOS
    mov cx, 0002h
    mov dx, 49F0h
    mov ah, 86h
    int 15h
    
    ; 4. Apagar altavoz
    in al, 61h
    and al, 0FCh        ; Apagar bocina
    out 61h, al
    
    ; 5. Silencio corto entre pitidos: 150 ms (000249F0h microsegundos) usando BIOS
    mov cx, 0002h
    mov dx, 49F0h
    mov ah, 86h
    int 15h
    
    pop cx              ; Recuperar contador del loop externo
    loop beep_loop      ; Siguiente pitido
    
    pop dx
    pop cx
    pop ax
endm

; Macro de retardo simulando tiempo real usando interrupción 15h ah=86h
; secs: cantidad de segundos a esperar
RETARDO macro secs
    local r_loop
    push ax
    push cx
    push dx
    mov cx, secs
r_loop:
    push cx
    mov cx, 000Fh       ; 1 segundo = 1,000,000 microsegundos (000F4240h)
    mov dx, 4240h
    mov ah, 86h
    int 15h
    pop cx
    loop r_loop
    pop dx
    pop cx
    pop ax
endm

; =============================================================================
; PROCEDIMIENTOS DE TELEMETRÍA (Karla)
; =============================================================================

; Procedimiento: SimularComunicacion
; Simula el envío de una trama serial de telemetría y espera la respuesta central
SimularComunicacion PROC
    ; Inicializar IDs en trama con espacios
    mov cx, 4
    lea di, t_id
fill_sp_trama:
    mov byte ptr [di], ' '
    inc di
    loop fill_sp_trama

    ; Copiar ID
    lea si, paciente_id
    lea di, t_id
    mov cx, paciente_id_len
    or cx, cx
    jz copiar_trama_end
    cmp cx, 4
    jbe copiar_t_loop
    mov cx, 4
copiar_t_loop:
    mov al, [si]
    mov [di], al
    inc si
    inc di
    loop copiar_t_loop
copiar_trama_end:

    mov ax, pam
    lea di, t_pam
    call IntToString3

    mov ax, oxigenacion
    lea di, t_spo2
    call IntToString3

    mov ax, temp_f
    lea di, t_tempf
    call IntToString3

    ; Calcular Checksum
    lea si, trama
    xor ax, ax
calc_checksum_loop:
    lea bx, t_cs
    cmp si, bx
    je calc_checksum_end
    xor dx, dx
    mov dl, byte ptr [si]
    add ax, dx
    inc si
    jmp calc_checksum_loop
calc_checksum_end:
    mov bx, 100
    xor dx, dx
    div bx
    mov ax, dx
    lea di, t_cs
    call IntToString2

    MOSTRAR_COLOR msg_tx, 09h           ; Azul claro para TX
    MOSTRAR_CADENA newline
    MOSTRAR_COLOR trama, 0Dh            ; Magenta claro para la trama
    RETARDO 1           ; Retardo de 1 segundo para la transmisión serial
    MOSTRAR_COLOR msg_rx, 0Ah           ; Verde claro para RX ACK
    MOSTRAR_CADENA newline
    ret
SimularComunicacion ENDP

; Formatea enteros a una cadena de 2 caracteres numéricos
IntToString2 PROC
    push ax
    push bx
    push cx
    push dx
    
    mov bx, 10
    xor dx, dx
    div bx             ; AX = Cociente, DX = Residuo (unidades)
    add dl, '0'
    mov [di+1], dl     ; Unidades
    
    add al, '0'
    mov [di], al       ; Decenas
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret
IntToString2 ENDP
