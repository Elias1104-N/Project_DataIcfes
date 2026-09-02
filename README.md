# Integración de datos ICFES — Panel longitudinal Saber 11 → Saber Pro (2014–2025)

Proyecto 1 · Estadística Industrial · Ingeniería Industrial · Universidad del Magdalena · Semestre 2026-II

## 1. Descripción

Este repositorio contiene el flujo reproducible que construye una base de datos consolidada a nivel de
estudiante, vinculando los resultados del examen **Saber 11** (educación media) con los del **Saber Pro**
(final de pregrado) para todos los estudiantes que sea posible emparejar dentro de la ventana 2014–2025.

El resultado es un **panel multi-cohorte** (no una sola promoción de graduandos): cada registro representa
un par Saber 11 → Saber Pro observado, con el rezago (tiempo transcurrido) entre ambas pruebas como variable
derivada.

## 2. Equipo

- María Mónica Murillo Rincón
- Elias José Parra Royero

## 3. Estructura del repositorio

```
.
├── run_all.R                          # Script maestro: ejecuta todo el pipeline de punta a punta
├── config.yml                         # Único lugar donde se cambian años, rutas y umbrales
├── README.md                          # Este archivo
├── scripts/
│   ├── 00_setup.R                     # Carga de librerías y de config.yml
│   ├── 01_diccionarios_homologacion.R # Lectura de diccionarios de homologación (Excel externos)
│   ├── 02_funciones_lectura.R         # Funciones leer_saber11() / leer_saberpro()
│   ├── 03_cargar_datos.R              # Lectura selectiva de los .txt crudos por año/periodo
│   ├── 04_limpieza.R                  # Tipificación, estandarización y reglas de calidad (Fase 4)
│   ├── 05_cruce.R                     # Cruce Saber11–SaberPro con llave estándar/reforzada (Fase 3)
│   ├── 06_validacion.R                # Métricas de calidad, matriz de cobertura, rezago (Fase 5)
│   └── 07_diccionario_final.R         # Genera el diccionario de la base final automáticamente
├── logs/
│   ├── utilidades_log.R               # Funciones iniciar_log() / escribir_log()
│   └── ejecucion.log                  # (generado en cada corrida)
├── data/
│   ├── raw/                           # EXCLUIDO del repositorio (ver .gitignore) — microdatos originales
│   │   ├── Saber11/                   # Examen_Saber_11_AAAAP.txt
│   │   └── SaberPro/                  # Examen_Saber_Pro_Genericas_AAAA.txt
│   ├── metadata/
│   │   ├── diccionario_saber11.xlsx       # Tabla de homologación de variables Saber 11
│   │   ├── diccionario_saberpro.xlsx      # Tabla de homologación de variables Saber Pro
│   │   ├── divipola.xlsx                  # Codificación oficial DANE (depto/municipio)
│   │   └── diccionario_base_final.xlsx    # (generado/actualizado en cada corrida)
│   └── processed/                     # Checkpoints .rds intermedios (generado; no versionar)
├── output/
│   └── tables/
│       └── diccionario_base_final.csv # (generado)
└── docs/
    ├── bitacora_ia.md                 # Bitácora de uso de IA (Entregable 7)
    ├── registro_decisiones.md         # Registro cronológico de decisiones metodológicas (Entregable 6)
    └── informe_tecnico.pdf            # Informe técnico (Entregable 3)
```

## 4. Requisitos y entorno

- **R** ≥ 4.2 (verificar versión exacta con `sessionInfo()` antes de la entrega y pegar la salida aquí).
- Paquetes utilizados:

```r
install.packages(c("here", "data.table", "readxl", "writexl", "config"))
```

> Antes de la entrega final, reemplazar esta lista por la salida real de `sessionInfo()` ejecutada en el
> entorno donde corrió el pipeline por última vez (requisito de reproducibilidad, sección 4.1 del enunciado).

No hay procedimientos con componente aleatorio en el pipeline actual; si se incorpora alguno (p. ej. muestreo
para pruebas), debe fijarse semilla con `set.seed()` y documentarse aquí.

## 5. Obtención de los datos originales

Los microdatos **no se incluyen en este repositorio** (ver sección 8). Para reproducir la base:

