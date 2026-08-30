library(here)
library(data.table)
library(config) 
library(yaml)
library(readxl)

config <- config::get(file = here("config.yml"))
ruta_log <- here(config$paths$log_file)
