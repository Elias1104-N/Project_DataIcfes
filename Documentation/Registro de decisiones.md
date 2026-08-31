# Registro de decisiones metodológicas

**Proyecto:** Integración de datos ICFES — Panel longitudinal Saber 11 → Saber Pro (2014–2025)
**Curso:** Estadística Industrial · Ingeniería Industrial · Universidad del Magdalena · 2026-II
**Entregable 6:** `docs/registro_decisiones.md`
**Periodo cubierto:** 13 – 30 de agosto de 2026

---

## Nota metodológica

Este registro documenta, en orden cronológico, las decisiones metodológicas tomadas durante el
desarrollo del pipeline. No es una bitácora de ejecución ni un changelog de código: para cada
decisión se deja constancia de qué se decidió, qué alternativas se consideraron, por qué se
eligió la opción final y qué consecuencia tuvo sobre la base de datos resultante. El objetivo es
que cualquier persona pueda entender, sin leer el código, por qué la base final tiene la forma que
tiene.

---

### 13 de agosto — Fuente de verdad para la homologación de variables

**Decisión:** construir los diccionarios de homologación (`diccionario_saber11.xlsx`,
`diccionario_saberpro.xlsx`) a partir de la revisión directa de los documentos oficiales del
ICFES (guías de interpretación y lectura de resultados, layouts de archivo por periodo) en vez de
inferir la correspondencia entre nombres de variable solo comparando los encabezados de los
`.txt` crudos entre años.

**Alternativas consideradas:**
- Inferir la homologación por similitud de nombres de columna entre archivos de años consecutivos.
- Usar únicamente el diccionario que trae el propio archivo de datos del ICFES (cuando existe),
  sin contrastarlo contra la documentación oficial.

**Justificación:** los nombres de columna cambian de forma no siempre obvia entre periodos (renombres,
variables que desaparecen y reaparecen, variables que cambian de significado), por lo que basarse
solo en coincidencia de texto arriesgaba homologar variables que no son en realidad la misma
pregunta. La documentación oficial es la única fuente que permite verificar el significado de cada
variable, no solo su nombre.

**Consecuencia sobre la base:** el crosswalk de homologación (`nombre_final`, `nombre_en_archivo`,
`periodo_desde`, `periodo_hasta` por variable) queda trazable a una fuente oficial y auditable, y
se convirtió en la base de la que dependen todos los pasos posteriores del pipeline.

---

### 14 de agosto — Diccionarios como archivos externos, no como código

**Decisión:** mantener los diccionarios de homologación como archivos Excel editables en
`data/metadata/`, leídos por `01_diccionarios_homologacion.R`, en vez de escribirlos como
`data.table()` dentro del propio script de R.

**Alternativas consideradas:**
- Definir los diccionarios directamente en el script como estructuras de datos en R.
- Usar un archivo de configuración de texto plano (CSV) en vez de Excel.

**Justificación:** agregar una equivalencia nueva o un año adicional con nombres de variable
distintos no debía requerir editar código ni entender R — cualquier integrante del equipo puede
abrir el Excel y agregar una fila. Se prefirió Excel sobre CSV porque además sirve como documento
de referencia legible para el informe técnico. Se agregó una validación estructural
(`stopifnot()`) que detiene la ejecución si el Excel queda mal formado o vacío, en vez de dejarlo
pasar en silencio.

**Consecuencia sobre la base:** la actualización de la base con años nuevos del ICFES no requiere
modificar ningún script — solo el Excel correspondiente — reduciendo el riesgo de introducir
errores de código al incorporar datos nuevos.

---

### 17-18 de agosto — Tolerancia a variables faltantes por periodo

**Decisión:** que la lectura de cada archivo crudo (`leer_saber11()` / `leer_saberpro()`) no se
detenga si un periodo no tiene alguna de las variables del diccionario; en su lugar, la variable se
crea como `NA` para ese periodo y queda registrada en el log.

**Alternativas consideradas:**
- Detener la ejecución si algún archivo no tiene todas las variables esperadas.
- Omitir silenciosamente el archivo completo cuando le falte alguna variable.

