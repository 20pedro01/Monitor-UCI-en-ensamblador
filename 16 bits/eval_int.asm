; =============================================================================
; ARCHIVO DE EVALUACIÓN E INTERFAZ: eval_int.asm
; INTEGRANTE: Brenda Argelia Chan Xooc
; PROYECTO FINAL: MONITOR DE PACIENTE UCI
; =============================================================================

; Procedimiento: EvaluarEstado
; Evalúa los signos vitales del paciente y determina su estado clínico:
; 0=Normal, 1=Alerta, 2=Critico
EvaluarEstado PROC
    mov estado_salud, 0

    mov ax, oxigenacion
    cmp ax, 90
    jl marcar_critico
    cmp ax, 95
    jl marcar_alerta

    mov ax, ritmo_cardiaco
    cmp ax, 120
    jg marcar_critico
    cmp ax, 50
    jl marcar_critico
    
    cmp ax, 100
    jg marcar_alerta
    cmp ax, 60
    jl marcar_alerta

    mov ax, temperatura
    cmp ax, 39
    jge marcar_critico
    cmp ax, 38
    jge marcar_alerta
    ret

marcar_critico:
    mov estado_salud, 2
    ret

marcar_alerta:
    mov ax, estado_salud
    cmp ax, 2
    je fin_eval
    mov estado_salud, 1
fin_eval:
    ret
EvaluarEstado ENDP

; Procedimiento: DibujarCorazon
; Dibuja el corazón ♥ (ASCII 3) animado, parpadeando y con color variable según el estado
DibujarCorazon PROC
    push ax
    push bx
    push cx
    push dx

    ; Alternar el estado del pulso (0 o 1)
    xor heart_state, 1
    
    ; Seleccionar color según el estado de salud
    mov ax, estado_salud
    cmp ax, 0
    je cor_normal
    cmp ax, 1
    je cor_alerta
    
    ; Critico: Rojo (0Ch si heart_state=1, 04h si heart_state=0)
    mov bl, 0Ch
    cmp heart_state, 1
    je cor_print
    mov bl, 04h
    jmp cor_print
    
cor_normal:
    ; Normal: Verde (0Ah si heart_state=1, 02h si heart_state=0)
    mov bl, 0Ah
    cmp heart_state, 1
    je cor_print
    mov bl, 02h
    jmp cor_print
    
cor_alerta:
    ; Alerta: Amarillo (0Eh si heart_state=1, 06h si heart_state=0)
    mov bl, 0Eh
    cmp heart_state, 1
    je cor_print
    mov bl, 06h
    
cor_print:
    ; Escribir el carácter ASCII 3 (Corazón) con el color seleccionado
    push bx
    mov ah, 03h         ; Obtener posición cursor
    mov bh, 00h
    int 10h
    pop bx
    
    mov ah, 09h
    mov al, 3           ; Código ASCII de '♥'
    mov bh, 00h
    mov cx, 1
    int 10h
    
    ; Avanzar cursor
    inc dl
    mov ah, 02h
    mov bh, 00h
    int 10h

    pop dx
    pop cx
    pop bx
    pop ax
    ret
DibujarCorazon ENDP

; =============================================================================
; PROCEDIMIENTOS DE INTERFAZ Y RENDERIZADO (Brenda)
; =============================================================================

; Helper para imprimir con color (escribe carácter por carácter con atributo)
ImprimirConColor PROC
    push ax
    push bx
    push cx
    push dx
    push si
    
    mov si, dx          ; SI apunta a la cadena
char_loop:
    mov al, [si]
    cmp al, '$'
    je done_print
    
    cmp al, 13
    je handle_newline
    cmp al, 10
    je handle_newline
    
    ; Obtener posición actual del cursor (Fila en DH, Columna en DL)
    push bx             ; Guardar color
    mov ah, 03h         ; Leer posición
    mov bh, 00h
    int 10h
    pop bx              ; Restaurar color
    
    ; Escribir carácter con atributo en la posición actual
    mov ah, 09h
    mov al, [si]
    mov bh, 00h
    mov cx, 1
    int 10h
    
    ; Avanzar cursor
    inc dl
    mov ah, 02h
    mov bh, 00h
    int 10h
    
    inc si
    jmp char_loop
    
handle_newline:
    mov ah, 02h
    mov dl, al
    int 21h             ; Dejar que DOS procese el salto de línea
    inc si
    jmp char_loop

done_print:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
ImprimirConColor ENDP

