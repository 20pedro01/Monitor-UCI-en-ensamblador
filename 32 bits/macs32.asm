; =============================================================================
; ARCHIVO DE MACROS: macs32.asm (32 bits)
; INTEGRANTE: Karla Cristina Pat Canche
; PROYECTO FINAL: MONITOR DE PACIENTE UCI
; =============================================================================

; Macro 1: Desplegar una cadena de texto en pantalla terminada en 0 (Null-terminated)
MOSTRAR_CADENA macro cad
    push edx
    mov edx, offset cad
    call WriteString
    pop edx
endm

; Macro 1.5: Desplegar una cadena de texto terminada en 0 con un color específico (vía ImprimirConColor)
MOSTRAR_COLOR macro cad, color
    push ebx
    push edx
    mov edx, offset cad
    mov bl, color
    call ImprimirConColor
    pop edx
    pop ebx
endm

; Macro 1.6: Copiar búfer de entrada a una variable destino y calcular longitud
COPIAR_BUFFER macro buf_in, var_out, len_out
    local copy_done
    push eax
    push ecx
    push esi
    push edi
    
    xor ecx, ecx
    mov cl, [buf_in + 1]       ; Obtener longitud leída
    mov len_out, ecx         ; Almacenar longitud (32-bit)
    or ecx, ecx
    jz copy_done
    
    lea esi, [buf_in + 2]
    lea edi, var_out
    rep movsb               ; Copiar cadena
copy_done:
    pop edi
    pop esi
    pop ecx
    pop eax
endm

; Macro 1.7: Mostrar una variable de longitud dinámica temporalmente terminada en 0 con color
MOSTRAR_VAR_COLOR macro var, length, color
    push ebx
    
    mov ebx, length
    mov byte ptr [var + ebx], 0        ; Terminar temporalmente con null
    
    push edx
    lea edx, var
    mov bl, color
    call ImprimirConColor
    pop edx
    
    mov ebx, length
    mov byte ptr [var + ebx], ' ' ; Restaurar espacio original
    
    pop ebx
endm

; Macro 2: Capturar entrada de texto por teclado usando buffer estructurado
LEER_CADENA macro buffer_in
    push ecx
    push edx
    lea edx, buffer_in + 2
    movzx ecx, byte ptr [buffer_in] ; Max chars
    call ReadString
    mov [buffer_in + 1], al         ; Guardar longitud real leída
    pop edx
    pop ecx
endm

; Macro 3: Limpiar la pantalla de la consola
LIMPIAR_PANTALLA macro
    call Clrscr
endm

; Macro 4: Cerrar un archivo abierto en el sistema a partir de su handler
CERRAR_ARCHIVO macro handle
    push eax
    mov eax, handle
    call CloseFile
    pop eax
endm

; Macro 5: Sonar la alarma mediante la API Beep de Windows y el caracter Bell (ASCII 7)
SONAR_ALARMA macro
    INVOKE Beep, 1000, 300
    push eax
    mov al, 07h
    call WriteChar
    pop eax
endm

; Macro de retardo en segundos usando la función nativa de Irvine32
RETARDO macro secs
    push eax
    mov eax, secs
    imul eax, 1000
    call Delay
    pop eax
endm

; =============================================================================
; PROCEDIMIENTOS DE TELEMETRÍA (Karla)
; =============================================================================

; Procedimiento: SimularComunicacion
; Simula el envío de una trama serial de telemetría y espera la respuesta central
SimularComunicacion PROC
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi

    ; Inicializar IDs en trama con espacios
    mov ecx, 4
    lea edi, t_id
fill_sp_trama:
    mov byte ptr [edi], ' '
    inc edi
    loop fill_sp_trama

    ; Copiar ID
    lea esi, paciente_id
    lea edi, t_id
    mov ecx, paciente_id_len
    or ecx, ecx
    jz copiar_trama_end
    cmp ecx, 4
    jbe copiar_t_loop
    mov ecx, 4
copiar_t_loop:
    mov al, [esi]
    mov [edi], al
    inc esi
    inc edi
    loop copiar_t_loop
copiar_trama_end:

    mov eax, pam
    lea edi, t_pam
    call IntToString3

    mov eax, oxigenacion
    lea edi, t_spo2
    call IntToString3

    mov eax, temp_f
    lea edi, t_tempf
    call IntToString3

    ; Calcular Checksum
    lea esi, trama
    xor eax, eax
calc_checksum_loop:
    lea ebx, t_cs
    cmp esi, ebx
    je calc_checksum_end
    movzx edx, byte ptr [esi]
    add eax, edx
    inc esi
    jmp calc_checksum_loop
calc_checksum_end:
    mov ebx, 100
    xor edx, edx
    div ebx
    mov eax, edx
    lea edi, t_cs
    call IntToString2

    MOSTRAR_COLOR msg_tx, 09h           ; Azul claro para TX
    MOSTRAR_CADENA newline
    MOSTRAR_COLOR trama, 0Dh            ; Magenta claro para la trama
    RETARDO 1           ; Retardo de 1 segundo para la transmisión serial
    MOSTRAR_COLOR msg_rx, 0Ah           ; Verde claro para RX ACK
    MOSTRAR_CADENA newline
    
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
SimularComunicacion ENDP

; Formatea enteros a una cadena de 2 caracteres numéricos
IntToString2 PROC
    push eax
    push ebx
    push ecx
    push edx
    
    mov ebx, 10
    xor edx, edx
    div ebx             ; EAX = Cociente, EDX = Residuo (unidades)
    add dl, '0'
    mov [edi+1], dl     ; Unidades
    
    add al, '0'
    mov [edi], al       ; Decenas
    
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
IntToString2 ENDP