**Justificación:** el ICFES no pregunta las mismas variables en todos los periodos (p. ej.
`percentil_global` no existía en 2014-1); detener el pipeline por eso habría impedido construir
un panel multi-cohorte. Omitir el archivo completo habría sido peor: se perderían todas las
variables disponibles de ese periodo por culpa de una sola variable ausente. Rellenar con `NA` y
registrar la ausencia en el log preserva el resto de la información y deja trazabilidad de qué
falta y por qué.

**Consecuencia sobre la base:** la base final incluye todos los periodos de la ventana 2014-2025
aunque no todos tengan las mismas variables; el porcentaje de faltantes por variable-periodo queda
documentado en `ejecucion_log.txt` y es la base para distinguir después "no preguntado" de "no
respondido" (ver decisión del 23 de agosto).

---

### 19 de agosto — Configuración centralizada en `config.yml`

**Decisión:** centralizar en un único archivo (`config.yml`) la ventana temporal de cada prueba,
el periodo de cambio de escala de Saber Pro, los rangos válidos de puntaje, la definición de las
llaves de cruce y las rutas de datos — en vez de tener esos parámetros dispersos como valores
fijos dentro de cada script.

**Alternativas consideradas:**
- Definir cada parámetro como una variable al inicio del script donde se usa.
- Pasar los parámetros como argumentos al ejecutar `run_all.R` en vez de un archivo de
  configuración.

**Justificación:** varios de estos parámetros (ventana temporal, rangos válidos) se necesitan en
más de un script; si estuvieran repetidos en cada uno, actualizar la base con un año nuevo
implicaría buscar y cambiar el mismo valor en varios lugares, con riesgo de dejar alguno
desactualizado. Un archivo de configuración único hace explícito, en un solo lugar, qué se puede
cambiar sin tocar código.

**Consecuencia sobre la base:** incorporar un año nuevo (p. ej. Saber Pro 2026) se reduce a
copiar el `.txt` y actualizar dos valores en `config.yml`, sin editar ningún script.

---

### 20 de agosto — Tratamiento de fechas de nacimiento centinela vs. *date heaping*

**Decisión:** anular como `NA` únicamente `estu_fechanacimiento == "1900-01-01"` y
`"1980-01-31"`; conservar sin modificar el patrón de *date heaping* (concentración en fechas
día=mes, ej. 09-09, 12-12).

**Alternativas consideradas:**
- Anular cualquier fecha con patrón día=mes, asumiendo que también son valores por defecto del
  sistema.
- No anular ninguna fecha y dejar que el análisis posterior filtre lo que considere necesario.

**Justificación:** `1900-01-01` es descartable por imposibilidad demográfica directa (implicaría
edades superiores a 100 años). `1980-01-31` se verificó empíricamente: su frecuencia es
~10 veces la de fechas vecinas (814 vs. 55-90 registros), un patrón característico de un valor
"por defecto" del sistema, no de nacimientos reales. El *date heaping* día=mes, en cambio, es un
patrón conocido de datos autorreportados y no mostró ese mismo salto abrupto de frecuencia — se
consideró una limitación de precisión del dato, no un error de captura, por lo que anularlo
habría sido eliminar información real sin evidencia que lo justifique.

**Consecuencia sobre la base:** se pierden como `NA` solo los registros con fechas
demostrablemente imposibles o centinela; el *date heaping* queda documentado como limitación en el
informe técnico en vez de corregirse, evitando una pérdida de datos no justificada.

---

### 21 de agosto — Cambio de escala de Saber Pro (2016): marcar, no descartar

**Decisión:** no excluir los puntajes de Saber Pro anteriores a 2016; en su lugar, agregar la
variable `puntaje_escala_comparable` (`TRUE`/`FALSE` según el periodo) para que la comparabilidad
de escala quede marcada explícitamente en la base, y sea el análisis posterior quien decida si los
incluye.

