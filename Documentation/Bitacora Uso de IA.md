# Bitácora de uso de Inteligencia Artificial

**Proyecto:** Integración de datos ICFES — Panel longitudinal Saber 11 → Saber Pro (2014–2025)
**Curso:** Estadística Industrial · Ingeniería Industrial · Universidad del Magdalena · 2026-II
**Entregable 7:** `docs/bitacora_ia.md`
**Herramienta utilizada:** Claude (Anthropic)
**Periodo cubierto:** 17 – 30 de agosto de 2026

---

## Nota metodológica

Esta bitácora registra cada interacción relevante con IA durante el desarrollo del pipeline
(`scripts/01_diccionarios_homologacion.R` a `08_exportar.R`). Se documenta con qué criterio se
usó la IA: qué se le preguntó, qué respondió, cómo se verificó esa respuesta contra el dato real
o contra la lógica del proyecto, y si se aceptó, se corrigió o se descartó. El equipo es
responsable de todo lo entregado — la IA propuso enfoques y código; la verificación y la decisión
final fueron del equipo en cada caso.

---

### 1. Lunes 17 de agosto — Fase 2: diccionarios de homologación (`01_diccionarios_homologacion.R`)

**Objetivo:** decidir cómo estructurar la lectura de los diccionarios de homologación de
variables para que agregar un año nuevo, o una variable que cambia de nombre entre periodos, no
implique tocar código.

**Prompt:** "Tengo los diccionarios de equivalencia de nombres de variables Saber 11 y Saber Pro
escritos como `data.table()` dentro del script. Cada vez que cambia el nombre de una variable de
un año a otro tengo que editar el código directamente. ¿Cómo lo estructuro mejor para no tener que
tocar el script cada vez?"

**Respuesta obtenida:** mover los diccionarios a archivos Excel externos y editables en
`data/metadata/` (`diccionario_saber11.xlsx`, `diccionario_saberpro.xlsx`), leerlos con
`read_excel()`, y agregar un `stopifnot()` que valide que existan las columnas
`nombre_final`, `nombre_en_archivo`, `periodo_desde`, `periodo_hasta` y que el diccionario no esté
vacío, para que un Excel mal formado detenga la ejecución en vez de fallar en silencio más
adelante.

**Verificación aplicada:** se probó el script cargando un diccionario con una columna renombrada a
propósito, confirmando que `stopifnot()` detiene la ejecución con el mensaje de error esperado en
vez de continuar con datos incompletos.

**Resultado:** Aceptado.

---

### 2. Martes 18 de agosto — Fase 2: funciones de lectura (`02_funciones_lectura.R`)

**Objetivo:** que `leer_saber11()` / `leer_saberpro()` no fallen cuando un año no tiene alguna de
las variables del diccionario (p. ej. `percentil_global` no existía en 2014-1), y que la ausencia
quede registrada en algún lado en vez de perderse en la consola.

**Prompt:** "Cuando un archivo de un año no tiene una de las columnas del diccionario, el script se
cae. Necesito que en cambio la rellene con NA y que quede anotado en algún log, no solo impreso en
pantalla mientras corro."

**Respuesta obtenida:** separar las variables de la especificación en `disponibles` vs
`faltantes` comparando contra las columnas reales del `.txt` (leídas con `nrows = 0`), crear las
columnas faltantes explícitamente como `NA`, y enviar el aviso a un sistema de log centralizado
(`escribir_log()`) en vez de `message()`/`print()`.

**Verificación aplicada:** se ejecutó sobre `Examen_Saber_11_20141.txt`, que efectivamente carece
de `punt_global`, y se confirmó en `ejecucion_log.txt` que quedó el `WARNING` correspondiente y que
el pipeline continuó con la columna en NA en vez de detenerse.

**Resultado:** Aceptado.

---

### 3. Jueves 20 de agosto — Fase 4: fechas de nacimiento sospechosas (`04_limpieza.R`)

**Objetivo:** decidir qué hacer con valores de `estu_fechanacimiento` sospechosos
(`1900-01-01`, `1980-01-31`) sin anular fechas que podrían ser reales.

**Prompt:** "Tengo un montón de `estu_fechanacimiento` en 1900-01-01 y también un pico raro en
1980-01-31. ¿Las trato igual? ¿Cómo verifico que de verdad son errores del sistema y no
nacimientos reales antes de anularlas?"