; Procedimiento: DibujarConsola
; Renderiza la pantalla principal del monitor de signos vitales
DibujarConsola PROC
    LIMPIAR_PANTALLA
    MOSTRAR_COLOR msg_separador, 09h     ; Azul claro
    MOSTRAR_CADENA newline
    
    ; Mostrar ID del paciente y Número de Cama (Datos 1 y 7)
    MOSTRAR_COLOR msg_paciente, 0Fh
    MOSTRAR_VAR_COLOR paciente_id, paciente_id_len, 0Eh
    MOSTRAR_COLOR msg_lbl_cama, 0Fh
    MOSTRAR_VAR_COLOR cama, cama_len, 0Eh
    MOSTRAR_CADENA newline

    ; Mostrar Nombre (Dato 2)
    MOSTRAR_COLOR msg_nombre_lbl, 0Fh
    MOSTRAR_VAR_COLOR nombre_paciente, nombre_paciente_len, 0Eh
    MOSTRAR_CADENA newline

    ; Mostrar Género y Edad (Datos 4 y 3)
    MOSTRAR_COLOR msg_lbl_genero, 0Fh
    MOSTRAR_VAR_COLOR genero, genero_len, 0Eh
    MOSTRAR_COLOR msg_lbl_edad, 0Fh
    MOSTRAR_VAR_COLOR edad, edad_len, 0Eh
    MOSTRAR_CADENA newline

    ; Mostrar Peso y Estatura (Datos 5 y 6)
    MOSTRAR_COLOR msg_lbl_peso, 0Fh
    MOSTRAR_VAR_COLOR peso, peso_len, 0Eh
    MOSTRAR_COLOR msg_lbl_estatura, 0Fh
    MOSTRAR_VAR_COLOR estatura, estatura_len, 0Eh
    MOSTRAR_COLOR msg_unit_estatura, 07h
    MOSTRAR_CADENA newline

    ; Mostrar Médico Responsable (Dato 8)
    MOSTRAR_COLOR msg_lbl_medico, 0Fh
    MOSTRAR_VAR_COLOR medico, medico_len, 0Eh
    MOSTRAR_CADENA newline
    
    MOSTRAR_COLOR msg_separador, 09h     ; Azul claro
    MOSTRAR_CADENA newline
    MOSTRAR_COLOR msg_sec_datos, 0Bh     ; Celeste
    MOSTRAR_CADENA newline

    ; Mostrar Ritmo Cardíaco
    MOSTRAR_COLOR msg_lbl_fc, 0Fh        ; Blanco
    mov ax, ritmo_cardiaco
    lea di, str_num3
    call IntToString3
    MOSTRAR_COLOR str_num3, 0Bh          ; Celeste para el número
    MOSTRAR_COLOR msg_unit_fc, 07h       ; Gris para la unidad
    MOSTRAR_COLOR space_str, 07h         ; Separador
    call DibujarCorazon                  ; Corazón pulsante de color
    MOSTRAR_CADENA newline

    ; Mostrar Presión Arterial (SIS/DIA)
    MOSTRAR_COLOR msg_lbl_presion, 0Fh
    mov ax, presion_sistolica
    lea di, str_num3
    call IntToString3
    MOSTRAR_COLOR str_num3, 0Bh
    MOSTRAR_COLOR msg_slash, 07h
    
    mov ax, presion_diastolica
    lea di, str_num3
    call IntToString3
    MOSTRAR_COLOR str_num3, 0Bh
    MOSTRAR_COLOR msg_unit_presion, 07h
    MOSTRAR_CADENA newline

    ; Mostrar PAM
    MOSTRAR_COLOR msg_lbl_pam, 0Fh
    mov ax, pam
    lea di, str_num3
    call IntToString3
    MOSTRAR_COLOR str_num3, 0Bh
    MOSTRAR_COLOR msg_unit_presion, 07h
    MOSTRAR_CADENA newline

    ; Mostrar SpO2
    MOSTRAR_COLOR msg_lbl_spo2, 0Fh
    mov ax, oxigenacion
    lea di, str_num3
    call IntToString3
    MOSTRAR_COLOR str_num3, 0Bh
    MOSTRAR_COLOR msg_unit_spo2, 07h
    MOSTRAR_CADENA newline

    ; Mostrar Temperatura
    MOSTRAR_COLOR msg_lbl_temp, 0Fh
    mov ax, temperatura
    lea di, str_num2
    call IntToString2
    MOSTRAR_COLOR str_num2, 0Bh
    MOSTRAR_COLOR msg_unit_temp, 07h
    
    mov ax, temp_f
    lea di, str_num3
    call IntToString3
    MOSTRAR_COLOR str_num3, 0Bh
    MOSTRAR_COLOR msg_unit_temp_f, 07h
    MOSTRAR_CADENA newline

    MOSTRAR_COLOR msg_lbl_estado, 09h    ; Azul claro
    MOSTRAR_CADENA newline
    MOSTRAR_COLOR msg_lbl_estado2, 0Fh   ; Blanco

    ; Mostrar diagnóstico clínico con colores y efectos
    mov ax, estado_salud
    cmp ax, 0
    je print_normal
    cmp ax, 1
    je print_alerta
    MOSTRAR_COLOR msg_txt_critico, 8Ch   ; Parpadeo rojo (0Ch + bit 7)
    jmp print_estado_end
print_normal:
    MOSTRAR_COLOR msg_txt_normal, 0Ah    ; Verde claro
    jmp print_estado_end
print_alerta:
    MOSTRAR_COLOR msg_txt_alerta, 0Eh    ; Amarillo

print_estado_end:
    MOSTRAR_CADENA newline
    MOSTRAR_COLOR msg_separador, 09h     ; Azul claro
    MOSTRAR_CADENA newline
    ret
DibujarConsola ENDP

; Formatea enteros a una cadena de 3 caracteres numéricos
IntToString3 PROC
    push ax
    push bx
    push cx
    push dx
    
    mov bx, 10
    xor dx, dx
    div bx             ; AX = Cociente, DX = Residuo (unidades)
    add dl, '0'
    mov [di+2], dl     ; Unidades

    xor dx, dx
    div bx             ; AX = Cociente, DX = Decenas
    add dl, '0'
    mov [di+1], dl     ; Decenas

    add al, '0'
    mov [di], al       ; Centenas
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret
IntToString3 ENDP
