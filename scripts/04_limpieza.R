#===============================================================================
# 04_limpieza.R — Tipificación y estandarización (Fase 4)
# Requiere: saber11_completo, saberpro_completo ya cargados (ver 03_cargar_datos.R)
#===============================================================================

## --- Tipificación de fechas -------------------------------------------------
saber11_completo[, estu_fechanacimiento := as.IDate(estu_fechanacimiento, format = "%Y/%m/%d")]
saberpro_completo[, estu_fechanacimiento := as.IDate(estu_fechanacimiento, format = "%Y/%m/%d")]

# NOTA: 913 casos de estu_fechanacimiento vacío en Saber Pro 2016 (de 245,181
# registros) corresponden a campo "no respondido" por el estudiante, no a un
# problema de formato ni de tipificación. Verificado contra el dato crudo
# (ver scripts/exploracion/02_diagnostico_limpieza.R).
# Categoría: "no respondido", distinta de "no preguntado" (ej. percentil_global
# en 2014-1, que no existía como variable). Otros ~17-40 casos por archivo en
# el resto de periodos son ruido normal de captura, sin patrón de concentración.

## --- Padding de códigos DANE a longitud oficial (evita perder ceros) -------
saber11_completo[!is.na(estu_cod_reside_mcpio), estu_cod_reside_mcpio := sprintf("%05d", as.integer(estu_cod_reside_mcpio))]
saber11_completo[!is.na(estu_cod_reside_depto), estu_cod_reside_depto := sprintf("%02d", as.integer(estu_cod_reside_depto))]
saberpro_completo[!is.na(estu_cod_reside_mcpio), estu_cod_reside_mcpio := sprintf("%05d", as.integer(estu_cod_reside_mcpio))]
saberpro_completo[!is.na(estu_cod_reside_depto), estu_cod_reside_depto := sprintf("%02d", as.integer(estu_cod_reside_depto))]

## --- Fechas centinela confirmadas (no son nacimientos reales) --------------
# 1900-01-01: imposible demográficamente (edad >100 años). 1980-01-31: pico
# aislado ~10x sus fechas vecinas (814 vs 55-90), patrón típico de valor
# "por defecto" del sistema. Verificado, no se trata de date heaping normal.
saber11_completo[estu_fechanacimiento == as.IDate("1900-01-01"), estu_fechanacimiento := NA]
saberpro_completo[estu_fechanacimiento == as.IDate("1900-01-01"), estu_fechanacimiento := NA]
saber11_completo[estu_fechanacimiento == as.IDate("1980-01-31"), estu_fechanacimiento := NA]
saberpro_completo[estu_fechanacimiento == as.IDate("1980-01-31"), estu_fechanacimiento := NA]

# NOTA: Saber 11 muestra date heaping (fechas día=mes: 09-09, 12-12, etc.,
# 2x-6.4x el promedio de 291 registros/fecha) — patrón conocido en datos
# autorreportados, NO se anula por no ser demográficamente imposible.
# Documentado como limitación de precisión, no como error de captura.

## --- Marca de comparabilidad de escala en puntajes Saber Pro ---------------
# El ICFES cambió la escala de calificación de Saber Pro en 2016 (de un rango
# aprox. 0-20 a 0-300), confirmado por la Resolución 455 de 2016: "las escalas
# de calificación... serán las producidas para la primera aplicación 2016...
# la línea de base... se construirá a partir de 2016". Confirmado también
# empíricamente (salto abrupto de min/max/promedio en el periodo 20162) y
# descartada la existencia de una columna recalibrada alternativa en años
# anteriores (ver scripts/exploracion/02_diagnostico_limpieza.R).
# Aplica a todos los módulos genéricos, no solo lectura crítica, porque fue
# un cambio de metodología de calificación completo (modelo TRI 3 parámetros).

saberpro_completo[, puntaje_escala_comparable := periodo >= config$escala_saberpro$periodo_cambio]

## --- Valores centinela: texto vacío en variables geográficas/colegio ------
saber11_completo[estu_mcpio_reside == "", estu_mcpio_reside := NA]
saberpro_completo[estu_mcpio_reside == "", estu_mcpio_reside := NA]
saber11_completo[cole_cod_dane_establecimiento == "", cole_cod_dane_establecimiento := NA]
saberpro_completo[estu_coddane_cole_termino == "", estu_coddane_cole_termino := NA]

