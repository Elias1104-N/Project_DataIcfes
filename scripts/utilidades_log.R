#===============================================================================
# utilidades_log.R — Registro de ejecución (trazabilidad)
#
# Una sola función, usada en todo el pipeline, para que el rastro de ejecución
# quede en un único formato y en un único archivo físico.
#===============================================================================

#' Escribe una línea con timestamp en el log de ejecución.
#'
#' @param mensaje  Texto a registrar.
#' @param tipo     "INFO", "WARNING" o "ERROR". Default "INFO".
#' @param log_file Ruta absoluta al archivo de log (usualmente config$paths$log_file).
escribir_log <- function(mensaje, tipo = "INFO", log_file) {
  linea <- sprintf(
    "[%s] [%s] %s",
    format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    tipo,
    mensaje
  )
  cat(linea, "\n", file = log_file, append = TRUE, sep = "")
  invisible(linea)
}

#' Inicializa el log al comienzo de una corrida (encabezado separador).
iniciar_log <- function(log_file) {
  if (!dir.exists(dirname(log_file))) {
    dir.create(dirname(log_file), recursive = TRUE)
  }
  cat(
    "\n=====================================================================\n",
    sprintf("Ejecución iniciada: %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
    "=====================================================================\n",
    file = log_file, append = TRUE, sep = ""
  )
  invisible(NULL)
}
