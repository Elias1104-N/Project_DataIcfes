leer_saber11 <- function(ruta, diccionario, tipos_columna = NULL) {
  nombre_archivo <- basename(ruta)
  periodo_archivo <- extraer_periodo_de_nombre(nombre_archivo)
  
  especificacion <- construir_especificacion(diccionario, periodo_archivo)
  
  columnas_disponibles <- names(fread(file = ruta, nrows = 0, encoding = "UTF-8"))
  
  disponibles <- especificacion[especificacion %in% columnas_disponibles]
  faltantes   <- especificacion[!especificacion %in% columnas_disponibles]
  
  datos <- fread(file = ruta, select = unname(disponibles), encoding = "UTF-8", colClasses = tipos_columna)
  setnames(datos, old = unname(disponibles), new = names(disponibles))
  
  # En leer_saber11 y leer_saberpro:
  if (length(faltantes) > 0) {
    for (nombre_final_faltante in names(faltantes)) {
      datos[, (nombre_final_faltante) := NA]
    }
    # Enviar al sistema centralizado de logs en vez de la consola
    mensaje <- sprintf("Archivo %s - Faltan variables (marcadas NA): %s", nombre_archivo, paste(names(faltantes), collapse = ", "))
    escribir_log(mensaje, tipo = "WARNING", log_file = here::here(config::get()$paths$log_file))
  } else {
    escribir_log(sprintf("Archivo %s - Leído con éxito sin variables faltantes.", nombre_archivo), tipo = "INFO", log_file = here::here(config::get()$paths$log_file))
    
  }
  
  datos[, archivo_origen := nombre_archivo]
  return(datos)
}

leer_saberpro <- function(ruta, diccionario, tipos_columna = NULL) {
  nombre_archivo <- basename(ruta)
  anio_archivo <- extraer_anio_de_nombre_saberpro(nombre_archivo)
  
  especificacion <- construir_especificacion(diccionario, anio_archivo)
  
  columnas_disponibles <- names(fread(file = ruta, nrows = 0, encoding = "UTF-8"))
  
  disponibles <- especificacion[especificacion %in% columnas_disponibles]
  faltantes   <- especificacion[!especificacion %in% columnas_disponibles]
  
  datos <- fread(file = ruta, select = unname(disponibles), encoding = "UTF-8", colClasses = tipos_columna)
  setnames(datos, old = unname(disponibles), new = names(disponibles))
  
  # En leer_saber11 y leer_saberpro:
  if (length(faltantes) > 0) {
    for (nombre_final_faltante in names(faltantes)) {
      datos[, (nombre_final_faltante) := NA]
    }
    # Enviar al sistema centralizado de logs en vez de la consola
    mensaje <- sprintf("Archivo %s - Faltan variables (marcadas NA): %s", nombre_archivo, paste(names(faltantes), collapse = ", "))
    escribir_log(mensaje, tipo = "WARNING", log_file = here::here(config::get()$paths$log_file))
  } else {
    escribir_log(sprintf("Archivo %s - Leído con éxito sin variables faltantes.", nombre_archivo), tipo = "INFO", log_file = here::here(config::get()$paths$log_file))
  }
  
  datos[, archivo_origen := nombre_archivo]
  return(datos)
}
