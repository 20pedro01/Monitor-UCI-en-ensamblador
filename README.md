# Monitor de paciente UCI - sistema de signos vitales

<img src="MD/Reporte/Logo.png" alt="Logo del monitor" width="100%">

Este proyecto consiste en un **monitor de paciente en Unidad de Cuidados Intensivos (UCI)**, desarrollado en lenguaje ensamblador x86. El sistema simula la captura de datos generales del paciente, lee muestras de sensores clínicos desde un archivo físico (`lecturas.txt`), procesa variables médicas complejas (como la Presión Arterial Media y la conversión de Temperatura de Celsius a Fahrenheit), diagnostica el estado clínico en tiempo real, activa alarmas sonoras/visuales en caso crítico y guarda un registro persistente en una bitácora de historial (`bitacora.txt`).

El repositorio contiene dos versiones funcionales estructuradas de forma modular en **4 archivos de código ensamblador (.asm)**:
1. **Versión de 16 bits**: Orientada para ejecutarse en entornos DOS puros o emulados mediante **DOSBox**.
2. **Versión de 32 bits**: Optimizada para el modelo plano (`flat, stdcall`) mediante el ensamblador **JWasm/MASM** utilizando la biblioteca **Irvine32**.

---

## Estructura del proyecto

Tanto la carpeta `16 bits` como `32 bits` cuentan con la misma distribución lógica y modular física de archivos:

*   **`mon16.asm` / `mon32.asm`**: Archivo principal. Segmentos de datos, bucles de validaciones de entrada del teclado, flujo del ciclo principal y procedimientos auxiliares de validación.
*   **`macros.asm` / `macs32.asm`**: Contiene macros útiles (impresión con color, copia y captura de búferes, retardo de tiempo, alertas sonoras de alarma) y el procedimiento de telemetría COM1 (`SimularComunicacion`).
    *   *Nota: En la versión de 32 bits, el archivo se renombró a `macs32.asm` para evitar colisión de nombres con la biblioteca nativa `Macros.inc` de Irvine32.*
*   **`calc_his.asm`**: Procedimientos aritméticos (`CalcularPAM`, `CalcularFahrenheit`), parser de lecturas clínicas (saltando comentarios de cabecera `;` o `#`) y persistencia de archivos (`CargarHistorial`, `EscribirBitacora`).
*   **`eval_int.asm`**: Procedimientos de diagnóstico clínico (`EvaluarEstado`), renderizado de interfaz de pantalla completa (`DibujarConsola`) y la animación del corazón parpadeante (`DibujarCorazon`).

---

## Capturas de pantalla de los escenarios clínicos

A continuación se muestran los tres escenarios de visualización en pantalla del monitor de signos vitales según el diagnóstico clínico evaluado en tiempo real:

### Escenario 1 - estado clínico normal (estable)
Muestra signos vitales estables dentro del rango esperado. El corazón indicador parpadea en color verde claro.
![Escenario 1 - estado clínico normal](IMG/Escenario%201.png)

### Escenario 2 - estado clínico de alerta (bajo observación)
Se presenta cuando alguno de los signos vitales se desvía levemente de los rangos normales (como fiebre leve o taquicardia moderada). El corazón indicador parpadea en color amarillo.
![Escenario 2 - estado clínico de alerta](IMG/Escenario%202.png)

### Escenario 3 - estado clínico crítico (alarma activada)
Activado por valores críticos (hipoxia severa, bradicardia o fiebre alta). El corazón indicador parpadea en color rojo, el texto del diagnóstico parpadea en pantalla y suena una alarma física intermitente.
![Escenario 3 - estado clínico crítico](IMG/Escenario%203.png)

---

## Guía de compilación y ejecución

### 1. Versión de 16 bits (DOSBox)

Para ejecutar la versión de 16 bits desde cero usando la consola de DOSBox, sigue estos pasos:

