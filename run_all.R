#===============================================================================
# run_all.R — Ejecuta el pipeline completo de principio a fin.
#
# Estado actual: carga y homologación de Saber 11 y Saber Pro (Fase 4).
# Pendiente de agregar a medida que se construya: limpieza fina,
# deduplicación, integración (Fase 5) y validación (Fase 6).
#===============================================================================

source(here::here("scripts", "00_setup.R"))
source(here::here("scripts", "01_diccionarios_homologacion.R"))
source(here::here("scripts", "02_funciones_lectura.R"))
source(here::here("scripts", "03_cargar_datos.R"))
source(here::here("scripts", "04_limpieza.R"))

message("Pipeline completado. Objetos generados: saber11_completo, saberpro_completo")
message("Guardados en data/processed/")

saveRDS(saber11_completo, here("data", "processed", "saber11_completo.rds"))
saveRDS(saberpro_completo, here("data", "processed", "saberpro_completo.rds"))