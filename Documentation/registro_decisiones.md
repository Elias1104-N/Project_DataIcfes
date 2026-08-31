# Registro de decisiones — Proyecto Integración de datos ICFES

Bitácora cronológica de las decisiones metodológicas tomadas durante el proyecto: qué se decidió, qué
alternativas se consideraron, por qué se eligió esa opción y qué consecuencia tuvo sobre la base final.

> **Nota de uso:** las fechas exactas de cada decisión no quedaron registradas al momento de escribir esta
> versión; se dejan marcadas con `[fecha]` para que el equipo las complete con la fecha real en que se tomó
> cada decisión (o la fecha aproximada según el avance del cronograma del curso). El contenido metodológico
> de cada entrada sí está verificado contra el código y los comentarios existentes en los scripts.

---

## Fase 3 — Diseño de la estrategia de integración

### 1. Elección de la llave de vinculación estándar

- **Fecha:** [fecha]
- **Decisión:** usar una llave compuesta por `estu_fechanacimiento`, `estu_genero`, `estu_tipodocumento`,
  `estu_cod_reside_mcpio`, `cole_cod_dane_establecimiento` y `fami_estratovivienda` para vincular Saber 11
  con Saber Pro.
- **Alternativas consideradas:**
  - Usar únicamente tipo y número de documento de identidad. Descartada: el número de documento no está
    disponible o no es consistente de forma confiable entre ambas fuentes para todo el periodo.
  - Usar nombre completo del estudiante. Descartada: alto riesgo de falsos positivos por homónimos y
    variaciones de escritura entre años.
- **Justificación:** combinación de variables demográficas y de colegio disponibles en ambas pruebas, con
  el código DANE del colegio como llave autoritativa (los códigos no cambian de escritura entre años, los
  nombres sí).
- **Consecuencia sobre la base:** los registros con `NA` en cualquier componente de la llave se excluyen del
  cruce por esa vía (ver `filtrar_llave_completa()` en `05_cruce.R`) y se cuantifican explícitamente en el
  log como "excluidos por llave incompleta".

### 2. Llave reforzada para el periodo 2023–2024

- **Fecha:** [fecha]
- **Decisión:** aplicar una llave alternativa (`estu_fechanacimiento`, `estu_genero`, `estu_tipodocumento`,
  `fami_estratovivienda`, `estu_mcpio_presentacion`) exclusivamente para el subconjunto de Saber Pro con
  `anio_saberpro` entre 2023 y 2024 (parámetro `periodo_reforzada_desde/hasta` en `config.yml`).
- **Alternativas consideradas:**
  - Mantener la llave estándar para toda la serie. Descartada: generaba una caída anómala de vinculación en
    esos años específicos, indicando un problema de calidad/disponibilidad en las variables de colegio de
    residencia para ese periodo, no un problema real de emparejamiento.
  - Excluir 2023–2024 del alcance. Descartada: hubiera reducido innecesariamente la cobertura del panel en
    las cohortes más recientes con datos disponibles.
- **Justificación:** cambio detectado en la disponibilidad/calidad de `cole_cod_dane_establecimiento` /
  `estu_cod_reside_mcpio` en esos periodos específicos.
- **Consecuencia sobre la base:** cada registro final queda marcado con la variable `llave_reforzada_usada`
  (`TRUE`/`FALSE`), permitiendo distinguir en el análisis posterior qué método de vinculación se usó.

---

## Fase 4 — Limpieza, estandarización e integración

### 3. Corrección de la interpretación de `periodo` en Saber Pro

- **Fecha:** [fecha]
- **Decisión:** tratar `periodo` en Saber Pro como un código `AAAAS` de 5 dígitos (igual formato que Saber
  11), y derivar `anio_saberpro <- periodo %/% 10` para cualquier comparación contra un año de 4 dígitos.
- **Alternativa considerada (versión original, descartada):** asumir que `periodo` ya era directamente un
  año de 4 dígitos. Esta versión producía comparaciones que nunca coincidían al particionar la llave
  reforzada contra `periodo_reforzada_desde/hasta` (2023, 2024).
- **Justificación:** verificación empírica del formato real de la columna en los archivos crudos.
- **Consecuencia sobre la base:** sin esta corrección, la partición estándar/reforzada y el cálculo de
  rezago (`rezago_anios`) habrían sido incorrectos en toda la serie, no solo en 2023–2024.

### 4. Comparabilidad de puntajes de Saber Pro (cambio de escala 2016)

- **Fecha:** [fecha]
- **Decisión:** **no** transformar los puntajes anteriores a 2016 a la escala nueva; conservar el puntaje
  original y agregar la variable derivada booleana `puntaje_escala_comparable` (`periodo >=
  config$escala_saberpro$periodo_cambio`).
- **Alternativas consideradas:**
  - Normalizar todos los puntajes a una escala común. Descartada: requeriría un supuesto de transformación
    no respaldado por documentación oficial de recalibración retroactiva.
  - Excluir los años anteriores a 2016. Descartada: reduciría innecesariamente la cobertura del panel.
- **Justificación:** la Resolución 455 de 2016 del ICFES confirma un cambio de metodología de calificación
  completo (modelo TRI de 3 parámetros) para Saber Pro a partir de 2016; se verificó también empíricamente
  un salto abrupto en mínimo/máximo/promedio en ese periodo, y se descartó la existencia de una columna
  recalibrada alternativa en los años previos.
