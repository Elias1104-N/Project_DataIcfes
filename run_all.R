#===============================================================================
# run_all.R
#===============================================================================

source(here::here("scripts", "00_setup.R"))
source(here::here("logs", "utilidades_log.R"))
iniciar_log(ruta_log)
source(here::here("scripts", "01_diccionarios_homologacion.R"))
source(here::here("scripts", "02_funciones_lectura.R"))
source(here::here("scripts", "02b_funciones_limpieza.R"))

ruta_checkpoint_sb11  <- here("data", "processed", "saber11_completo.rds")
ruta_checkpoint_spro  <- here("data", "processed", "saberpro_completo.rds")

# Cambia a FALSE cuando ya confirmaste que la carga+limpieza está bien y
# solo quieres iterar sobre el cruce (05_cruce.R) sin repetir todo lo demás.
FORZAR_RECARGA_COMPLETA <- T

if (!FORZAR_RECARGA_COMPLETA && file.exists(ruta_checkpoint_sb11) && file.exists(ruta_checkpoint_spro)) {
  
  escribir_log("Checkpoint encontrado: cargando saber11_completo/saberpro_completo desde .rds (se omite carga+limpieza).", log_file = ruta_log)
  saber11_completo  <- readRDS(ruta_checkpoint_sb11)
  saberpro_completo <- readRDS(ruta_checkpoint_spro)
  
} else {
  
  source(here::here("scripts", "03_cargar_datos.R"))
  source(here::here("scripts", "04_limpieza.R"))
  
  if (!dir.exists(here("data", "processed"))) dir.create(here("data", "processed"), recursive = TRUE)
  saveRDS(saber11_completo, ruta_checkpoint_sb11)
  saveRDS(saberpro_completo, ruta_checkpoint_spro)
  escribir_log("Checkpoint guardado: saber11_completo/saberpro_completo en data/processed/.", log_file = ruta_log)
  
}

# Se carga SIEMPRE, fuera del if/else de arriba: el checkpoint solo cubre
# saber11_completo/saberpro_completo, no la base de cruce oficial ICFES.
source(here::here("scripts", "03b_cargar_cruce.R"))

source(here::here("scripts", "05_cruce.R"))
source(here::here("scripts", "06_validacion.R"))
source(here::here("scripts", "07_diccionario_final.R"))
source(here::here("scripts", "08_exportar.R"))
# NOTA: 08_exportar.R se agregó a la cadena de run_all.R para que ejecutar
# este único script sea, sin excepción, sinónimo de obtener el .csv final
# (antes había que sourcearlo aparte, lo que llevaba a errores como olvidar
# la extensión .R al escribir la ruta a mano).

message("Pipeline completado. Objeto generado: base_cruzada, exportado a output/tables/base_consolidada_saber11_saberpro.csv")