archivos_sb11_todos <- list.files(
  path = here("data", "raw", "Saber11"),
  pattern = "^Examen_Saber_11_[0-9]{5}\\.txt$",
  full.names = TRUE
)

archivos_sb11 <- archivos_sb11_todos[periodos_detectados >= 20141 & periodos_detectados <= 20252]

lista_sb11 <- lapply(
  archivos_sb11,
  leer_saber11,
  diccionario = diccionario_homologacion_sb11,
  tipos_columna = c(cole_cod_dane_establecimiento = "character")
)

saber11_completo <- rbindlist(lista_sb11, fill = TRUE)

archivos_saberpro_todos <- list.files(
  path = here("data", "raw", "SaberPro"),
  pattern = "^Examen_Saber_Pro_Genericas_[0-9]{4}\\.txt$",
  full.names = TRUE
)

archivos_saberpro <- archivos_saberpro_todos[anios_detectados >= 2014 & anios_detectados <= 2025]

lista_saberpro <- lapply(
  archivos_saberpro,
  leer_saberpro,
  diccionario = diccionario_homologacion_saberpro,
  tipos_columna = c(estu_coddane_cole_termino = "character",
                    inst_cod_institucion = "character")
)

saberpro_completo <- rbindlist(lista_saberpro, fill = TRUE)