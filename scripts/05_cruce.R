#===============================================================================
# 05_cruce.R — Cruce Saber11-SaberPro vía llave oficial de consecutivos ICFES
#===============================================================================

col_cruce_sb11 <- config$llave_cruce_oficial$columna_cruce_saber11
col_cruce_spro <- config$llave_cruce_oficial$columna_cruce_saberpro
var_consecutivo_sb11 <- config$llave_cruce_oficial$consecutivo_saber11   # "estu_consecutivo"
var_consecutivo_spro <- config$llave_cruce_oficial$consecutivo_saberpro # "estu_consecutivo"

# --- Denominador para tasa de vinculación (igual que antes) -----------------
denominador_sb11 <- saber11_completo[, .N, by = periodo]
setnames(denominador_sb11, "N", "total_saber11")

# --- Validación de calidad de la propia base de cruce del ICFES -------------
# A diferencia de la llave demográfica, aquí el riesgo de colisión no es
# nuestro: es de la tabla que publica el ICFES. Igual hay que verificarlo,
# no asumir que viene perfecta.
dup_sb11 <- base_cruce_icfes[, .N, by = c(col_cruce_sb11)][N > 1]
dup_spro <- base_cruce_icfes[, .N, by = c(col_cruce_spro)][N > 1]

escribir_log(sprintf(
  "Base de cruce ICFES: %d consecutivos de Saber11 duplicados (%.2f%%), %d de Saber Pro duplicados (%.2f%%).",
  nrow(dup_sb11), 100 * nrow(dup_sb11) / nrow(base_cruce_icfes),
  nrow(dup_spro), 100 * nrow(dup_spro) / nrow(base_cruce_icfes)
), tipo = "WARNING", log_file = ruta_log)

# Registros con NA en la propia tabla de cruce (no deberían existir, pero se
# excluyen explícitamente antes del merge por la misma razón que antes:
# NA == NA no debe generar una coincidencia).
cruce_completo <- base_cruce_icfes[!is.na(get(col_cruce_sb11)) & !is.na(get(col_cruce_spro))]
n_incompletos_cruce <- nrow(base_cruce_icfes) - nrow(cruce_completo)
if (n_incompletos_cruce > 0) {
  escribir_log(sprintf(
    "Excluidas %d filas de la base de cruce ICFES por NA en algun consecutivo.",
    n_incompletos_cruce
  ), tipo = "WARNING", log_file = ruta_log)
}

# --- Cruce en dos pasos: Saber11 -> tabla de cruce -> SaberPro ---------------
paso1 <- merge.data.table(
  saber11_completo, cruce_completo,
  by.x = var_consecutivo_sb11, by.y = col_cruce_sb11,
  all = FALSE
)

base_cruzada <- merge.data.table(
  paso1, saberpro_completo,
  by.x = col_cruce_spro, by.y = var_consecutivo_spro,
  suffixes = c("_saber11", "_saberpro"),
  all = FALSE
)

rm(paso1)
gc()

escribir_log(sprintf(
  "Cruce completado (llave oficial ICFES): %d registros totales, %d variables.",
  nrow(base_cruzada), ncol(base_cruzada)
), log_file = ruta_log)

## --- Limpieza de redundancias en base_cruzada -------------------------------

# 1) periodo_sb11/periodo_sbpro venían de la tabla de cruce (solo se usaron
# para filtrar por ventana en 03b_cargar_cruce.R). Duplican exactamente
# periodo_saber11/periodo_saberpro, que vienen del dato crudo de cada prueba.
# Se verifica antes de borrar: si hubiera discrepancias, sería un hallazgo de
# calidad de datos del ICFES, no un simple duplicado.
discrepancias_sb11  <- base_cruzada[periodo_sb11 != periodo_saber11, .N]
discrepancias_sbpro <- base_cruzada[periodo_sbpro != periodo_saberpro, .N]
escribir_log(sprintf(
  "Verificacion redundancia periodo: %d discrepancias periodo_sb11 vs periodo_saber11, %d discrepancias periodo_sbpro vs periodo_saberpro.",
  discrepancias_sb11, discrepancias_sbpro
), tipo = if (discrepancias_sb11 > 0 || discrepancias_sbpro > 0) "WARNING" else "INFO", log_file = ruta_log)

base_cruzada[, c("periodo_sb11", "periodo_sbpro") := NULL]

# 2) Renombrar estu_consecutivo -> estu_consecutivo_sb11 para que quede
# simétrico con estu_consecutivo_sbpro (antes no se notaba a cuál prueba
# pertenecía cada consecutivo con solo mirar el nombre).
setnames(base_cruzada, "estu_consecutivo", "estu_consecutivo_sb11")

# 3) Tipo de documento: dejar solo dos columnas limpias (Saber11 y SaberPro).
# estu_tipodocumento_saberpro, tal como salía del merge, en realidad contenía
# el dato de Saber 11 recordado dentro del archivo de Saber Pro — remanente
# del renombrado en 04_limpieza.R que solo servía para la llave demográfica
# vieja. Ya no aporta información distinta de estu_tipodocumento_saber11.
base_cruzada[, estu_tipodocumento_saberpro := NULL]

# estu_tipodocumento_actual_sbpro sí es el tipo de documento real reportado
# en Saber Pro — se renombra para que quede como el par limpio esperado.
setnames(base_cruzada, "estu_tipodocumento_actual_sbpro", "estu_tipodocumento_saberpro")

escribir_log(sprintf(
  "Limpieza de redundancias completada: base_cruzada queda con %d variables.",
  ncol(base_cruzada)
), log_file = ruta_log)