**Alternativas consideradas:**
- Excluir de la base todos los registros de Saber Pro anteriores a 2016.
- Intentar recalibrar los puntajes antiguos a la escala nueva mediante alguna transformación
  estadística.

**Justificación:** se confirmó, mediante la Resolución 455 de 2016 del ICFES y de forma empírica
(salto abrupto en mínimo/máximo/promedio del periodo 20162), que el cambio de escala corresponde a
un cambio de metodología de calificación completo (modelo TRI de 3 parámetros), no a un error de
lectura. Excluir los datos antiguos habría reducido innecesariamente la ventana temporal del
panel. Recalibrar sin una tabla de equivalencia oficial del ICFES habría introducido un supuesto
no verificable. Marcar la comparabilidad de escala, sin transformar ni excluir, preserva toda la
información y traslada la decisión de comparabilidad al análisis, donde puede documentarse con el
contexto adecuado.

**Consecuencia sobre la base:** el panel conserva toda la ventana 2014-2025 de Saber Pro; cualquier
análisis que compare puntajes entre periodos debe filtrar explícitamente por
`puntaje_escala_comparable == TRUE`, evitando comparaciones inválidas entre escalas distintas.

---

### 21-22 de agosto — Valores centinela en estrato ("Sin Estrato", "Estrato 0")

**Decisión:** convertir a `NA` tanto "Sin Estrato" (ambas pruebas) como "Estrato 0" (Saber Pro
2016-2017, n=1,726).

**Alternativas consideradas:**
- Tratar "Estrato 0" como una categoría socioeconómica válida distinta de las demás.
- Dejar "Sin Estrato" y "Estrato 0" sin modificar y filtrarlos únicamente en el análisis.

**Justificación:** "Sin Estrato" es explícitamente un valor centinela, no información
socioeconómica real. "Estrato 0" no existe oficialmente en el sistema de estratificación
colombiano (rango 1-6); no se encontró documentación oficial del ICFES que lo defina como
categoría válida. Se decidió tratarlo como centinela por ausencia de evidencia en contra, no por
confirmación directa — esta incertidumbre se documentó explícitamente como limitación en el
informe, en vez de presentarlo como un hecho verificado.

**Consecuencia sobre la base:** `fami_estratovivienda` queda como variable ordinal limpia
(1-6 o NA); el tamaño relativamente pequeño de "Estrato 0" (1,726 registros, años acotados)
significa que el impacto sobre el análisis socioeconómico es limitado, pero la decisión queda
señalada como la de menor certeza de todo el proceso de limpieza.

---

### 22 de agosto — Normalización de texto libre en nombres de colegios e instituciones

**Decisión:** normalizar `cole_nombre_establecimiento` e `inst_nombre_institucion`
(mayúsculas, espacios colapsados, sin tildes/diacríticos) antes de cualquier análisis o cruce.

**Alternativas consideradas:**
- Dejar el texto tal como viene en el archivo crudo y normalizar solo si se necesita para un
  análisis específico más adelante.
- Usar el nombre normalizado como parte de la llave de cruce entre Saber 11 y Saber Pro.

**Justificación:** sin normalizar, la misma institución podía aparecer como entidades distintas
solo por diferencias de formato (mayúsculas, tildes, espacios), lo que habría distorsionado
cualquier conteo o agregación por colegio/institución. No se usó como parte de la llave de cruce
porque la vinculación Saber11-SaberPro se basa en identidad del estudiante (fecha de nacimiento,
género, tipo de documento, ubicación), no en el nombre del colegio, que puede cambiar entre las dos
pruebas si el estudiante cambió de institución.

**Consecuencia sobre la base:** los conteos y agregaciones por colegio o institución son
consistentes; la normalización no afecta la llave de cruce, que depende de otras variables.

---

### 23 de agosto — Distinguir "no preguntado" de "no respondido"

**Decisión:** crear variables `_motivo_na` que distingan, para cada NA, si la variable no
existía como pregunta en ese periodo ("no_preguntado") o si existía pero el estudiante no la
contestó ("no_respondido").