**Respuesta obtenida:** `1900-01-01` es descartable de forma directa por imposibilidad
demográfica (edad >100 años), pero `1980-01-31` requiere evidencia empírica antes de tratarla como
valor centinela — comparar su frecuencia contra fechas vecinas para confirmar que es un pico
anómalo y no variación normal. Se advirtió además no confundir esto con el *date heaping*
(fechas día=mes, ej. 09-09) que es un patrón conocido de datos autorreportados y no debía anularse
por el mismo criterio.

**Verificación aplicada:** se calculó la frecuencia de `1980-01-31` contra fechas cercanas
(814 registros vs. 55–90 en fechas vecinas), confirmando el pico de ~10x; se revisó aparte que el
patrón día=mes no mostraba ese mismo salto abrupto.

**Resultado:** Aceptado parcialmente — se anularon `1900-01-01` y `1980-01-31` como NA; se
descartó tratar el *date heaping* general como error, y quedó documentado como limitación de
precisión del dato, no como error de captura.

---

### 4. Viernes 21 de agosto — Fase 4: cambio de escala Saber Pro 2016

**Objetivo:** verificar si el salto en los puntajes de Saber Pro entre 2015 y 2016 correspondía a
un cambio real de escala del ICFES o a un error de lectura, y decidir cómo marcarlo sin perder los
datos anteriores.

**Prompt:** "Los puntajes de Saber Pro antes de 2016 se ven en una escala totalmente distinta a los
de después. ¿Esto es un cambio de escala real del ICFES o es un error mío de lectura? Y si es real,
¿los descarto o los marco de alguna forma para poder decidir después si los uso?"

**Respuesta obtenida:** no descartar los datos antiguos sino agregar una bandera
`puntaje_escala_comparable` (`periodo >= periodo_cambio`, tomado de `config.yml`) para que la
decisión de incluirlos o no quede en manos del análisis posterior, no impuesta en la limpieza;
sugirió además buscar la resolución oficial del ICFES que confirmara el cambio de escala en vez de
asumirlo solo por el salto en los datos.

**Verificación aplicada:** se confirmó la Resolución 455 de 2016 del ICFES sobre el cambio de
escala; se verificó empíricamente el salto abrupto en mínimo/máximo/promedio en el periodo 20162 y
se descartó la existencia de una columna recalibrada alternativa en años anteriores.

**Resultado:** Aceptado.

---

### 5. Lunes 24 de agosto — Fase 4: pérdida anómala en deduplicación (2016-2 y 2023-2024)

**Objetivo:** entender por qué la deduplicación estaba perdiendo entre 65% y 84% de los registros
justo en 2023-2024 y en 2016-2, muy por encima del resto de la serie.

**Prompt:** "Después de deduplicar, estoy perdiendo muchísimos más registros en 2023-2024 y en
2016-2 que en el resto de los años. No tiene sentido que justo esos periodos pierdan tanto. ¿Qué
puede estar pasando?"

**Respuesta obtenida:** `data.table` trata `NA == NA` como "iguales" al agrupar con `by =`, así
que estudiantes distintos con colegio o municipio de residencia faltantes se estaban fusionando
como si fueran el mismo registro — precisamente en los periodos con más NA en esas columnas.
Se propuso agregar las variables de refuerzo (`estu_mcpio_presentacion`, `estu_inst_municipio`) al
agrupamiento de deduplicación, el mismo refuerzo ya usado para la llave de vinculación.

**Verificación aplicada:** se re-ejecutó la deduplicación con las variables agregadas y se
comparó la caída de 2024 antes/después (65–84% → 13–29%), quedando en línea con el resto de la
serie.

**Resultado:** Aceptado.

---

### 6. Martes 25 de agosto — Fase 5: la llave reforzada (2023-2024) no capturaba registros (`05_cruce.R`)

**Objetivo:** resolver por qué la partición de Saber Pro por llave reforzada, configurada para
2023-2024 en `config.yml`, daba cero registros al correr el cruce.

**Prompt:** "Configuré en `config.yml` que la llave reforzada aplique para 2023 y 2024, pero al
correr el cruce me da cero registros en esa partición. ¿Dónde está el error?"

**Respuesta obtenida:** la columna `periodo` en Saber Pro no es un año de 4 dígitos como se había
asumido, sino un código AAAAS de 5 dígitos igual que en Saber 11 (ej. `20233`, no `2023`), por lo
que comparar `periodo` directamente contra `periodo_ref_desde`/`periodo_ref_hasta` nunca coincidía.
Se propuso crear `anio_saberpro <- periodo %/% 10` en la limpieza y particionar sobre esa variable
en vez de sobre el periodo crudo.