## --- Valores centinela: texto vacío en género y estrato --------------------

# "Sin Estrato" -> NA explícito (valor centinela, no información socioeconómica real)
saber11_completo[fami_estratovivienda == "Sin Estrato", fami_estratovivienda := NA]
saberpro_completo[fami_estratovivienda == "Sin Estrato", fami_estratovivienda := NA]

# "Estrato 0" (Saber Pro 2016-2017, n=1,726) tratado como valor centinela: no
# existe oficialmente en el sistema de estratificación colombiano (rango 1-6).
# No se encontró documentación oficial del ICFES que lo defina como categoría
# válida — decisión tomada por ausencia de evidencia en contra, no por
# confirmación directa. Documentado como limitación de certeza en el informe.

saberpro_completo[fami_estratovivienda == "Estrato 0", fami_estratovivienda := NA]

## --- Año real de Saber Pro (periodo es codigo AAAAS de 5 digitos, NO año simple) ---
# CRÍTICO: periodo en Saber Pro NO es un año de 4 dígitos como se asumió
# originalmente — es un código AAAAS igual que Saber 11 (ej. 20233, no 2023).
# Sin esta conversión, cualquier comparación directa de periodo contra un año
# (partición de llave reforzada, cálculo de rezago) da resultados sin sentido.
saberpro_completo[, anio_saberpro := periodo %/% 10]

# Texto vacío ("") en estas variables significa "no respondido", no una
# categoría válida. Se convierte a NA explícito. Verificado en
# scripts/exploracion/02_diagnostico_limpieza.R.
saber11_completo[estu_tipodocumento == "", estu_tipodocumento := NA]
saberpro_completo[estu_tipodocumento == "", estu_tipodocumento := NA]

# estu_tipodocumentosb11 vacío es más frecuente de lo esperado (29,682 casos
# en 2014, decreciendo a ~4,000-8,000/año en periodos posteriores) — no es
# ruido disperso, representa una limitación real de la llave de vinculación
# para esos estudiantes específicos (menor refuerzo disponible). Se convierte
# a NA para tratamiento consistente; el impacto en la tasa de colisión de la
# llave debe evaluarse en Fase 5 al ejecutar el cruce real.

saberpro_completo[estu_tipodocumentosb11 == "", estu_tipodocumentosb11 := NA]

saber11_completo[estu_genero == "", estu_genero := NA]
saberpro_completo[estu_genero == "", estu_genero := NA]
saber11_completo[fami_estratovivienda == "", fami_estratovivienda := NA]
saberpro_completo[fami_estratovivienda == "", fami_estratovivienda := NA]

## --- Normalización de texto libre -------------------------------------------
# Colapsa espacios múltiples, quita espacios al inicio/final, unifica
# mayúsculas y quita tildes/diacríticos — evita que la misma institución o
# colegio cuente como "distinto" solo por diferencias de formato.
normalizar_texto <- function(x) {
  x <- toupper(trimws(x))
  x <- gsub("\\s+", " ", x)
  x <- iconv(x, from = "UTF-8", to = "ASCII//TRANSLIT")
  return(x)
}

saberpro_completo[, inst_nombre_institucion := normalizar_texto(inst_nombre_institucion)]
saber11_completo[, cole_nombre_establecimiento := normalizar_texto(cole_nombre_establecimiento)]
saberpro_completo[, cole_nombre_establecimiento := normalizar_texto(cole_nombre_establecimiento)]

## --- Validación de códigos de municipio contra DIVIPOLA --------------------
tabla_dane <- as.data.table(read_excel(here(config$paths$metadata_dane)))
setnames(tabla_dane, c("codigo_departamento", "nombre_departamento", "codigo_municipio", "nombre_municipio"))
tabla_dane <- tabla_dane[!is.na(codigo_municipio)]
tabla_dane[, codigo_municipio := sprintf("%05d", as.integer(codigo_municipio))]
tabla_dane[, codigo_departamento := sprintf("%02d", as.integer(codigo_departamento))]
tabla_dane <- unique(tabla_dane)

