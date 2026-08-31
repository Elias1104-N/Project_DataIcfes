library(here)
library(data.table)
data.table::setDTthreads(0)  # usa todos los núcleos disponibles
library(readxl)
library(writexl)

config <- config::get(file = here("config.yml"))
ruta_log <- here(config$paths$log_file)
 