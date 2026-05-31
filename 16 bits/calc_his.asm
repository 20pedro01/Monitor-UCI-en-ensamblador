; =============================================================================
; ARCHIVO DE CÁLCULOS HISTORIAL: calc_his.asm
; INTEGRANTE: Gabriel Danneshe Corona Noh
; PROYECTO FINAL: MONITOR DE PACIENTE UCI
; =============================================================================

; Procedimiento: CalcularPAM
; Calcula la Presión Arterial Media: PAM = (2 * Diastólica + Sistólica) / 3
CalcularPAM PROC
    mov ax, presion_diastolica
    mov bx, 2
    mul bx                     ; DX:AX = presion_diastolica * 2
    add ax, presion_sistolica  ; AX = (2 * Diastolica) + Sistolica
    mov bx, 3
    xor dx, dx
    div bx                     ; AX = AX / 3
    mov pam, ax
    ret
CalcularPAM ENDP

; Procedimiento: CalcularFahrenheit
; Convierte la temperatura de Celsius a Fahrenheit: F = (C * 9 / 5) + 32
CalcularFahrenheit PROC
    mov ax, temperatura
    mov bx, 9
    mul bx                     ; DX:AX = Celsius * 9
    mov bx, 5
    xor dx, dx
    div bx                     ; AX = AX / 5
    add ax, 32                 ; AX = (Celsius * 9 / 5) + 32
    mov temp_f, ax
    ret
CalcularFahrenheit ENDP

; Procedimiento Auxiliar: CargarHistorial
; Abre bitacora.txt en modo lectura y cuenta cuántas líneas (sesiones previas) existen
CargarHistorial PROC
    push ax
    push bx
    push cx
    push dx

    mov num_registros, 0
    
    ; Intentar abrir bitacora.txt para lectura
    mov ah, 3Dh
    mov al, 0           ; Solo lectura
    lea dx, file_bitacora
    int 21h
    jc done_historial   ; Si el archivo no existe (ej. primera ejecución), salir
    mov bx, ax          ; BX = handle del archivo
    
read_hist_loop:
    mov ah, 3Fh         ; Leer desde archivo
    mov bx, bx          ; (handle está en BX)
    mov cx, 1           ; Leer 1 byte
    lea dx, char_temp
    int 21h
    jc close_historial  ; Si hay error, cerrar y salir
    or ax, ax           ; ¿EOF (0 bytes leídos)?
    jz close_historial  ; Si es fin de archivo, cerrar y salir
    
    mov al, char_temp
    cmp al, 10          ; ¿Es salto de línea (LF)?
    jne read_hist_loop  ; Si no, seguir leyendo
    inc num_registros   ; Si es fin de línea, contar un registro más
    jmp read_hist_loop
    
close_historial:
    mov ah, 3Eh         ; Cerrar archivo
    int 21h
    
done_historial:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
CargarHistorial ENDP

; =============================================================================
; PROCEDIMIENTOS DE ARCHIVOS Y PARSING (Gabriel)
; =============================================================================

; Procedimiento: AbrirArchivos
; Abre el archivo de lecturas y de bitácora
AbrirArchivos PROC
    ; Abrir archivo de lecturas (lecturas.txt) modo Lectura
    mov ah, 3Dh
    mov al, 0           ; Solo lectura
    lea dx, file_lecturas
    int 21h
    jc error_lecturas
    mov handle_lecturas, ax

    ; Intentar abrir bitacora.txt en modo Escritura
    mov ah, 3Dh
    mov al, 1           ; Solo escritura
    lea dx, file_bitacora
    int 21h
    jnc set_bitacora_handle
    
    ; Si no existe, crearlo
    mov ah, 3Ch
    mov cx, 0           ; Archivo normal
    lea dx, file_bitacora
    int 21h
    jc error_bitacora
set_bitacora_handle:
    mov handle_bitacora, ax
    mov ax, 0
    ret

error_lecturas:
    mov ax, -1
    ret
error_bitacora:
    mov ax, -1
    ret
AbrirArchivos ENDP

; Procedimiento: ParserMuestra
; Lee y decodifica la siguiente línea de lecturas.txt
ParserMuestra PROC
    mov parser_index, 0
    mov val_acc, 0