1.  **Configurar el teclado en español** (para poder escribir `:` y `\` fácilmente):
    ```cmd
    keyb sp
    ```
2.  **Montar la carpeta del compilador MASM** (por ejemplo, `masm611` en tu disco duro) como la unidad `C:`:
    ```cmd
    mount c "/Ruta/A/Tu/Carpeta/masm611"
    ```
3.  **Montar la carpeta de este proyecto** como la unidad `D:`:
    ```cmd
    mount d "/Ruta/A/Tu/Carpeta/Monitor UCI"
    ```
4.  **Configurar el PATH** en DOSBox para incluir los ejecutables del compilador:
    ```cmd
    set PATH=%PATH%;C:\BIN;C:\
    ```
5.  **Cambiar a la unidad `D:` e ingresar a la carpeta de 16 bits**:
    ```cmd
    d:
    cd "16 bits"
    ```
6.  **Compilar y enlazar el programa** en un solo paso usando `ml`:
    ```cmd
    ml mon16.asm
    ```
    *(Alternativamente, puedes usar el ensamblador clásico: `masm mon16.asm;` seguido de `link mon16.obj;`)*
7.  **Ejecutar el monitor**:
    ```cmd
    mon16.exe
    ```
8.  **Verificar la bitácora física escrita**:
    ```cmd
    type bitacora.txt
    ```

---

### 2. Versión de 32 bits (VS Code / Antigravity con MASM Runner)

La versión de 32 bits está diseñada para compilarse en entornos modernos a través de la extensión **MASM/TASM Runner** en VS Code o Antigravity IDE. Debido a que esta extensión corre dentro de un contenedor o visor virtual en sandbox (Webview), sigue estas instrucciones cuidadosamente:

1.  **Abrir el proyecto correctamente**:
    En tu IDE, abre directamente la carpeta **`32 bits`** como tu espacio de trabajo activo (*File -> Open Folder...*). Esto asegura que el emulador monte esta carpeta como la unidad raíz `D:\` del entorno virtual.
2.  **Transferir archivos de dependencias al emulador (CRÍTICO)**:
    Dado que el proyecto está dividido modularmente en 4 archivos, la extensión no podrá resolver los `include` si no tiene los archivos físicamente cargados en el disco virtual de la consola.
    *   Haz clic derecho sobre **`macs32.asm`** en la barra lateral del explorador y selecciona **"Send files to MASM Runner Webview"**.
    *   Repite el mismo paso para **`calc_his.asm`**.
    *   Repite el mismo paso para **`eval_int.asm`**.
    *   Repite el mismo paso para **`lecturas.txt`**.
3.  **Compilar y correr**:
    *   Abre el archivo principal **`mon32.asm`**.
    *   Presiona el botón de play/run de MASM Runner (o presiona la tecla de compilar configurada en tu IDE). El compilador `JWasm.exe` compilará y ejecutará el monitor automáticamente.
4.  **Limpiar historial de la bitácora virtual**:
    El emulador guarda de forma persistente los archivos creados en tiempo de ejecución en su caché local virtual. Si deseas vaciar la bitácora para que inicie desde `0 registros detectados`, escribe en la línea de comando del emulador:
    ```cmd
    del bitacora.txt
    ```
5.  **Extraer la bitácora escrita a tu disco real (macOS/Windows)**:
    Debido a que el emulador web no tiene permisos directos para escribir archivos de texto `.txt` a tu disco duro físico, el archivo local `BITACORA.TXT` permanecerá vacío. Para extraer el reporte completo:
    *   En la consola virtual de Wine, ejecuta:
        ```cmd
        copy bitacora.txt bitacora.obj
        ```
    *   **Vuelve a compilar/correr `mon32.asm`**. Al terminar de compilar, el emulador detectará el archivo de extensión `.obj` como un artefacto de compilación y lo exportará físicamente a la carpeta de tu Mac.
    *   Abre o renombra el archivo `bitacora.obj` resultante en tu Mac para acceder a los registros.

*Nota: Si ejecutas el compilado `mon32.exe` en un sistema operativo Windows real o en un emulador nativo con permisos de disco directo, el programa escribirá en `BITACORA.TXT` físicamente de forma automática.*

---

## Autores - asignatura: lenguajes de interfaz (grupo 6C)
*   **Cauich Pat Pedro Antonio**
*   **Chan Xooc Brenda Argelia**
*   **Corona Noh Gabriel Danneshe**
*   **Pat Canche Karla Cristina**
