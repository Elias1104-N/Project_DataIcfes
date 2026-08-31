#===============================================================================
# 05_cruce.R — Cruce Saber11-SaberPro con llave condicional por periodo
#===============================================================================

llave_estandar_sb11  <- config$llave_cruce$estandar$saber11
llave_estandar_spro  <- config$llave_cruce$estandar$saberpro
llave_reforzada_sb11 <- config$llave_cruce$reforzada$saber11
llave_reforzada_spro <- config$llave_cruce$reforzada$saberpro
periodo_ref_desde    <- config$llave_cruce$periodo_reforzada_desde
periodo_ref_hasta    <- config$llave_cruce$periodo_reforzada_hasta

if (length(llave_estandar_sb11) != length(llave_estandar_spro)) {
  stop("La llave estandar tiene distinto numero de columnas entre saber11 y saberpro en config.yml.")
}
if (length(llave_reforzada_sb11) != length(llave_reforzada_spro)) {
  stop("La llave reforzada tiene distinto numero de columnas entre saber11 y saberpro en config.yml.")
}

validar_columnas_llave <- function(datos, columnas, nombre_tabla) {
  faltantes <- setdiff(columnas, names(datos))
  if (length(faltantes) > 0) {
    stop(sprintf("[%s] Faltan columnas de la llave de cruce: %s", nombre_tabla, paste(faltantes, collapse = ", ")))
  }
}
validar_columnas_llave(saber11_completo, llave_estandar_sb11, "saber11_completo (estandar)")
validar_columnas_llave(saberpro_completo, llave_estandar_spro, "saberpro_completo (estandar)")
validar_columnas_llave(saber11_completo, llave_reforzada_sb11, "saber11_completo (reforzada)")
validar_columnas_llave(saberpro_completo, llave_reforzada_spro, "saberpro_completo (reforzada)")

# --- Denominador para tasa de vinculación (ANTES de excluir por llave incompleta) ---
denominador_sb11 <- saber11_completo[, .N, by = periodo]
setnames(denominador_sb11, "N", "total_saber11")

# --- Partición de Saber Pro por AÑO REAL (anio_saberpro), no por periodo crudo ---
# CORREGIDO: antes se comparaba 'periodo' (código AAAAS de 5 dígitos, ej. 20233)
# directamente contra periodo_ref_desde/hasta (2023, 2024) — nunca coincidía.
saberpro_estandar  <- saberpro_completo[anio_saberpro < periodo_ref_desde | anio_saberpro > periodo_ref_hasta]
saberpro_reforzada <- saberpro_completo[anio_saberpro >= periodo_ref_desde & anio_saberpro <= periodo_ref_hasta]

escribir_log(sprintf(
  "Particion Saber Pro para cruce: %d con llave estandar, %d con llave reforzada (anios %s-%s).",
  nrow(saberpro_estandar), nrow(saberpro_reforzada), periodo_ref_desde, periodo_ref_hasta
), log_file = ruta_log)

# --- Excluir filas con NA en cualquier columna de la llave, ANTES del merge -
filtrar_llave_completa <- function(datos, columnas_llave) {
  filtro <- datos[, Reduce(`&`, lapply(.SD, function(x) !is.na(x))), .SDcols = columnas_llave]
  list(completos = datos[filtro], incompletos = datos[!filtro])
}

sb11_estandar        <- filtrar_llave_completa(saber11_completo, llave_estandar_sb11)
spro_estandar_split  <- filtrar_llave_completa(saberpro_estandar, llave_estandar_spro)
sb11_reforzada       <- filtrar_llave_completa(saber11_completo, llave_reforzada_sb11)
spro_reforzada_split <- filtrar_llave_completa(saberpro_reforzada, llave_reforzada_spro)

escribir_log(sprintf(
  "Excluidos por llave incompleta (NA) - estandar: %d Saber11, %d SaberPro. Reforzada: %d Saber11, %d SaberPro.",
  nrow(sb11_estandar$incompletos), nrow(spro_estandar_split$incompletos),
  nrow(sb11_reforzada$incompletos), nrow(spro_reforzada_split$incompletos)
), tipo = "WARNING", log_file = ruta_log)

# --- Cruce 1: llave estándar --------------------------------------------------
base_cruzada_estandar <- merge.data.table(
  sb11_estandar$completos, spro_estandar_split$completos,
  by.x = llave_estandar_sb11, by.y = llave_estandar_spro,
  suffixes = c("_saber11", "_saberpro"),
  all = FALSE
)
base_cruzada_estandar[, llave_reforzada_usada := FALSE]

# --- Cruce 2: llave reforzada (2023-2024) ------------------------------------
base_cruzada_reforzada <- merge.data.table(
  sb11_reforzada$completos, spro_reforzada_split$completos,
  by.x = llave_reforzada_sb11, by.y = llave_reforzada_spro,
  suffixes = c("_saber11", "_saberpro"),
  all = FALSE
)
base_cruzada_reforzada[, llave_reforzada_usada := TRUE]

# --- Unión final --------------------------------------------------------------
base_cruzada <- rbindlist(list(base_cruzada_estandar, base_cruzada_reforzada), fill = TRUE)

rm(base_cruzada_estandar, base_cruzada_reforzada, saberpro_estandar, saberpro_reforzada)
gc()

escribir_log(sprintf("Cruce completado: %d registros totales, %d variables (%d via llave reforzada).",
                     nrow(base_cruzada), ncol(base_cruzada), base_cruzada[llave_reforzada_usada == TRUE, .N]),
             log_file = ruta_log)