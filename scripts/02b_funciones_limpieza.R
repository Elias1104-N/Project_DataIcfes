#===============================================================================
# 02b_funciones_limpieza.R — Funciones auxiliares de limpieza que 06_validacion.R
# también necesita (aplicar_motivo_na_todas -> marcar_motivo_na).
#
# IMPORTANTE: se sourcea SIEMPRE en run_all.R, fuera del if/else del checkpoint,
# porque cuando se reutiliza el checkpoint (FORZAR_RECARGA_COMPLETA <- FALSE),
# 04_limpieza.R nunca corre, y con él se perdía la definición de esta función.
#===============================================================================

## --- Distinción "no preguntado" vs "no respondido" --------------------------
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

## --- Normalización de texto (por si el diccionario final u otro paso la usa) -
normalizar_texto <- function(x) {
  x <- toupper(trimws(x))
  x <- gsub("\\s+", " ", x)
  x <- iconv(x, from = "UTF-8", to = "ASCII//TRANSLIT")
  return(x)
}