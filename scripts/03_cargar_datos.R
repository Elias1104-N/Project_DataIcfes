archivos_sb11_todos <- list.files(
  path = here("data", "raw", "Saber11"),
  pattern = "^Examen_Saber_11_[0-9]{5}\\.txt$",
  full.names = TRUE
)

periodos_detectados <- sapply(basename(archivos_sb11_todos), extraer_periodo_de_nombre)

archivos_sb11 <- archivos_sb11_todos[periodos_detectados >= config$ventana_saber11$periodo_desde & periodos_detectados <= config$ventana_saber11$periodo_hasta]

lista_sb11 <- lapply(
  archivos_sb11,
  leer_saber11,
  diccionario = diccionario_homologacion_sb11,
  tipos_columna = c(cole_cod_dane_establecimiento = "character",
                    estu_cod_reside_mcpio = "character",estu_cod_mcpio_presentacion = "character")
)

saber11_completo <- rbindlist(lista_sb11, fill = TRUE)

archivos_saberpro_todos <- list.files(
  path = here("data", "raw", "SaberPro"),
  pattern = "^Examen_Saber_Pro_Genericas_[0-9]{4}\\.txt$",
  full.names = TRUE
)

anios_detectados <- sapply(basename(archivos_saberpro_todos), extraer_anio_de_nombre_saberpro)
archivos_saberpro <- archivos_saberpro_todos[anios_detectados >= config$ventana_saberpro$anio_desde & anios_detectados <= config$ventana_saberpro$anio_hasta]
lista_saberpro <- lapply(
  archivos_saberpro,
  leer_saberpro,
  diccionario = diccionario_homologacion_saberpro,
  tipos_columna = c(estu_coddane_cole_termino = "character",
                    inst_cod_institucion = "character",
                    estu_cod_reside_mcpio = "character", estu_snies_prgmacademico = "character",
                    estu_cod_mcpio_presentacion = "character", estu_inst_codmunicipio = "character")
)

saberpro_completo <- rbindlist(lista_saberpro, fill = TRUE)