read_char_loop:
    mov ah, 3Fh         ; Leer desde archivo
    mov bx, handle_lecturas
    mov cx, 1
    lea dx, char_temp
    int 21h
    jc error_parser
    or ax, ax
    jz check_eof_parser

    mov al, char_temp
    cmp al, 13
    je fin_linea
    cmp al, 10
    je fin_linea
    cmp al, ','
    je coma_detectada

    ; Si empieza con un comentario o cabecera (; o #), saltar la línea
    cmp al, ';'
    je check_start_comment
    cmp al, '#'
    je check_start_comment

    cmp al, '0'
    jl read_char_loop
    cmp al, '9'
    jg read_char_loop

    sub al, '0'
    mov ah, 0
    push ax
    mov ax, val_acc
    mov dx, 10
    mul dx
    pop bx
    add ax, bx
    mov val_acc, ax
    jmp read_char_loop

check_start_comment:
    cmp parser_index, 0
    jne read_char_loop
    cmp val_acc, 0
    jne read_char_loop

skip_comment_line:
    mov ah, 3Fh
    mov bx, handle_lecturas
    mov cx, 1
    lea dx, char_temp
    int 21h
    jc error_parser
    or ax, ax
    jz check_eof_comment
    
    mov al, char_temp
    cmp al, 13
    je end_comment_line
    cmp al, 10
    je end_comment_line
    jmp skip_comment_line

check_eof_comment:
    mov eof_flag, 1
    mov ax, 0
    ret

end_comment_line:
    ; Reiniciar el parser para leer la siguiente línea
    mov parser_index, 0
    mov val_acc, 0
    jmp read_char_loop

coma_detectada:
    call GuardarValor
    mov val_acc, 0
    inc parser_index
    jmp read_char_loop

fin_linea:
    cmp parser_index, 4
    jne read_char_loop
    call GuardarValor
    mov ax, 1
    ret

check_eof_parser:
    cmp parser_index, 0
    jne guardar_ultimo
    mov eof_flag, 1
    mov ax, 0
    ret

guardar_ultimo:
    call GuardarValor
    mov ax, 1
    ret

error_parser:
    mov ax, -1
    ret
ParserMuestra ENDP

; Procedimiento Auxiliar: GuardarValor
; Asigna el valor del acumulador a la variable correspondiente del paciente
GuardarValor PROC
    mov ax, val_acc
    cmp parser_index, 0
    je asig_rc
    cmp parser_index, 1
    je asig_sis
    cmp parser_index, 2
    je asig_dia
    cmp parser_index, 3
    je asig_spo2
    cmp parser_index, 4
    je asig_temp
    ret
asig_rc:
    mov ritmo_cardiaco, ax
    ret
asig_sis:
    mov presion_sistolica, ax
    ret
asig_dia:
    mov presion_diastolica, ax
    ret
asig_spo2:
    mov oxigenacion, ax
    ret
asig_temp:
    mov temperatura, ax
    ret
GuardarValor ENDP

; Procedimiento: EscribirBitacora
; Guarda un registro con los datos del paciente en bitacora.txt
EscribirBitacora PROC
    ; Posicionarse al final del archivo para anexar (Seek End)
    mov ah, 42h
    mov al, 2           ; Desde fin de archivo
    mov bx, handle_bitacora
    xor cx, cx
    xor dx, dx
    int 21h

    ; Rellenar ID con espacios
    mov cx, 4
    lea di, l_id
fill_sp_log:
    mov byte ptr [di], ' '
    inc di
    loop fill_sp_log

    lea si, paciente_id
    lea di, l_id
    mov cx, paciente_id_len
    or cx, cx
    jz copiar_log_id_end
    cmp cx, 4
    jbe copiar_log_id_loop
    mov cx, 4
copiar_log_id_loop:
    mov al, [si]
    mov [di], al
    inc si
    inc di
    loop copiar_log_id_loop
copiar_log_id_end:

    mov ax, ritmo_cardiaco
    lea di, l_fc
    call IntToString3

    mov ax, pam
    lea di, l_pam
    call IntToString3

    mov ax, oxigenacion
    lea di, l_spo2
    call IntToString3

    mov ax, temperatura
    lea di, l_tempc
    call IntToString2

    mov ax, temp_f
    lea di, l_tempf
    call IntToString3

    mov ax, estado_salud
    cmp ax, 0
    je log_normal
    cmp ax, 1
    je log_alerta
    lea si, str_critico
    jmp copiar_estado_log
log_normal:
    lea si, str_normal
    jmp copiar_estado_log
log_alerta:
    lea si, str_alerta

copiar_estado_log:
    lea di, l_est
    mov cx, 8
copiar_est_l_loop:
    mov al, [si]
    mov [di], al
    inc si
    inc di
    loop copiar_est_l_loop

    ; Guardar reporte en el archivo
    mov ah, 40h         ; Escribir a archivo
    mov bx, handle_bitacora
    mov cx, log_line_len
    lea dx, log_line
    int 21h
    ret
EscribirBitacora ENDP