**Verificación aplicada:** se revisó una muestra de valores crudos de la columna `periodo` en el
`.txt` de Saber Pro 2023, confirmando el formato AAAAS. Tras el cambio, `ejecucion_log.txt` mostró
la partición con registros reales en ambas llaves (2,273,459 estándar / 459,867 reforzada).

**Resultado:** Aceptado.

---

### 7. Miércoles 26 de agosto — Fase 5: umbral de rezago plausible (`06_validacion.R`)

**Objetivo:** definir un umbral defendible para marcar como implausible un rezago (años entre
Saber 11 y Saber Pro) negativo o excesivamente largo, sin inventar un número fijo.

**Prompt:** "Necesito marcar los casos de rezago que no tengan sentido (negativos o
absurdamente largos), pero no quiero poner un número de años fijo porque no tengo cómo
justificarlo en el informe. ¿Cómo lo calculo de forma que se pueda defender con los datos?"

**Respuesta obtenida:** en vez de fijar un número externo, calcular el percentil 99 de la
distribución real de rezagos no negativos de la propia base como umbral superior, de forma que el
corte se apoye en la forma real de los datos de este proyecto y no en una suposición externa.

**Verificación aplicada:** se imprimió la distribución completa de `rezago_anios` por año antes de
fijar el umbral, confirmando que el percentil 99 (9 años) caía en una cola visiblemente separada
del grueso de la distribución.

**Resultado:** Aceptado.

---

### 8. Jueves 27 de agosto — Fase 5: interpretación de la matriz de cobertura

**Objetivo:** dejar explícito en el pipeline por qué las cohortes de Saber 11 más recientes
(2023-2025) y las de Saber Pro más antiguas (2014-2016) muestran vinculación baja, para que no se
lea como una falla del procedimiento de cruce.

**Prompt:** "En la matriz de cobertura, las cohortes de Saber 11 más recientes y las de Saber Pro
más viejas tienen tasas de vinculación bajísimas. Alguien podría pensar que el cruce está mal
hecho. ¿Cómo dejo claro en el código y en el log que esto es esperado y no un error?"

**Respuesta obtenida:** distinguir explícitamente pérdida **estructural** (inherente a la ventana
temporal — un estudiante que presentó Saber 11 en 2025 aún no puede tener Saber Pro) de pérdida
**atribuible al procedimiento** (llave, deduplicación, calidad del dato), calculando qué cohortes
caen en zona de censura derecha o truncamiento izquierda según la ventana definida en
`config.yml`, y dejando esa interpretación registrada en el log.

**Verificación aplicada:** se contrastó la lista de cohortes marcadas como censura/truncamiento
contra la ventana 2014-2025 de `config.yml`, confirmando que coincidían con las cohortes que por
diseño no podían tener pareja todavía.

**Resultado:** Aceptado.

---

### 9. Viernes 28 de agosto — Fase 6: diccionario final automático (`07_diccionario_final.R`)

**Objetivo:** que el diccionario de variables de la base final se actualice con cada corrida del
pipeline (tipo de dato, % de faltantes) sin perder las descripciones ya escritas a mano en
corridas anteriores.

**Prompt:** "Cada vez que corro el pipeline de nuevo quiero que el diccionario de la base final se
actualice con los datos reales, pero sin borrar las descripciones que ya escribí a mano la última
vez. ¿Cómo separo lo automático de lo manual?"

**Respuesta obtenida:** dividir el diccionario en dos partes: hechos técnicos siempre
recalculados sobre la base real (`tipo_dato`, `pct_faltantes`, `n_categorias_unicas`) y contenido
manual (`fuente`, `descripcion`, `limitaciones`) que se lee del Excel existente si ya existe y se
conserva vía `merge`. Se recomendó explícitamente NO traer `tipo_dato` del archivo manual, porque
el calculado sobre la base real es más confiable que lo anotado a mano la última vez. Se agregó un
aviso (sin detener el pipeline) que lista las columnas nuevas sin descripción manual.

**Verificación aplicada:** se corrió el pipeline dos veces seguidas, comprobando que una
descripción escrita a mano en la primera corrida seguía presente en la segunda, y que el
`WARNING` listaba correctamente las columnas nuevas (con sufijos `_saber11`/`_saberpro`) que
todavía no tenían descripción.