validar_codigos_dane <- function(datos, nombre_tabla) {
  no_reconocidos <- setdiff(unique(datos$estu_cod_reside_mcpio), tabla_dane$codigo_municipio)
  no_reconocidos <- no_reconocidos[!is.na(no_reconocidos)]
  if (length(no_reconocidos) > 0) {
    escribir_log(sprintf("[%s] %d codigos de municipio no reconocidos por DIVIPOLA: %s",
                         nombre_tabla, length(no_reconocidos), paste(head(no_reconocidos, 20), collapse = ", ")),
                 tipo = "WARNING", log_file = ruta_log)
  }
  invisible(no_reconocidos)
}

validar_codigos_dane(saber11_completo, "saber11_completo")
validar_codigos_dane(saberpro_completo, "saberpro_completo")

## --- Formalizar la distinción no_preguntado / no_respondido -----------------
marcar_motivo_na <- function(datos, columna, diccionario, col_periodo = "periodo") {
  col_flag <- paste0(columna, "_motivo_na")
  datos[, (col_flag) := fifelse(
    is.na(get(columna)),
    fifelse(
      get(col_periodo) < diccionario[nombre_final == columna, min(periodo_desde)] |
        get(col_periodo) > diccionario[nombre_final == columna, max(periodo_hasta)],
      "no_preguntado",
      "no_respondido"
    ),
    NA_character_
  )]
}

marcar_motivo_na(saber11_completo, "percentil_global", diccionario_homologacion_sb11)
marcar_motivo_na(saberpro_completo, "estu_tipodocumentosb11", diccionario_homologacion_saberpro)
# repite para cualquier otra variable donde esta distinción importe para tu análisis

## --- Fail-fast de puntajes usando los parámetros de config.yml -------------
rango_sb11 <- config$validacion_rangos$saber11_punt_global
if (nrow(saber11_completo[!is.na(punt_global) & (punt_global < rango_sb11[1] | punt_global > rango_sb11[2])]) > 0) {
  stop("ERROR: Puntajes globales de Saber 11 fuera del rango permitido en config.yml")
}

rango_spro <- config$validacion_rangos$saberpro_punt_global
if (nrow(saberpro_completo[!is.na(punt_global) & (punt_global < rango_spro[1] | punt_global > rango_spro[2])]) > 0) {
  stop("ERROR: Puntajes globales de Saber Pro fuera del rango permitido en config.yml")
}

## --- Deduplicación --------------------------------------------------------
saber11_completo <- saber11_completo[
  order(periodo),
  .SD[1],
  by = .(estu_fechanacimiento, estu_genero, estu_tipodocumento,
         estu_mcpio_reside, cole_cod_dane_establecimiento, fami_estratovivienda)
]

saberpro_completo <- saberpro_completo[
  order(periodo),
  .SD[1],
  by = .(estu_fechanacimiento, estu_genero, estu_tipodocumentosb11,
         estu_mcpio_reside, estu_coddane_cole_termino, fami_estratovivienda,
         estu_mcpio_presentacion, estu_inst_municipio)
]

# La deduplicación inicial (sin variables de refuerzo) generaba pérdida
# artificial en 2023-2024 y 2016-2, porque data.table agrupa NA==NA como
# "iguales" al usar by= — estudiantes distintos con colegio/municipio
# de residencia faltantes (documentado en Fase 4) se fusionaban por error.
# Se corrigió agregando estu_mcpio_presentacion y estu_inst_municipio
# (mismo refuerzo ya usado para la llave de vinculación) al agrupamiento
# de deduplicación. Verificado: caída en 2024 pasó de 65-84% a 13-29%,
# consistente con el resto de la serie.

## --- Renombrado final para unificar nombres antes del cruce ----------------
# Preserva el tipo de documento ACTUAL de Saber Pro con otro nombre, antes de
# liberar "estu_tipodocumento" para que sea el nombre común de la llave
setnames(saberpro_completo, "estu_tipodocumento", "estu_tipodocumento_actual_sbpro")
setnames(saberpro_completo, "estu_tipodocumentosb11", "estu_tipodocumento")
setnames(saberpro_completo, "estu_coddane_cole_termino", "cole_cod_dane_establecimiento")
saberpro_completo[cole_cod_dane_establecimiento == "", cole_cod_dane_establecimiento := NA]