#===============================================================================
# 05_cruce.R — Cruce Saber11-SaberPro con llave oficial ICFES 
#===============================================================================

col_cruce_sb11 <- config$llave_cruce_oficial$columna_cruce_saber11
col_cruce_spro <- config$llave_cruce_oficial$columna_cruce_saberpro
var_consecutivo_sb11 <- config$llave_cruce_oficial$consecutivo_saber11
var_consecutivo_spro <- config$llave_cruce_oficial$consecutivo_saberpro

# Denominador para la tasa de vinculacion

denominador_sb11 <- saber11_completo[, .N, by = periodo]
setnames(denominador_sb11, "N", "total_saber11")

# Validacion de calidad de la llave oficial ICFES
# A diferencia de la llave anterior, el riesgo de colision no es nuestro sino 
# de la tabla que publica el ICFES. Igual lo verificamos

dup_sb11 <- base_cruce_icfes[, .N, by = c(col_cruce_sb11)][N > 1]
dup_spro <- base_cruce_icfes[, .N, by = c(col_cruce_spro)][N > 1]

escribir_log(sprintf(
  "Base de cruce ICFES: %d consecutivos de Saber11 duplicados (%.2f%%),
   %d de Saber Pro duplicados (%.2f%%).",
  nrow(dup_sb11), 100 * nrow(dup_sb11) / nrow(base_cruce_icfes),
  nrow(dup_spro), 100 * nrow(dup_spro) / nrow(base_cruce_icfes)
), tipo = "WARNING", log_file = "ruta_log")


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