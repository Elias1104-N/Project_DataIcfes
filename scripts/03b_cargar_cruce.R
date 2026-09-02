# -- Base de cruce oficial ICFES

ruta_cruce <- here(config$llave_cruce_oficial$archivo_cruce)
col_cruce_sb11 <- config$llave_cruce_oficial$columna_cruce_saber11
col_cruce_periodo_sb11 <- config$llave_cruce_oficial$columna_periodo_cruce_saber11
col_cruce_spro <- config$llave_cruce_oficial$columna_cruce_saberpro
col_cruce_periodo_spro <- config$llave_cruce_oficial$columna_periodo_cruce_saberpro


base_cruce_icfes <- fread(
  file = ruta_cruce,
  encoding = "UTF-8",
  select = c(col_cruce_sb11, col_cruce_periodo_sb11 ,col_cruce_spro, col_cruce_periodo_spro ),
  colClasses = setNames(c("character", "character", "character", "character"),
                        c(col_cruce_sb11, col_cruce_periodo_sb11,col_cruce_spro, col_cruce_periodo_spro))
)

n_total_cruce <- nrow(base_cruce_icfes)
n_total_cruce

base_cruce_icfes <- base_cruce_icfes[
  get(col_cruce_periodo_sb11) >= config$ventana_cruce_saber11$periodo_desde &
    get(col_cruce_periodo_sb11) <= config$ventana_cruce_saber11$periodo_hasta & 
    get(col_cruce_periodo_spro) >= config$ventana_cruce_saberpro$periodo_desde &
    get(col_cruce_periodo_spro) <= config$ventana_cruce_saberpro$periodo_hasta
]

escribir_log(sprintf(
  "Base de cruce oficial ICFES cargada %d filas desde %s.",
  nrow(base_cruce_icfes), basename(ruta_cruce)
), log_file = ruta_log)