**Alternativas consideradas:**
- Dejar todos los NA sin distinción de motivo.
- Excluir de la base las variables que no se preguntaron en todos los periodos, para evitar mezclar
  ambos tipos de ausencia.

**Justificación:** tratar todos los NA por igual mezcla dos fenómenos con implicaciones
completamente distintas para el análisis: una tasa alta de "no preguntado" es un artefacto del
diseño del instrumento en ese periodo, mientras que una tasa alta de "no respondido" puede ser
informativa (p. ej. sobre el perfil de quien omite una pregunta). Excluir esas variables habría
significado perder información disponible en los periodos donde sí se preguntaron.

**Consecuencia sobre la base:** las variables con cobertura temporal parcial (ver
`aplicar_motivo_na_todas()` en `06_validacion.R`) quedan acompañadas de su columna `_motivo_na`,
permitiendo que el análisis de faltantes distinga limitación del instrumento de no-respuesta real.

---

### 24 de agosto — Deduplicación reforzada con variables adicionales

**Decisión:** deduplicar `saber11_completo` y `saberpro_completo` agrupando no solo por las
variables de identidad básicas, sino agregando variables de refuerzo (`estu_mcpio_presentacion`,
`estu_inst_municipio` en Saber Pro) al agrupamiento.

**Alternativas consideradas:**
- Deduplicar únicamente por las variables de identidad básicas (fecha de nacimiento, género, tipo
  de documento, municipio de residencia, colegio, estrato).
- No deduplicar y aceptar que pudiera haber registros repetidos del mismo estudiante en el mismo
  periodo.

**Justificación:** al probar la deduplicación con las variables básicas, se detectó una pérdida
anómala de 65-84% de los registros en 2023-2024 y 2016-2 — muy por encima del resto de la serie.
La causa es que `data.table` agrupa `NA == NA` como "iguales" al usar `by =`, por lo que
estudiantes distintos con colegio o municipio de residencia faltantes (frecuente en esos periodos
específicos) se estaban fusionando como si fueran el mismo registro. Agregar las variables de
refuerzo ya usadas en la llave de vinculación reduce esa colisión espuria.

**Consecuencia sobre la base:** la caída de registros en 2024 pasó de 65-84% a 13-29%, en línea con
el resto de la serie, corrigiendo una pérdida de datos que no correspondía a duplicados reales
sino a un artefacto del agrupamiento con NA.

---

### 25 de agosto — Llave de cruce en dos niveles (estándar / reforzada) y corrección de `periodo` vs. año real

**Decisión:** usar una llave "estándar" para la mayoría de los periodos y una llave "reforzada"
(con variables adicionales) específicamente para 2023-2024; y corregir la partición de Saber Pro
para que use `anio_saberpro` (`periodo %/% 10`) en vez del código crudo `periodo`.

**Alternativas consideradas:**
- Usar una sola llave de cruce para todos los periodos.
- Usar la llave reforzada para toda la serie, no solo para 2023-2024.

**Justificación:** el diagnóstico de faltantes (ver decisión del 23 de agosto) mostró que
`estu_tipodocumentosb11` vacío es particularmente frecuente en 2023-2024, debilitando la llave
estándar justo en esos periodos; una llave reforzada con variables adicionales compensa esa
debilidad puntual sin penalizar el resto de la serie, donde la llave estándar funciona bien. Usar
la llave reforzada para toda la serie habría sido innecesariamente restrictivo donde no hace
falta. Durante la implementación se detectó que la partición por periodo no capturaba ningún
registro reforzado: `periodo` en Saber Pro es un código AAAAS de 5 dígitos (igual que en Saber 11),
no un año de 4 dígitos como se había asumido originalmente, por lo que comparar `periodo`
directamente contra `2023`/`2024` nunca coincidía.

**Consecuencia sobre la base:** cada registro cruzado queda marcado con `llave_reforzada_usada`,
permitiendo distinguir en el análisis qué parte de la base se vinculó con criterio más estricto;
tras la corrección del bug, la partición reforzada pasó de capturar 0 registros a 429,509 en el
periodo 2023-2024.

---

