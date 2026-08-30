library(here)
library(data.table)
library(config)   # instala primero con install.packages("config") si no lo tienes
library(readxl)

cfg <- config::get(file = here("config.yml"))