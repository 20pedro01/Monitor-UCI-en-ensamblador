; =============================================================================
; ARCHIVO DE CÁLCULOS HISTORIAL: calc_his.asm (32 bits)
; INTEGRANTE: Gabriel Danneshe Corona Noh
; PROYECTO FINAL: MONITOR DE PACIENTE UCI
; =============================================================================

; Procedimiento: CalcularPAM
; Calcula la Presión Arterial Media: PAM = (2 * Diastólica + Sistólica) / 3
CalcularPAM PROC
    push ebx
    push edx
    mov eax, presion_diastolica
    mov ebx, 2
    mul ebx                     ; EDX:EAX = presion_diastolica * 2
    add eax, presion_sistolica  ; EAX = (2 * Diastolica) + Sistolica
    mov ebx, 3
    xor edx, edx
    div ebx                     ; EAX = EAX / 3
    mov pam, eax
    pop edx
    pop ebx
    ret
CalcularPAM ENDP

; Procedimiento: CalcularFahrenheit
; Convierte la temperatura de Celsius a Fahrenheit: F = (C * 9 / 5) + 32
CalcularFahrenheit PROC
    push ebx
    push edx
    mov eax, temperatura
    mov ebx, 9
    mul ebx                     ; EDX:EAX = Celsius * 9
    mov ebx, 5
    xor edx, edx
    div ebx                     ; EAX = EAX / 5
    add eax, 32                 ; EAX = (Celsius * 9 / 5) + 32
    mov temp_f, eax
    pop edx
    pop ebx
    ret
CalcularFahrenheit ENDP

; Procedimiento Auxiliar: CargarHistorial
; Abre bitacora.txt en modo lectura y cuenta cuántas líneas (sesiones previas) existen
CargarHistorial PROC
    push eax
    push ebx
    push ecx
    push edx

    mov num_registros, 0
    
    ; Intentar abrir bitacora.txt para lectura
    mov edx, offset file_bitacora
    call OpenInputFile
    cmp eax, -1                  ; INVALID_HANDLE_VALUE
    je done_historial
    mov ebx, eax                 ; EBX = handle del archivo
    
read_hist_loop:
    mov eax, ebx
    mov edx, offset char_temp
    mov ecx, 1
    call ReadFromFile
    jc close_historial
    or eax, eax
    jz close_historial
    
    mov al, char_temp
    cmp al, 10                  ; ¿Es salto de línea (LF)?
    jne read_hist_loop          ; Si no, seguir leyendo
    inc num_registros           ; Si es fin de línea, contar un registro más
    jmp read_hist_loop
    
close_historial:
    mov eax, ebx
    call CloseFile
    
done_historial:
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
CargarHistorial ENDP

; =============================================================================
; PROCEDIMIENTOS DE ARCHIVOS Y PARSING (Gabriel)
; =============================================================================

; Procedimiento: AbrirArchivos
; Abre el archivo de lecturas y de bitácora
AbrirArchivos PROC
    ; Abrir archivo de lecturas (lecturas.txt) modo Lectura
    mov edx, offset file_lecturas
    call OpenInputFile
    mov handle_lecturas, eax
    cmp eax, -1
    je error_lecturas

    ; Abrir/Crear bitacora.txt utilizando la API de Windows CreateFile
    INVOKE CreateFile,
        offset file_bitacora,
        40000000h,      ; GENERIC_WRITE (Acceso de escritura)
        0,              ; Sin compartir
        0,              ; Sin seguridad
        4,              ; OPEN_ALWAYS (Abre si existe, crea si no)
        80h,            ; FILE_ATTRIBUTE_NORMAL
        0
    mov handle_bitacora, eax
    cmp eax, -1
    je error_bitacora

    mov eax, 0
    ret

error_lecturas:
    mov eax, -1
    ret
error_bitacora:
    mov eax, -1
    ret
AbrirArchivos ENDP

; Procedimiento: ParserMuestra
; Lee y decodifica la siguiente línea de lecturas.txt
ParserMuestra PROC
    push ebx
    push ecx
    push edx
    
    mov parser_index, 0
    mov val_acc, 0
