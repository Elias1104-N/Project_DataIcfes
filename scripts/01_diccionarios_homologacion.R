#===============================================================================
# 01_diccionarios_homologacion.R
# Los diccionarios viven como archivos externos editables (data/metadata/),
# no como data.table() escritos en este script — agregar una equivalencia o
# un año nuevo con nombre distinto ya no requiere tocar código, solo el Excel.
#===============================================================================

diccionario_homologacion_sb11 <- as.data.table(
  read_excel(here("data", "metadata", "diccionario_saber11.xlsx"))
)

diccionario_homologacion_saberpro <- as.data.table(
  read_excel(here("data", "metadata", "diccionario_saberpro.xlsx"))
)

# Validación estructural: detiene la ejecución si algún Excel quedó mal
# formado (columnas faltantes o vacío), en vez de dejarlo pasar en silencio.
stopifnot(
  "diccionario_saber11.xlsx debe tener columnas nombre_final, nombre_en_archivo, periodo_desde, periodo_hasta" =
    all(c("nombre_final", "nombre_en_archivo", "periodo_desde", "periodo_hasta") %in% names(diccionario_homologacion_sb11)),
  "diccionario_saberpro.xlsx debe tener columnas nombre_final, nombre_en_archivo, periodo_desde, periodo_hasta" =
    all(c("nombre_final", "nombre_en_archivo", "periodo_desde", "periodo_hasta") %in% names(diccionario_homologacion_saberpro)),
  "diccionario_saber11.xlsx no debe estar vacío" = nrow(diccionario_homologacion_sb11) > 0,
  "diccionario_saberpro.xlsx no debe estar vacío" = nrow(diccionario_homologacion_saberpro) > 0
)

extraer_periodo_de_nombre <- function(nombre_archivo) {
  numero <- regmatches(nombre_archivo, regexpr("[0-9]{5}", nombre_archivo))
  return(as.integer(numero))
}

extraer_anio_de_nombre_saberpro <- function(nombre_archivo) {
  numero <- regmatches(nombre_archivo, regexpr("[0-9]{4}", nombre_archivo))
  return(as.integer(numero))
}

construir_especificacion <- function(diccionario, periodo_archivo) {
  filas_validas <- diccionario[periodo_desde <= periodo_archivo & periodo_hasta >= periodo_archivo]
  especificacion <- filas_validas$nombre_en_archivo
  names(especificacion) <- filas_validas$nombre_final
  return(especificacion)
}

