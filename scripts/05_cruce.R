#===============================================================================
# Cruce Saber11-SaberPro con llave condicional por periodo (parametrizada)
#===============================================================================

llave_estandar_sb11  <- config$llave_cruce$estandar$saber11
llave_estandar_spro  <- config$llave_cruce$estandar$saberpro
llave_reforzada_sb11 <- config$llave_cruce$reforzada$saber11
llave_reforzada_spro <- config$llave_cruce$reforzada$saberpro
periodo_ref_desde    <- config$llave_cruce$periodo_reforzada_desde
periodo_ref_hasta    <- config$llave_cruce$periodo_reforzada_hasta


# --- Fail-fast: las dos listas de cada llave deben tener el mismo largo ---
if (length(llave_estandar_sb11) != length(llave_estandar_spro)) {
  stop("La llave estandar tiene distinto numero de columnas entre saber11 y saberpro en config.yml.")
}
if (length(llave_reforzada_sb11) != length(llave_reforzada_spro)) {
  stop("La llave reforzada tiene distinto numero de columnas entre saber11 y saberpro en config.yml.")
}


# --- Fail-fast: las columnas de cada llave deben existir en su tabla ---
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

# --- Partición de Saber Pro según qué tramo de periodo le corresponde ---
anio_spro <- floor(saberpro_completo$periodo / 10)
saberpro_estandar  <- saberpro_completo[anio_spro < periodo_ref_desde | anio_spro > periodo_ref_hasta]
saberpro_reforzada <- saberpro_completo[anio_spro >= periodo_ref_desde & anio_spro <= periodo_ref_hasta]

escribir_log(sprintf(
  "Particion Saber Pro para cruce: %d con llave estandar, %d con llave reforzada (periodos %s-%s).",
  nrow(saberpro_estandar), nrow(saberpro_reforzada), periodo_ref_desde, periodo_ref_hasta
), log_file = ruta_log)

# --- Cruce 1: llave estándar ---
base_cruzada_estandar <- merge.data.table(
  saber11_completo, saberpro_estandar,
  by.x = llave_estandar_sb11, by.y = llave_estandar_spro,
  suffixes = c("_saber11", "_saberpro"),
  all = FALSE
)


base_cruzada_estandar[, llave_reforzada_usada := FALSE]

# --- Cruce 2: llave reforzada (2023-2024) ---
base_cruzada_reforzada <- merge.data.table(
  saber11_completo, saberpro_reforzada,
  by.x = llave_reforzada_sb11, by.y = llave_reforzada_spro,
  suffixes = c("_saber11", "_saberpro"),
  all = FALSE
)
base_cruzada_reforzada[, llave_reforzada_usada := TRUE]

# --- Unión final ---
base_cruzada <- rbindlist(list(base_cruzada_estandar, base_cruzada_reforzada), fill = TRUE)

escribir_log(sprintf(
  "Cruce completado: %d registros totales (%d con llave estandar, %d con llave reforzada).",
  nrow(base_cruzada), nrow(base_cruzada_estandar), nrow(base_cruzada_reforzada)
), log_file = ruta_log)


