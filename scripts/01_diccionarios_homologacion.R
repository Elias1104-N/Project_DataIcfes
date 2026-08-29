diccionario_homologacion_sb11 <- data.table(
  nombre_final = c(
    "estu_consecutivo", "periodo", "estu_tipodocumento", "estu_fechanacimiento",
    "estu_genero", "estu_mcpio_reside", "fami_estratovivienda",
    "cole_cod_dane_establecimiento", "fami_nivelsisben",
    "punt_sociales_ciudadanas", "punt_sociales_ciudadanas",
    "punt_ingles",
    "punt_lectura_critica", "punt_lectura_critica",
    "punt_matematicas",
    "punt_c_naturales", "punt_c_naturales",
    "punt_global", "percentil_global"
  ),
  nombre_en_archivo = c(
    "estu_consecutivo", "periodo", "estu_tipodocumento", "estu_fechanacimiento",
    "estu_genero", "estu_mcpio_reside", "fami_estratovivienda",
    "cole_cod_dane_establecimiento", "fami_nivelsisben",
    "punt_ciencias_sociales", "punt_sociales_ciudadanas",   # nombre viejo / nuevo
    "punt_ingles",
    "punt_lenguaje", "punt_lectura_critica",                 # nombre viejo / nuevo
    "punt_matematicas",
    "recaf_punt_c_naturales", "punt_c_naturales",             # nombre especial 2010-1 a 2014-1
    "punt_global", "percentil_global"
  ),
  periodo_desde = c(
    20101, 20101, 20101, 20101, 20101, 20101, 20101, 20101, 20101,
    20101, 20142, 20101, 20101, 20142, 20101, 20101, 20142, 20142, 20142
  ),
  periodo_hasta = c(
    20252, 20252, 20252, 20252, 20252, 20252, 20252, 20252, 20141,
    20141, 20252, 20252, 20141, 20252, 20252, 20141, 20252, 20252, 20252
  )
)

extraer_periodo_de_nombre <- function(nombre_archivo) {
  numero <- regmatches(nombre_archivo, regexpr("[0-9]{5}", nombre_archivo))
  return(as.integer(numero))
}

construir_especificacion <- function(diccionario, periodo_archivo) {
  filas_validas <- diccionario[periodo_desde <= periodo_archivo & periodo_hasta >= periodo_archivo]
  especificacion <- filas_validas$nombre_en_archivo
  names(especificacion) <- filas_validas$nombre_final
  return(especificacion)
}

extraer_anio_de_nombre_saberpro <- function(nombre_archivo) {
  numero <- regmatches(nombre_archivo, regexpr("[0-9]{4}", nombre_archivo))
  return(as.integer(numero))
}

diccionario_homologacion_saberpro <- data.table(
  nombre_final = c(
    "estu_consecutivo", "periodo", "estu_tipodocumento", "estu_tipodocumentosb11",
    "estu_fechanacimiento", "estu_genero", "estu_mcpio_reside", "fami_estratovivienda",
    "estu_coddane_cole_termino", "fami_nivel_sisben",
    "punt_sociales_ciudadanas", "punt_ingles", "punt_lectura_critica", "punt_matematicas",
    "punt_comuni_escrita", "punt_global", "percentil_global",
    "inst_nombre_institucion", "inst_cod_institucion", "estu_inst_departamento"
  ),
  nombre_en_archivo = c(
    "estu_consecutivo", "periodo", "estu_tipodocumento", "estu_tipodocumentosb11",
    "estu_fechanacimiento", "estu_genero", "estu_mcpio_reside", "fami_estratovivienda",
    "estu_coddane_cole_termino", "fami_nivel_sisben",
    "mod_competen_ciudada_punt", "mod_ingles_punt", "mod_lectura_critica_punt", "mod_razona_cuantitat_punt",
    "mod_comuni_escrita_punt", "punt_global", "percentil_global",
    "inst_nombre_institucion", "inst_cod_institucion", "estu_inst_departamento"
  ),
  periodo_desde = rep(2012, 20),
  periodo_hasta = rep(2025, 20)
)