### 26 de agosto — Umbral de rezago plausible: percentil de la distribución real, no un número fijo

**Decisión:** calcular `UMBRAL_REZAGO_MAX` como el percentil 99 de la distribución real de
rezagos no negativos de la propia base cruzada, en vez de fijar un número de años arbitrario.

**Alternativas consideradas:**
- Fijar un umbral externo basado en la duración típica de un programa de pregrado (p. ej. 5-7
  años).
- No fijar ningún umbral y dejar que el análisis filtre rezagos extremos caso por caso.

**Justificación:** no existe un único umbral "correcto" definido externamente que aplique a esta
base específica — la trayectoria real de los estudiantes (repitencia, cambios de carrera, ingreso
tardío) puede exceder la duración nominal de un programa. Anclar el umbral a la forma real de la
distribución de rezagos de este proyecto, en vez de a una suposición externa, hace el criterio
defendible con los propios datos.

**Consecuencia sobre la base:** el umbral resultante (9 años) marca como `rezago_implausible` un
0.37% de los registros (1,912 de 517,119), de los cuales el 100% corresponde a rezago negativo
(orden temporal invertido) más que a rezagos excesivamente largos.

---

### 27 de agosto — Distinguir pérdida estructural de pérdida procedimental en la cobertura

**Decisión:** calcular explícitamente qué cohortes de Saber 11 caen en zona de "censura derecha"
(cohortes recientes que aún no pueden tener Saber Pro) y qué cohortes de Saber Pro caen en zona de
"truncamiento izquierda" (cohortes tempranas cuyo Saber 11 cae antes del inicio de la ventana), y
dejar esa interpretación registrada junto a la matriz de cobertura.

**Alternativas consideradas:**
- Presentar la matriz de cobertura sin ninguna interpretación adicional, dejando que el lector
  infiera las causas de la baja vinculación.
- Excluir de la base las cohortes con vinculación estructuralmente baja para "limpiar" la matriz.

**Justificación:** sin esta distinción, una tasa de vinculación baja en, por ejemplo, la cohorte
Saber 11 2025 podría leerse como una falla del procedimiento de cruce (llave, deduplicación,
calidad de dato), cuando en realidad es inherente a la ventana temporal 2014-2025: un estudiante
que presentó Saber 11 en 2025 estructuralmente no ha tenido tiempo de presentar Saber Pro todavía.
Excluir esas cohortes habría ocultado información legítima sobre la cobertura real del panel.

**Consecuencia sobre la base:** la matriz de cobertura se conserva completa, pero el log y el
informe técnico documentan explícitamente qué cohortes están en zona de censura/truncamiento
estructural, evitando que se interpreten como un defecto del procedimiento.

---

### 28 de agosto — Diccionario final: hechos técnicos siempre recalculados, descripciones manuales persistentes

**Decisión:** que `07_diccionario_final.R` recalcule siempre los hechos técnicos (tipo de dato,
% de faltantes, número de categorías únicas) sobre la base real de cada corrida, pero conserve las
descripciones escritas a mano (`fuente`, `descripcion`, `limitaciones`) del diccionario ya
existente vía `merge`.

**Alternativas consideradas:**
- Mantener el diccionario final completamente manual, actualizado a mano después de cada corrida.
- Regenerar el diccionario completo desde cero en cada corrida, sin conservar las descripciones
  manuales previas.

**Justificación:** un diccionario completamente manual se desactualiza fácilmente respecto al
estado real de la base (tipo de dato o % de faltantes que cambian entre corridas). Regenerarlo
completo desde cero habría obligado a reescribir las descripciones cualitativas cada vez, un
trabajo repetido innecesario. Separar lo que debe recalcularse siempre (hechos técnicos) de lo que
debe persistir (descripciones) evita ambos problemas.

**Consecuencia sobre la base:** el diccionario final queda siempre sincronizado con el estado real
de la base en cuanto a tipo de dato y faltantes, mientras conserva el trabajo de documentación
cualitativa entre corridas; el pipeline además advierte (sin detenerse) qué columnas nuevas
todavía no tienen descripción manual.