**Resultado:** Aceptado.

---

### 10. Sábado 29 de agosto — Fase 6: convención de nombres antes de exportar (`08_exportar.R`)

**Objetivo:** evitar que la base final se exporte con nombres de variable que incumplan la
convención exigida (minúsculas, sin tildes ni espacios), incluso si alguien del equipo agrega una
columna nueva más adelante sin darse cuenta.

**Prompt:** "El enunciado exige que las variables del CSV final vayan en minúscula, sin tildes ni
espacios. Si más adelante alguien del equipo agrega una columna nueva y se le olvida seguir esa
convención, quiero que el script no deje exportar en vez de que el error se cuele hasta la
entrega."

**Respuesta obtenida:** un chequeo *fail-fast* con una expresión regular
(`[A-ZÁÉÍÓÚÑ ]`) sobre los nombres de columnas antes de exportar, que detiene la ejecución con
`stop()` listando los nombres inválidos; y exportar con `bom = FALSE` para evitar que un BOM UTF-8
genere problemas de lectura en algunos programas.

**Verificación aplicada:** se probó renombrando a propósito una columna con mayúscula para
confirmar que el script se detiene con el mensaje de error esperado antes de escribir el CSV.

**Resultado:** Aceptado.

---

### 11. Domingo 30 de agosto — `run_all.R`: checkpoints para iterar más rápido

**Objetivo:** evitar tener que releer y limpiar cerca de 1.8 millones de registros crudos cada vez
que se prueba un cambio pequeño en el cruce o la validación.

**Prompt:** "Cada vez que pruebo un cambio pequeño en el cruce tengo que esperar a que se vuelvan a
leer y limpiar todos los `.txt` crudos, y eso toma bastante tiempo. ¿Cómo hago para que solo se
repita la carga completa cuando de verdad cambié `03_cargar_datos.R` o `04_limpieza.R`?"

**Respuesta obtenida:** guardar `saber11_completo` y `saberpro_completo` como checkpoints `.rds`
en `data/processed/` justo después de la limpieza, y controlar con un flag manual
(`FORZAR_RECARGA_COMPLETA`) si la siguiente corrida reutiliza esos checkpoints o recarga todo desde
cero. Se advirtió que el checkpoint debe invalidarse **manualmente** poniendo el flag en `TRUE` si
se edita `03` o `04`, porque el script no verifica automáticamente si el código cambió desde que se
guardó el `.rds`.

**Verificación aplicada:** se corrió una vez con `FORZAR_RECARGA_COMPLETA <- TRUE` y se confirmó en
`ejecucion_log.txt` el mensaje "Checkpoint guardado"; una segunda corrida con `FALSE` mostró
"Checkpoint encontrado" y omitió correctamente la carga y limpieza.

**Resultado:** Aceptado — se documentó también en el `README.md` como advertencia para el resto
del equipo.

---

## Resumen

| # | Fecha | Etapa / script | Resultado |
|---|---|---|---|
| 1 | 17 ago | `01_diccionarios_homologacion.R` | Aceptado |
| 2 | 18 ago | `02_funciones_lectura.R` | Aceptado |
| 3 | 20 ago | `04_limpieza.R` — fechas centinela | Aceptado parcialmente |
| 4 | 21 ago | `04_limpieza.R` — escala Saber Pro 2016 | Aceptado |
| 5 | 24 ago | `04_limpieza.R` — deduplicación (bug NA==NA) | Aceptado |
| 6 | 25 ago | `05_cruce.R` — bug periodo vs. año real | Aceptado |
| 7 | 26 ago | `06_validacion.R` — umbral de rezago | Aceptado |
| 8 | 27 ago | `06_validacion.R` — matriz de cobertura | Aceptado |
| 9 | 28 ago | `07_diccionario_final.R` | Aceptado |
| 10 | 29 ago | `08_exportar.R` — convención de nombres | Aceptado |
| 11 | 30 ago | `run_all.R` — checkpoints | Aceptado |

Ninguna respuesta de la IA se aceptó sin verificación contra el dato real, el log de ejecución o
una fuente externa (Resolución 455 de 2016 del ICFES). El caso del punto 3 (fechas centinela) es el
ejemplo más claro de una respuesta parcialmente descartada: se aceptó el criterio para valores
demográfica o estadísticamente imposibles, pero se rechazó extenderlo al *date heaping*, que se
documentó como limitación y no como error a corregir.