1. Registrarse en [DataICFES](https://www.icfes.gov.co/investigaciones/data-icfes/) y solicitar acceso a las
   bases de **Saber 11** y **Saber Pro (Genéricas)**.
2. Descargar los archivos `.txt` de los periodos requeridos y ubicarlos así:
   - Saber 11 → `data/raw/Saber11/Examen_Saber_11_AAAAP.txt` (código de 5 dígitos, ej. `Examen_Saber_11_20141.txt`)
   - Saber Pro → `data/raw/SaberPro/Examen_Saber_Pro_Genericas_AAAA.txt` (año de 4 dígitos, ej.
     `Examen_Saber_Pro_Genericas_2018.txt`)
3. Ubicar en `data/metadata/` los diccionarios de homologación (`diccionario_saber11.xlsx`,
   `diccionario_saberpro.xlsx`) y la tabla DIVIPOLA del DANE (`divipola.xlsx`).

## 6. Configuración (`config.yml`)

Es el **único** lugar que debe modificarse para actualizar la base con un año nuevo. No requiere tocar
ningún script en `scripts/`:

| Parámetro | Qué controla |
|---|---|
| `ventana_saber11` / `ventana_saberpro` | Rango de periodos/años a incluir en la carga |
| `escala_saberpro.periodo_cambio` | Periodo a partir del cual el puntaje de Saber Pro es comparable (cambio de escala 2016) |
| `validacion_rangos` | Rangos válidos de puntaje global; el pipeline se detiene si encuentra valores fuera de rango |
| `llave_cruce` | Definición de la llave estándar y la llave reforzada usadas en el cruce |
| `paths` | Rutas de datos crudos, metadatos y log |

**Para incorporar un año nuevo (ej. Saber Pro 2026):**
1. Copiar el `.txt` nuevo a `data/raw/SaberPro/` (o `Saber11/`).
2. Actualizar `ventana_saberpro.anio_hasta` (o `ventana_saber11.periodo_hasta`) en `config.yml`.
3. Volver a ejecutar `run_all.R`.

## 7. Ejecución

Desde una sesión de R nueva, con el directorio de trabajo en la raíz del proyecto:

```r
source(here::here("run_all.R"))
```

o desde terminal:

```bash
Rscript run_all.R
```

El script maestro ejecuta en orden: setup → diccionarios → funciones de lectura → carga → limpieza → cruce
→ validación → diccionario final, y deja registro de cada etapa en `logs/ejecucion.log`.

### Checkpoints (`data/processed/*.rds`)

Para acelerar la iteración, `run_all.R` guarda `saber11_completo` y `saberpro_completo` ya limpios en
`data/processed/`. Si esos archivos existen, la siguiente corrida **omite** carga y limpieza y los reutiliza.

```r
FORZAR_RECARGA_COMPLETA <- FALSE   # en run_all.R
```

⚠️ **Importante:** si se modifica `03_cargar_datos.R` o `04_limpieza.R`, hay que poner
`FORZAR_RECARGA_COMPLETA <- TRUE` al menos una vez (o borrar los `.rds` de `data/processed/`) para que el
checkpoint no quede desincronizado con el código nuevo.

## 8. Salidas generadas

- `base_cruzada` (objeto en memoria al terminar `run_all.R`) → exportar a `.csv` como Entregable 1
  (UTF-8, nombres de variable en minúscula sin tildes ni espacios, punto como separador decimal).
- `output/tables/diccionario_base_final.csv` y `data/metadata/diccionario_base_final.xlsx` → Entregable 4.
- `logs/ejecucion.log` → registro de ejecución (archivos leídos, registros por etapa, advertencias).

## 9. Datos y términos de uso

La carpeta `data/raw/` está excluida del repositorio (`.gitignore`). Los microdatos del ICFES se usan
exclusivamente con fines académicos, no se redistribuyen y no se intenta reidentificar a ningún individuo.
Todos los resultados reportados en el informe técnico son agregados, nunca a nivel de registro individual.

## 10. Prueba de reproducibilidad

Antes de la entrega, este repositorio fue ejecutado de punta a punta en una sesión limpia por un equipo
distinto al autor, siguiendo únicamente este README. [Completar con fecha y equipo que hizo la prueba.]

## 11. Licencia 

Uso académico — Estadística Industrial, Universidad del Magdalena.