- **Consecuencia sobre la base:** cualquier análisis que compare puntajes entre periodos debe filtrar o
  segmentar por `puntaje_escala_comparable`; esta limitación se documenta explícitamente en el informe
  técnico (sección de limitaciones).

### 5. Fechas centinela en `estu_fechanacimiento`

- **Fecha:** [fecha]
- **Decisión:** convertir a `NA` las fechas `1900-01-01` y `1980-01-31`.
- **Alternativas consideradas:**
  - Conservarlas como fechas válidas. Descartada: `1900-01-01` implica una edad demográficamente imposible
    (>100 años) en el momento de presentación de la prueba; `1980-01-31` presenta un pico de frecuencia
    aislado de aproximadamente 10 veces sus fechas vecinas, patrón típico de un valor por defecto del
    sistema, no de nacimientos reales.
- **Justificación:** verificación estadística de ambos patrones contra el resto de la distribución.
- **Consecuencia sobre la base:** aumenta el conteo de `NA` en `estu_fechanacimiento`, pero evita distorsión
  en cualquier variable derivada de edad o de agrupamiento por cohorte. Se documenta aparte que Saber 11
  además muestra *date heaping* (fechas día=mes) como limitación de precisión de dato autorreportado, sin
  tratarse como error de captura.

### 6. Deduplicación de Saber Pro con variables de refuerzo

- **Fecha:** [fecha]
- **Decisión:** agrupar la deduplicación de `saberpro_completo` no solo por la llave base, sino agregando
  `estu_mcpio_presentacion` y `estu_inst_municipio`.
- **Alternativa considerada (versión original, descartada):** deduplicar solo con la llave base
  (`estu_fechanacimiento`, `estu_genero`, `estu_tipodocumentosb11`, `estu_mcpio_reside`,
  `estu_coddane_cole_termino`, `fami_estratovivienda`). Generaba una pérdida artificial de 65–84 % de
  registros en 2023–2024 y en 2016-2, porque `data.table` agrupa `NA == NA` como "iguales" al usar `by=`,
  fusionando por error estudiantes distintos con colegio/municipio de residencia faltantes.
- **Justificación:** verificación empírica — al agregar las variables de refuerzo, la caída de registros en
  2024 pasó de 65–84 % a 13–29 %, quedando consistente con el resto de la serie.
- **Consecuencia sobre la base:** reduce las fusiones falsas por agrupamiento de valores faltantes; el
  criterio de "un registro por estudiante" queda mejor sustentado.

---

## Fase 5 — Validación de la base construida

### 7. Umbral de rezago implausible calculado sobre la distribución real

- **Fecha:** [fecha]
- **Decisión:** definir el umbral superior de rezago plausible como el percentil 99 de los rezagos no
  negativos observados en la propia base (`UMBRAL_REZAGO_MAX`), en vez de un número fijo.
- **Alternativa considerada:** fijar un umbral arbitrario (por ejemplo, 15 años) sin sustento estadístico.
  Descartada porque no se ajusta necesariamente a la forma real de la distribución de esta base específica.
- **Justificación:** el enunciado exige justificar el criterio explícitamente, y no propone una única
  respuesta correcta.
- **Consecuencia sobre la base:** el umbral se recalcula automáticamente si la distribución de rezagos
  cambia al incorporar años nuevos; los rezagos negativos (orden temporal invertido) se marcan siempre como
  implausibles, independientemente del percentil.

---

## Fase 6 — Automatización y cierre

### 8. Checkpoints (`.rds`) para acelerar la iteración sobre el cruce

- **Fecha:** [fecha]
- **Decisión:** guardar `saber11_completo` y `saberpro_completo` ya limpios como `.rds` en
  `data/processed/`, y que `run_all.R` los reutilice si existen (`FORZAR_RECARGA_COMPLETA <- FALSE`) en vez
  de repetir carga y limpieza en cada ejecución.
- **Alternativa considerada:** recargar y limpiar los datos crudos completos en cada corrida. Descartada
  como flujo de trabajo por defecto, dado el volumen de doce años de dos pruebas nacionales (advertencia
  explícita del enunciado sobre volumen de datos); sigue siendo la opción usada cuando
  `FORZAR_RECARGA_COMPLETA <- TRUE`.
- **Justificación:** acelera significativamente la iteración sobre `05_cruce.R` y `06_validacion.R` sin
  necesidad de repetir lectura y limpieza de los archivos crudos en cada ajuste.
- **Riesgo detectado y consecuencia:** durante la Fase 6 se detectó que el checkpoint puede quedar
  desincronizado en silencio si se modifica `04_limpieza.R` (por ejemplo, al agregar la columna
  `anio_saberpro`, decisión #3) sin invalidar el `.rds` existente, produciendo errores de columna no
  encontrada aguas abajo. El caso se documenta en detalle en `docs/bitacora_ia.md`. Se recomienda —y queda
  pendiente de implementar— una validación de esquema del checkpoint antes de confiar en él.

---

## Pendientes de completar en este registro

- Fechas exactas de cada decisión.
- Cualquier decisión adicional tomada por el equipo que no haya quedado registrada como comentario en el
  código (por ejemplo, alcance final de la ventana temporal tras verificar disponibilidad real en
  DataICFES, criterio final de inclusión de estudiantes, tratamiento de presentaciones múltiples si difiere
  de "conservar el primer registro por periodo").
