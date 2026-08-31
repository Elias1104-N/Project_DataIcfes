#===============================================================================
# 07_diccionario_final.R — Genera el diccionario de la base final automáticamente,
# fusionando hechos técnicos (regenerados cada corrida) con descripciones
# mantenidas manualmente (persisten entre corridas).
#===============================================================================

# --- Hechos técnicos: siempre frescos, calculados sobre la base real ---------
hechos_tecnicos <- data.table(
  nombre_variable = names(base_cruzada),
  tipo_dato = sapply(base_cruzada, function(x) class(x)[1]),
  pct_faltantes = sapply(base_cruzada, function(x) round(100 * sum(is.na(x)) / length(x), 2)),
  n_categorias_unicas = sapply(base_cruzada, function(x) if (is.character(x)) length(unique(x)) else NA)
)

# --- Contenido manual: se conserva si el archivo ya existe -------------------
# tipo_dato NO se trae del manual — el calculado automáticamente es más
# confiable porque refleja el estado real de la base, no lo que se anotó
# la última vez a mano.
ruta_diccionario_final <- here("data", "metadata", "diccionario_base_final.xlsx")

if (file.exists(ruta_diccionario_final)) {
  descripciones <- as.data.table(read_excel(ruta_diccionario_final))[
    , .(nombre_variable, fuente, descripcion, disponibilidad_temporal, limitaciones)
  ]
} else {
  descripciones <- data.table(nombre_variable = character(), fuente = character(),
                              descripcion = character(), disponibilidad_temporal = character(),
                              limitaciones = character())
}

# --- Fusión: técnico siempre actualizado + contenido manual conservado ------
diccionario_final <- merge(hechos_tecnicos, descripciones, by = "nombre_variable", all.x = TRUE)


# Fail-loud suave (no detiene el pipeline, pero avisa): columnas sin describir
sin_describir <- diccionario_final[is.na(descripcion), nombre_variable]
if (length(sin_describir) > 0) {
  escribir_log(sprintf(
    "Diccionario final: %d columna(s) sin descripcion manual, requieren completarse: %s",
    length(sin_describir), paste(sin_describir, collapse = ", ")
  ), tipo = "WARNING", log_file = ruta_log)
}

# --- Exportar: sobreescribe el archivo, con las descripciones ya fusionadas -
if (!dir.exists(here("output", "tables"))) dir.create(here("output", "tables"), recursive = TRUE)
fwrite(diccionario_final, here("output", "tables", "diccionario_base_final.csv"))
writexl::write_xlsx(diccionario_final, ruta_diccionario_final)

escribir_log(sprintf("Diccionario final regenerado: %d columnas documentadas.", nrow(diccionario_final)), log_file = ruta_log)