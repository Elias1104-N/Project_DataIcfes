#===============================================================================
# 06_validacion.R — Fase 5: validación de la base cruzada
# Requiere: base_cruzada, denominador_sb11 (ver 05_cruce.R)
#===============================================================================

## --- 1. Registros y variables de la base final ------------------------------
escribir_log(sprintf("Base final: %d registros, %d variables.",
                     nrow(base_cruzada), ncol(base_cruzada)), log_file = ruta_log)

## --- 2. Verificación de unicidad (separada por llave usada) -----------------
conteo_identidad_estandar <- base_cruzada[llave_reforzada_usada == FALSE, .N,
                                          by = .(estu_fechanacimiento, estu_genero, estu_tipodocumento,
                                                 estu_cod_reside_mcpio, cole_cod_dane_establecimiento, fami_estratovivienda)]

conteo_identidad_reforzada <- base_cruzada[llave_reforzada_usada == TRUE, .N,
                                           by = .(estu_fechanacimiento, estu_genero, estu_tipodocumento,
                                                  fami_estratovivienda, estu_mcpio_presentacion_saber11)]  # ajusta el nombre si quedó distinto

print(table(conteo_identidad_estandar$N))
print(table(conteo_identidad_reforzada$N))

## --- 2b. Marcar vinculación ambigua (solo llave reforzada) ------------------
llaves_ambiguas_reforzada <- conteo_identidad_reforzada[N > 1,
                                                        .(estu_fechanacimiento, estu_genero, estu_tipodocumento,
                                                          fami_estratovivienda, estu_mcpio_presentacion_saber11)]

base_cruzada[, vinculacion_ambigua := FALSE]
base_cruzada[
  llave_reforzada_usada == TRUE
][llaves_ambiguas_reforzada, on = names(llaves_ambiguas_reforzada),
  vinculacion_ambigua := TRUE
]

n_ambiguos <- base_cruzada[vinculacion_ambigua == TRUE, .N]
pct_ambiguos <- round(100 * n_ambiguos / nrow(base_cruzada), 2)
escribir_log(sprintf("Vinculacion ambigua: %d registros (%s%%), dentro de llave reforzada.",
                     n_ambiguos, pct_ambiguos), tipo = "WARNING", log_file = ruta_log)

## --- 3. Rezago entre pruebas (umbral basado en percentiles reales) ---------
base_cruzada[, anio_saber11 := periodo_saber11 %/% 10]
base_cruzada[, rezago_anios := anio_saberpro - anio_saber11]

distribucion_rezago <- base_cruzada[, .N, by = rezago_anios][order(rezago_anios)]
print(distribucion_rezago)

# Umbral superior data-driven: percentil 99 de los rezagos NO negativos.
# Se prefiere esto a un número fijo (el HTML explícita que no hay una única
# respuesta correcta): el corte se apoya en la forma real de la distribución
# de ESTA base, no en una suposición externa.
rezagos_validos <- base_cruzada[rezago_anios >= 0, rezago_anios]
UMBRAL_REZAGO_MAX <- ceiling(quantile(rezagos_validos, 0.99, na.rm = TRUE))

escribir_log(sprintf(
  "Umbral de rezago plausible calculado como percentil 99 de la distribucion real: %d anios.",
  UMBRAL_REZAGO_MAX
), log_file = ruta_log)

base_cruzada[, rezago_implausible := rezago_anios < 0 | rezago_anios > UMBRAL_REZAGO_MAX]

n_implausibles <- base_cruzada[rezago_implausible == TRUE, .N]
n_invertidos <- base_cruzada[rezago_anios < 0, .N]
escribir_log(sprintf(
  "Casos de rezago implausible: %d total (%.2f%%) — de estos, %d son orden invertido (rezago < 0).",
  n_implausibles, 100 * n_implausibles / nrow(base_cruzada), n_invertidos
), tipo = "WARNING", log_file = ruta_log)

## --- 4. Matriz de cobertura de cohortes (con interpretación) ---------------
matriz_cobertura <- dcast(base_cruzada, anio_saber11 ~ anio_saberpro,
                          fun.aggregate = length, value.var = "estu_fechanacimiento")
print(matriz_cobertura)

