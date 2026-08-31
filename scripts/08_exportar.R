#===============================================================================
# 08_exportar.R — Exporta la base consolidada final (Entregable 1)
# Requiere: base_cruzada (ver 05_cruce.R)
#===============================================================================

## --- Validación de convención de nombres antes de exportar ------------------
# Fail-fast: nombres de variable en minúscula, sin tildes ni espacios (exigido
# por el enunciado para el Entregable 1). Si alguien agrega una columna nueva
# más adelante sin seguir la convención, esto debe detener la ejecución, no
# dejarlo pasar en silencio.
nombres_invalidos <- names(base_cruzada)[
  grepl("[A-ZÁÉÍÓÚÑ ]", names(base_cruzada))
]
if (length(nombres_invalidos) > 0) {
  stop(sprintf(
    "ERROR: nombres de variable no cumplen la convencion (minuscula, sin tildes ni espacios): %s",
    paste(nombres_invalidos, collapse = ", ")
  ))
}

## --- Exportación --------------------------------------------------------------
ruta_salida_base <- here("output", "tables", "base_consolidada_saber11_saberpro.csv")

if (!dir.exists(here("output", "tables"))) dir.create(here("output", "tables"), recursive = TRUE)

fwrite(
  base_cruzada,
  file = ruta_salida_base,
  sep = ",",
  dec = ".",
  na = "NA",
  bom = FALSE          # evita el BOM UTF-8 que algunos lectores interpretan mal
)

escribir_log(sprintf(
  "Base final exportada a CSV: %d registros, %d variables -> %s",
  nrow(base_cruzada), ncol(base_cruzada), ruta_salida_base
), log_file = ruta_log)

message(sprintf("Entregable 1 exportado: %s (%d registros, %d variables)",
                ruta_salida_base, nrow(base_cruzada), ncol(base_cruzada)))