---

### 29 de agosto — Convención de nombres como validación fail-fast antes de exportar

**Decisión:** que `08_exportar.R` verifique, antes de escribir el CSV final, que ningún nombre
de columna tenga mayúsculas, tildes o espacios, deteniendo la ejecución con `stop()` si encuentra
alguno.

**Alternativas consideradas:**
- Confiar en que el equipo siga manualmente la convención de nombres al agregar columnas nuevas.
- Corregir automáticamente los nombres inválidos (minusculizar, quitar tildes) en vez de detener
  la ejecución.

**Justificación:** el enunciado del proyecto exige explícitamente la convención de nombres para el
Entregable 1; confiar en que se siga manualmente arriesga que una columna nueva agregada más
adelante por cualquier integrante del equipo incumpla la convención sin que nadie lo note hasta la
entrega. Corregir automáticamente habría ocultado el problema en vez de exponerlo, y podría generar
nombres de columna no anticipados en el resto del pipeline.

**Consecuencia sobre la base:** el CSV exportado (`base_consolidada_saber11_saberpro.csv`) cumple
la convención de nombres de forma garantizada por el propio script, no por revisión manual antes de
la entrega.

---

### 30 de agosto — Checkpoints `.rds` con invalidación manual

**Decisión:** guardar `saber11_completo` y `saberpro_completo` como checkpoints `.rds` en
`data/processed/` después de la limpieza, controlados por el flag manual
`FORZAR_RECARGA_COMPLETA` en `run_all.R`.

**Alternativas consideradas:**
- No usar checkpoints y releer/limpiar los datos crudos completos en cada corrida.
- Invalidar el checkpoint automáticamente comparando fecha de modificación o hash de
  `03_cargar_datos.R` y `04_limpieza.R` contra el checkpoint guardado.

**Justificación:** releer y limpiar cerca de 1.8 millones de registros crudos en cada iteración
sobre el cruce o la validación resultaba costoso en tiempo durante el desarrollo. Una invalidación
automática por hash habría sido más robusta, pero se consideró una complejidad adicional
innecesaria para el alcance del proyecto; se optó por un flag manual explícito, documentado como
advertencia en el README, aceptando el riesgo de que el equipo olvide activarlo tras modificar
`03` o `04`.

**Consecuencia sobre la base:** la iteración sobre `05_cruce.R` en adelante es sustancialmente más
rápida durante el desarrollo; a cambio, existe el riesgo -mitigado solo por advertencia
documental, no por verificación automática- de que un checkpoint quede desincronizado del código
si no se fuerza la recarga tras un cambio en carga o limpieza.

---

## Resumen cronológico

| Fecha | Decisión |
|---|---|
| 13 ago | Homologación basada en documentos oficiales del ICFES, no en coincidencia de nombres |
| 14 ago | Diccionarios como Excel externo, no como código |
| 17-18 ago | Variables faltantes se marcan NA y se registran, no detienen el pipeline |
| 19 ago | Parámetros centralizados en `config.yml` |
| 20 ago | Fechas centinela (1900-01-01, 1980-01-31) anuladas; *date heaping* conservado |
| 21 ago | Cambio de escala Saber Pro 2016 marcado con bandera, no excluido |
| 21-22 ago | "Sin Estrato" y "Estrato 0" tratados como centinela |
| 22 ago | Normalización de texto libre en nombres de colegio/institución |
| 23 ago | Distinción "no preguntado" vs. "no respondido" |
| 24 ago | Deduplicación reforzada (corrige colisión por NA==NA) |
| 25 ago | Llave de cruce en dos niveles + corrección `periodo` vs. `anio_saberpro` |
| 26 ago | Umbral de rezago = percentil 99 de la distribución real |
| 27 ago | Distinción censura/truncamiento estructural vs. pérdida procedimental |
| 28 ago | Diccionario final: técnico recalculado + manual persistente |
| 29 ago | Validación fail-fast de convención de nombres antes de exportar |
| 30 ago | Checkpoints `.rds` con invalidación manual |