# Interpretación explícita, requerida por el criterio C del HTML: distinguir
# pérdida ESTRUCTURAL (inherente a la ventana temporal, no corregible) de
# pérdida ATRIBUIBLE AL PROCEDIMIENTO (llave, deduplicación, calidad de dato).
anio_min_ventana <- config$ventana_saber11$periodo_desde %/% 10
anio_max_ventana <- config$ventana_saberpro$anio_hasta

# Censura derecha: cohortes Saber 11 recientes que estructuralmente no pueden
# tener aún su Saber Pro (el estudiante todavía no se ha graduado de pregrado).
cohortes_censura_derecha <- tasa_vinculacion[periodo %/% 10 > (anio_max_ventana - 3), periodo]

# Truncamiento izquierda: cohortes Saber Pro tempranas cuyo Saber 11
# correspondiente cae estructuralmente antes del inicio de la ventana.
cohortes_truncamiento_izq <- tasa_vinculacion_spro[anio_saberpro < (anio_min_ventana + 3), anio_saberpro]

escribir_log(sprintf(
  "Interpretacion cobertura: %d cohortes Saber11 en zona de censura derecha (%s), %d cohortes SaberPro en zona de truncamiento izquierda (%s). Baja vinculacion en estas cohortes es ESTRUCTURAL, no procedimental.",
  length(cohortes_censura_derecha), paste(cohortes_censura_derecha, collapse=","),
  length(cohortes_truncamiento_izq), paste(cohortes_truncamiento_izq, collapse=",")
), log_file = ruta_log)

## --- 5. Tasa de vinculación por cohorte --------------------------------------
vinculados_por_cohorte <- base_cruzada[, .N, by = .(periodo = periodo_saber11)]
setnames(vinculados_por_cohorte, "N", "vinculados")

tasa_vinculacion <- merge.data.table(denominador_sb11, vinculados_por_cohorte, by = "periodo", all.x = TRUE)
tasa_vinculacion[is.na(vinculados), vinculados := 0]
tasa_vinculacion[, tasa_pct := round(100 * vinculados / total_saber11, 2)]
print(tasa_vinculacion[order(periodo)])

## --- 5b. Tasa de vinculación del lado Saber Pro (truncamiento izquierda) ---
denominador_spro <- saberpro_completo[, .N, by = .(anio_saberpro)]
setnames(denominador_spro, "N", "total_saberpro")

vinculados_por_cohorte_spro <- base_cruzada[, .N, by = .(anio_saberpro)]
setnames(vinculados_por_cohorte_spro, "N", "vinculados")

tasa_vinculacion_spro <- merge(denominador_spro, vinculados_por_cohorte_spro, by = "anio_saberpro", all.x = TRUE)
tasa_vinculacion_spro[is.na(vinculados), vinculados := 0]
tasa_vinculacion_spro[, tasa_pct := round(100 * vinculados / total_saberpro, 2)]
print(tasa_vinculacion_spro[order(anio_saberpro)])

escribir_log(sprintf(
  "Tasa de vinculacion Saber Pro (truncamiento izquierda) calculada para %d cohortes.",
  nrow(tasa_vinculacion_spro)
), log_file = ruta_log)

## --- 6. Faltantes por variable ------------------------------------------------
aplicar_motivo_na_todas <- function(datos, diccionario) {
  rango_min <- min(diccionario$periodo_desde)
  rango_max <- max(diccionario$periodo_hasta)
  cobertura_var <- diccionario[, .(periodo_desde = min(periodo_desde), periodo_hasta = max(periodo_hasta)), by = nombre_final]
  variables_parciales <- cobertura_var[periodo_desde > rango_min | periodo_hasta < rango_max, nombre_final]
  for (var in variables_parciales) {
    if (var %in% names(datos)) marcar_motivo_na(datos, var, diccionario)
  }
  invisible(variables_parciales)
}

aplicar_motivo_na_todas(saber11_completo, diccionario_homologacion_sb11)
aplicar_motivo_na_todas(saberpro_completo, diccionario_homologacion_saberpro)

pct_faltantes <- sapply(base_cruzada, function(x) round(100 * sum(is.na(x)) / length(x), 2))
print(sort(pct_faltantes[pct_faltantes > 0], decreasing = TRUE))

escribir_log("Fase 5 (validacion) completada.", log_file = ruta_log)