read_char_loop:
    mov eax, handle_lecturas
    mov edx, offset char_temp
    mov ecx, 1
    call ReadFromFile
    jc error_parser
    or eax, eax
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
    movzx eax, al
    push eax
    mov eax, val_acc
    mov edx, 10
    mul edx
    pop ebx
    add eax, ebx
    mov val_acc, eax
    jmp read_char_loop

check_start_comment:
    cmp parser_index, 0
    jne read_char_loop
    cmp val_acc, 0
    jne read_char_loop

skip_comment_line:
    mov eax, handle_lecturas
    mov edx, offset char_temp
    mov ecx, 1
    call ReadFromFile
    jc error_parser
    or eax, eax
    jz check_eof_comment
    
    mov al, char_temp
    cmp al, 13
    je end_comment_line
    cmp al, 10
    je end_comment_line
    jmp skip_comment_line

check_eof_comment:
    mov eof_flag, 1
    mov eax, 0
    jmp done_parser

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
    mov eax, 1
    jmp done_parser

check_eof_parser:
    cmp parser_index, 0
    jne guardar_ultimo
    mov eof_flag, 1
    mov eax, 0
    jmp done_parser

guardar_ultimo:
    call GuardarValor
    mov eax, 1
    jmp done_parser

error_parser:
    mov eax, -1

done_parser:
    pop edx
    pop ecx
    pop ebx
    ret
ParserMuestra ENDP

; Procedimiento Auxiliar: GuardarValor
; Asigna el valor del acumulador a la variable correspondiente del paciente
GuardarValor PROC
    push eax
    mov eax, val_acc
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
    jmp done_asig
asig_rc:
    mov ritmo_cardiaco, eax
    jmp done_asig
asig_sis:
    mov presion_sistolica, eax
    jmp done_asig
asig_dia:
    mov presion_diastolica, eax
    jmp done_asig
asig_spo2:
    mov oxigenacion, eax
    jmp done_asig
asig_temp:
    mov temperatura, eax
done_asig:
    pop eax
    ret
GuardarValor ENDP

; Procedimiento: EscribirBitacora
; Guarda un registro con los datos del paciente en bitacora.txt
EscribirBitacora PROC
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi

    ; Posicionarse al final del archivo para anexar (Seek End)
    INVOKE SetFilePointer,
        handle_bitacora,
        0,              ; Desplazamiento bajo
        0,              ; Desplazamiento alto (NULL)
        2               ; FILE_END

    ; Rellenar ID con espacios
    mov ecx, 4
    lea edi, l_id
fill_sp_log:
    mov byte ptr [edi], ' '
    inc edi
    loop fill_sp_log

    lea esi, paciente_id
    lea edi, l_id
    mov ecx, paciente_id_len
    or ecx, ecx
    jz copiar_log_id_end
    cmp ecx, 4
    jbe copiar_log_id_loop
    mov ecx, 4
copiar_log_id_loop:
    mov al, [esi]
    mov [edi], al
    inc esi
    inc edi
    loop copiar_log_id_loop
copiar_log_id_end:

    mov eax, ritmo_cardiaco
    lea edi, l_fc
    call IntToString3

    mov eax, pam
    lea edi, l_pam
    call IntToString3

    mov eax, oxigenacion
    lea edi, l_spo2
    call IntToString3

    mov eax, temperatura
    lea edi, l_tempc
    call IntToString2

    mov eax, temp_f
    lea edi, l_tempf
    call IntToString3

    mov eax, estado_salud
    cmp eax, 0
    je log_normal
    cmp eax, 1
    je log_alerta
    lea esi, str_critico
    jmp copiar_estado_log
log_normal:
    lea esi, str_normal
    jmp copiar_estado_log
log_alerta:
    lea esi, str_alerta

copiar_estado_log:
    lea edi, l_est
    mov ecx, 8
copiar_est_l_loop:
    mov al, [esi]
    mov [edi], al
    inc esi
    inc edi
    loop copiar_est_l_loop

    ; Guardar reporte en el archivo
    mov eax, handle_bitacora
    mov edx, offset log_line
    mov ecx, log_line_len
    call WriteToFile
    
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
EscribirBitacora ENDP
