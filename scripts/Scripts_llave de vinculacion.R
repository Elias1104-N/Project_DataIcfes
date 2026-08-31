#===============================================================================
# FASE 3 — Diseño de la estrategia de integración
#
# Objetivo de esta fase: decidir y VERIFICAR CON EVIDENCIA (no solo en teoría)
# cuál será la llave de vinculación entre Saber 11 y Saber Pro, antes de
# automatizar nada. Se trabaja con UN archivo de cada prueba (2014-1 y 2016)
# como muestra representativa, no con la ventana completa todavía.
#===============================================================================

library(here)
library(data.table)

## --- Carga de los dos archivos de prueba ---------------------------------

ruta_saber11 <- here("data", "raw", "Saber11", "Examen_Saber_11_20141.txt")
file.exists(ruta_saber11)   # debe dar TRUE antes de continuar

saber11_2014_1 <- fread(
  ruta_saber11,
  select = c("estu_consecutivo", "periodo", "estu_tipodocumento",
             "estu_fechanacimiento", "estu_genero", "estu_cod_reside_mcpio",
             "cole_cod_dane_establecimiento", "fami_estratovivienda"),
  encoding = "UTF-8",
  # Códigos DANE e institucionales forzados a texto: nunca deben leerse como
  # número, porque pierden ceros a la izquierda con significado (ej. 05001).
  colClasses = c(estu_cod_reside_mcpio = "character",
                 cole_cod_dane_establecimiento = "character",
                 fami_estratovivienda = "character")
)

ruta_saberpro <- here("data", "raw", "SaberPro", "Examen_Saber_Pro_Genericas_2016.txt")

saberpro_2016 <- fread(
  ruta_saberpro,
  select = c("estu_consecutivo", "periodo", "estu_tipodocumento",
             "estu_tipodocumentosb11", "estu_fechanacimiento", "estu_genero",
             "estu_cod_reside_mcpio", "estu_coddane_cole_termino", "fami_estratovivienda"),
  encoding = "UTF-8",
  colClasses = c(estu_cod_reside_mcpio = "character",
                 estu_coddane_cole_termino = "character",
                 fami_estratovivienda = "character")
)

## --- Chequeo de unicidad: núcleo de la llave (fecha nacimiento + género) --
#
# Pregunta que responde este bloque: si usáramos SOLO estas dos variables,
# ¿cuántos estudiantes distintos comparten exactamente la misma combinación?
# Un porcentaje alto de colisión significa que la llave, sola, es ambigua.

chequeo_unicidadSaber11 <- saber11_2014_1[, .N, by = .(estu_fechanacimiento, estu_genero)]
combi_unicavsrepe_SB11 <- table(chequeo_unicidadSaber11$N > 1)
combi_unicavsrepe_SB11
porcen_colisiones_SB11 <- sum(chequeo_unicidadSaber11[N > 1, N]) / nrow(saber11_2014_1) * 100
porcen_colisiones_SB11

chequeo_unicidadSaberPro <- saberpro_2016[, .N, by = .(estu_fechanacimiento, estu_genero)]
combi_unicavsrepe_SaberPro <- table(chequeo_unicidadSaberPro$N > 1)
combi_unicavsrepe_SaberPro
porcen_colisiones_SaberPro <- sum(chequeo_unicidadSaberPro[N > 1, N]) / nrow(saberpro_2016) * 100
porcen_colisiones_SaberPro

# RESULTADO: 92.65% (SB11) y 98.33% (SaberPro) de colisión. El núcleo solo
# es prácticamente inútil como llave — esperado, dado que hay decenas de miles
# de estudiantes con edades muy similares y género solo tiene 2 valores.
# Confirma que el refuerzo con variables adicionales no es opcional.

## --- Refuerzo 1: + tipo de documento --------------------------------------
# NOTA: para Saber Pro se usa estu_tipodocumentosb11 (el documento que tenía
# AL MOMENTO de presentar Saber 11), no estu_tipodocumento (el actual) —
# así comparamos el mismo momento de vida en ambos lados, evitando falsos
# negativos por menores que cambiaron de TI a CC con la mayoría de edad.

chequeo_reforzado_SB11 <- saber11_2014_1[, .N, by = .(estu_fechanacimiento, estu_genero, estu_tipodocumento)]
table(chequeo_reforzado_SB11$N > 1)
sum(chequeo_reforzado_SB11[N > 1, N]) / nrow(saber11_2014_1) * 100

chequeo_reforzado_SaberPro <- saberpro_2016[, .N, by = .(estu_fechanacimiento, estu_genero, estu_tipodocumentosb11)]
table(chequeo_reforzado_SaberPro$N > 1)
sum(chequeo_reforzado_SaberPro[N > 1, N]) / nrow(saberpro_2016) * 100

# RESULTADO: apenas bajó (91-94%). Tipo de documento tiene muy pocas
# categorías posibles (casi todos TI en Saber 11) — una variable de refuerzo
# necesita ALTA CARDINALIDAD para discriminar bien, no solo 2-3 valores.

## --- Refuerzo 2: + municipio de residencia --------------------------------

chequeo_reforzado2_SB11 <- saber11_2014_1[, .N, by = .(estu_fechanacimiento, estu_genero, estu_tipodocumento, estu_cod_reside_mcpio)]
table(chequeo_reforzado2_SB11$N > 1)
sum(chequeo_reforzado2_SB11[N > 1, N]) / nrow(saber11_2014_1) * 100

chequeo_reforzado2_SaberPro <- saberpro_2016[, .N, by = .(estu_fechanacimiento, estu_genero, estu_tipodocumentosb11, estu_cod_reside_mcpio)]
table(chequeo_reforzado2_SaberPro$N > 1)
sum(chequeo_reforzado2_SaberPro[N > 1, N]) / nrow(saberpro_2016) * 100

# RESULTADO: baja a 33-37%. Con >1000 municipios en Colombia, esta variable
# sí tiene cardinalidad suficiente para discriminar de verdad.

## --- Refuerzo 3: + colegio de origen ---------------------------------------
# cole_cod_dane_establecimiento (SB11) y estu_coddane_cole_termino (SBPRO)
# son el MISMO concepto (código DANE del colegio) visto desde cada prueba.
# A diferencia de municipio, el colegio de graduación no cambia con el
# tiempo, así que exigir coincidencia exacta aquí es más seguro.

chequeo_reforzado3_SB11 <- saber11_2014_1[, .N, by = .(estu_fechanacimiento, estu_genero, estu_tipodocumento, estu_cod_reside_mcpio, cole_cod_dane_establecimiento)]
table(chequeo_reforzado3_SB11$N > 1)
sum(chequeo_reforzado3_SB11[N > 1, N]) / nrow(saber11_2014_1) * 100

chequeo_reforzado3_SaberPro <- saberpro_2016[, .N, by = .(estu_fechanacimiento, estu_genero, estu_tipodocumentosb11, estu_cod_reside_mcpio, estu_coddane_cole_termino)]
table(chequeo_reforzado3_SaberPro$N > 1)
sum(chequeo_reforzado3_SaberPro[N > 1, N]) / nrow(saberpro_2016) * 100

# Verificación de completitud: qué tan vacía está esta variable en este año,
# ya que un campo mayormente vacío anularía su poder de discriminación.
sum(saberpro_2016$estu_coddane_cole_termino == "" | is.na(saberpro_2016$estu_coddane_cole_termino))
sum(saberpro_2016$estu_coddane_cole_termino == "" | is.na(saberpro_2016$estu_coddane_cole_termino)) / nrow(saberpro_2016) * 100

# RESULTADO SB11: 16.46%. RESULTADO SaberPro 2016: 10.67% (con baja tasa de
# vacíos en este año — en años más recientes, como 2023-2024, esta variable
# desaparece del todo; ver el refuerzo alternativo más abajo en Fase 4).

## --- Refuerzo 4 (definitivo): + estrato de vivienda -----------------------
# Aunque solo tiene 6 categorías, no está correlacionado con las variables
# anteriores (dentro de un mismo municipio hay los 6 estratos), así que sí
# aporta información nueva — a diferencia de tipo de documento.

chequeo_reforzado4_SB11 <- saber11_2014_1[, .N, by = .(estu_fechanacimiento, estu_genero, estu_tipodocumento, estu_cod_reside_mcpio, cole_cod_dane_establecimiento, fami_estratovivienda)]
table(chequeo_reforzado4_SB11$N > 1)
sum(chequeo_reforzado4_SB11[N > 1, N]) / nrow(saber11_2014_1) * 100

chequeo_reforzado4_SaberPro <- saberpro_2016[, .N, by = .(estu_fechanacimiento, estu_genero, estu_tipodocumentosb11, estu_cod_reside_mcpio, estu_coddane_cole_termino, fami_estratovivienda)]
table(chequeo_reforzado4_SaberPro$N > 1)
sum(chequeo_reforzado4_SaberPro[N > 1, N]) / nrow(saberpro_2016) * 100

# RESULTADO FINAL: 7.68% (SB11) / 5.74% (SaberPro 2016).
#
# DECISIÓN DE LLAVE (Fase 3, cerrada): fecha_nacimiento + género (núcleo) +
# tipo_documento + municipio_residencia + colegio_origen + estrato_vivienda.
# estu_consecutivo queda DESCARTADO como llave (confirmado con la guía
# metodológica oficial del ICFES: es un identificador por aplicación de
# examen, no persistente entre pruebas distintas).
# Residual de colisión aceptado y documentado como limitación conocida,
# menor a la precisión del cruce oficial del ICFES (que usa documento de
# identidad + nombres + Registraduría Nacional, datos no disponibles
# públicamente).


#===============================================================================
# FASE 4 — Limpieza, estandarización e integración
#
# Frentes previstos por el HTML del proyecto: normalización de texto,
# homologación de categorías y de nombres de variables entre periodos,
# tipificación correcta de fechas/numéricos, valores centinela, distinción
# "no preguntado" vs "no respondido", códigos geográficos contra DANE.
#
# Esta sección construye la automatización de LECTURA + HOMOLOGACIÓN para
# los 24 archivos de Saber 11 y los 11 de Saber Pro dentro de la ventana
# 2014-2025. La limpieza fina (normalización de texto, valores centinela)
# queda pendiente para después de tener la tabla larga consolidada.
#===============================================================================

## ---------------------------------------------------------------------------
## 4.1 — SABER 11: diccionario de homologación y función de lectura
## ---------------------------------------------------------------------------
#
# Por qué un diccionario y no una lista fija de columnas: varias variables
# cambian de nombre a mitad de la ventana (ej. punt_lenguaje -> 
# punt_lectura_critica desde 2014-2) o aparecen/desaparecen por completo
# (fami_nivelsisben solo existe hasta 2014-1; punt_global y percentil_global
# no existen antes de 2014-2). El diccionario le dice a la función qué
# nombre técnico buscar según el periodo exacto del archivo que esté leyendo.

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

# Extrae el periodo (AAAAP, 5 dígitos) directamente del nombre del archivo,
# para que la función sepa automáticamente qué fila del diccionario aplicar.
extraer_periodo_de_nombre <- function(nombre_archivo) {
  numero <- regmatches(nombre_archivo, regexpr("[0-9]{5}", nombre_archivo))
  return(as.integer(numero))
}

# Dado el diccionario completo y el periodo de un archivo puntual, arma el
# vector con nombre (nombre_final = nombre_en_archivo) que fread() necesita
# para seleccionar y luego renombrar las columnas de ese archivo específico.
construir_especificacion <- function(diccionario, periodo_archivo) {
  filas_validas <- diccionario[periodo_desde <= periodo_archivo & periodo_hasta >= periodo_archivo]
  especificacion <- filas_validas$nombre_en_archivo
  names(especificacion) <- filas_validas$nombre_final
  return(especificacion)
}

# Función principal de lectura para un archivo de Saber 11.
# Verifica qué columnas existen REALMENTE en el archivo (no solo confía en
# el rango de periodos documentado, porque ya se comprobó que el diccionario
# oficial del ICFES puede no coincidir exactamente con los archivos reales,
# ej. percentil_global). Lo que falta se agrega como NA documentado
# (faltante estructural: "no preguntado", no "no respondido").
leer_saber11 <- function(ruta, diccionario, tipos_columna = NULL) {
  nombre_archivo <- basename(ruta)
  periodo_archivo <- extraer_periodo_de_nombre(nombre_archivo)
  
  especificacion <- construir_especificacion(diccionario, periodo_archivo)
  
  columnas_disponibles <- names(fread(file = ruta, nrows = 0, encoding = "UTF-8"))
  
  disponibles <- especificacion[especificacion %in% columnas_disponibles]
  faltantes   <- especificacion[!especificacion %in% columnas_disponibles]
  
  datos <- fread(file = ruta, select = unname(disponibles), encoding = "UTF-8", colClasses = tipos_columna)
  setnames(datos, old = unname(disponibles), new = names(disponibles))
  
  if (length(faltantes) > 0) {
    for (nombre_final_faltante in names(faltantes)) {
      datos[, (nombre_final_faltante) := NA]
    }
    cat("Archivo", nombre_archivo, "- variables no disponibles en este periodo (marcadas NA):",
        paste(names(faltantes), collapse = ", "), "\n")
  }
  
  datos[, archivo_origen := nombre_archivo]
  return(datos)
}

# Prueba de validación con un archivo "moderno" (fuera del caso especial
# 2014-1), para confirmar que el diccionario también funciona bien cuando
# no hay nombres viejos de por medio, antes de automatizar los 24 archivos.
ruta_saber11_moderno <- here("data", "raw", "Saber11", "Examen_Saber_11_20151.txt")
str(leer_saber11(ruta_saber11_moderno, diccionario_homologacion_sb11,
                 tipos_columna = c(cole_cod_dane_establecimiento = "character")))

## ---------------------------------------------------------------------------
## 4.2 — SABER 11: automatización de carga completa (ventana 2014-2025)
## ---------------------------------------------------------------------------

# Lista TODOS los archivos que sigan el patrón de nombre esperado...
archivos_sb11_todos <- list.files(
  path = here("data", "raw", "Saber11"),
  pattern = "^Examen_Saber_11_[0-9]{5}\\.txt$",
  full.names = TRUE
)

# ...pero solo nos quedamos con los que caen dentro de la ventana del
# proyecto (2014-2025). El inventario documenta variables desde 2010 como
# referencia histórica, pero el alcance del proyecto es más estrecho.
periodos_detectados <- sapply(basename(archivos_sb11_todos), extraer_periodo_de_nombre)
archivos_sb11 <- archivos_sb11_todos[periodos_detectados >= 20141 & periodos_detectados <= 20252]

archivos_sb11
length(archivos_sb11)  # esperado: 24 (12 años x 2 periodos)

# Aplica leer_saber11() a cada archivo de la lista, uno por uno.
lista_sb11 <- lapply(
  archivos_sb11,
  leer_saber11,
  diccionario = diccionario_homologacion_sb11,
  tipos_columna = c(cole_cod_dane_establecimiento = "character")
)

# Une las 24 tablas en una sola. fill = TRUE es necesario porque no todos
# los archivos tienen exactamente las mismas columnas (ej. 2014-1 no tiene
# punt_global; los periodos posteriores a 2014-1 no tienen fami_nivelsisben)
# — donde falte una columna en un archivo, queda NA para esas filas.
saber11_completo <- rbindlist(lista_sb11, fill = TRUE)

nrow(saber11_completo)                # 7,989,739 registros
table(saber11_completo$periodo)       # verificación: los 24 periodos representados

## ---------------------------------------------------------------------------
## 4.3 — SABER PRO: diccionario de homologación y función de lectura
## ---------------------------------------------------------------------------
# Mismo enfoque que Saber 11, pero el patrón de nombre de archivo usa solo
# AÑO (4 dígitos), no año+periodo — Saber Pro se reporta anual, no semestral.

extraer_anio_de_nombre_saberpro <- function(nombre_archivo) {
  numero <- regmatches(nombre_archivo, regexpr("[0-9]{4}", nombre_archivo))
  return(as.integer(numero))
}
extraer_anio_de_nombre_saberpro("Examen_Saber_Pro_Genericas_2016.txt")  # prueba: debe dar 2016

# Rangos period_desde/hasta amplios a propósito (2012-2025): igual que con
# Saber 11, no confiamos ciegamente en fechas documentadas — la función
# verifica disponibilidad real columna por columna en cada archivo.
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

# Idéntica lógica a leer_saber11(), adaptada solo en cómo detecta el periodo
# del archivo (año, no año+semestre).
leer_saberpro <- function(ruta, diccionario, tipos_columna = NULL) {
  nombre_archivo <- basename(ruta)
  anio_archivo <- extraer_anio_de_nombre_saberpro(nombre_archivo)
  
  especificacion <- construir_especificacion(diccionario, anio_archivo)
  
  columnas_disponibles <- names(fread(file = ruta, nrows = 0, encoding = "UTF-8"))
  
  disponibles <- especificacion[especificacion %in% columnas_disponibles]
  faltantes   <- especificacion[!especificacion %in% columnas_disponibles]
  
  datos <- fread(file = ruta, select = unname(disponibles), encoding = "UTF-8", colClasses = tipos_columna)
  setnames(datos, old = unname(disponibles), new = names(disponibles))
  
  if (length(faltantes) > 0) {
    for (nombre_final_faltante in names(faltantes)) {
      datos[, (nombre_final_faltante) := NA]
    }
    cat("Archivo", nombre_archivo, "- variables no disponibles:", paste(names(faltantes), collapse = ", "), "\n")
  }
  
  datos[, archivo_origen := nombre_archivo]
  return(datos)
}

# Lista y filtra archivos de Saber Pro dentro de la ventana 2014-2025.
archivos_saberpro_todos <- list.files(
  path = here("data", "raw", "SaberPro"),
  pattern = "^Examen_Saber_Pro_Genericas_[0-9]{4}\\.txt$",
  full.names = TRUE
)
anios_detectados <- sapply(basename(archivos_saberpro_todos), extraer_anio_de_nombre_saberpro)
archivos_saberpro <- archivos_saberpro_todos[anios_detectados >= 2014 & anios_detectados <= 2025]

archivos_saberpro
length(archivos_saberpro)  # 11 archivos disponibles (2014-2024; 2025 aún no publicado)

## ---------------------------------------------------------------------------
## 4.4 — SABER PRO: diagnóstico y refuerzo de llave para años recientes
## ---------------------------------------------------------------------------
# Hallazgo: en 2023-2024 desaparecen estu_coddane_cole_termino (colegio) y,
# en 2024, también estu_mcpio_reside (municipio de residencia) — dos de las
# piezas más fuertes de la llave. Sin refuerzo, la colisión en 2024 sube a
# 88.03%. Se prueban dos variables alternativas disponibles en 2024:
# municipio de PRESENTACIÓN del examen y municipio de la institución (IES).

ruta_2024 <- archivos_saberpro[archivos_saberpro %like% "2024"]

test_2024 <- fread(
  file = ruta_2024,
  select = c("estu_consecutivo", "estu_fechanacimiento", "estu_genero",
             "estu_tipodocumento", "fami_estratovivienda",
             "estu_mcpio_presentacion", "estu_inst_municipio"),
  encoding = "UTF-8"
)

# Línea base 2024 (sin colegio ni municipio de residencia): 88.03% colisión.
chequeo_2024_actual <- test_2024[, .N, by = .(estu_fechanacimiento, estu_genero, estu_tipodocumento, fami_estratovivienda)]
sum(chequeo_2024_actual[N > 1, N]) / nrow(test_2024) * 100

# Con municipio de presentación:
chequeo_2024_v1 <- test_2024[, .N, by = .(estu_fechanacimiento, estu_genero, estu_tipodocumento,
                                          fami_estratovivienda, estu_mcpio_presentacion)]
sum(chequeo_2024_v1[N > 1, N]) / nrow(test_2024) * 100

# Con municipio de la institución:
chequeo_2024_v2 <- test_2024[, .N, by = .(estu_fechanacimiento, estu_genero, estu_tipodocumento,
                                          fami_estratovivienda, estu_inst_municipio)]
sum(chequeo_2024_v2[N > 1, N]) / nrow(test_2024) * 100

# Con ambas combinadas — MEJOR RESULTADO: 26.98% (vs. 88.03% base).
chequeo_2024_v3 <- test_2024[, .N, by = .(estu_fechanacimiento, estu_genero, estu_tipodocumento,
                                          fami_estratovivienda, estu_mcpio_presentacion, estu_inst_municipio)]
sum(chequeo_2024_v3[N > 1, N]) / nrow(test_2024) * 100

# Se incorporan ambas variables al diccionario como refuerzo alternativo,
# disponible para todos los años (no solo 2024) por si hace falta en el
# cruce real de Fase 5 cuando colegio/municipio de residencia no estén.
diccionario_homologacion_saberpro <- rbindlist(list(
  diccionario_homologacion_saberpro,
  data.table(
    nombre_final = c("estu_mcpio_presentacion", "estu_inst_municipio"),
    nombre_en_archivo = c("estu_mcpio_presentacion", "estu_inst_municipio"),
    periodo_desde = c(2012, 2012),
    periodo_hasta = c(2025, 2025)
  )
))

## ---------------------------------------------------------------------------
## 4.5 — SABER PRO: carga completa definitiva (ya con refuerzo incluido)
## ---------------------------------------------------------------------------

lista_saberpro <- lapply(
  archivos_saberpro,
  leer_saberpro,
  diccionario = diccionario_homologacion_saberpro,
  tipos_columna = c(estu_coddane_cole_termino = "character",
                    inst_cod_institucion = "character")
)

saberpro_completo <- rbindlist(lista_saberpro, fill = TRUE)

nrow(saberpro_completo)              # 3,074,446 registros
table(saberpro_completo$periodo)     # verificación: los años/periodos representados

#===============================================================================
# ESTADO AL CIERRE DE ESTE BLOQUE:
#   saber11_completo   -> 7,989,739 filas, 24 periodos (2014-1 a 2025-2)
#   saberpro_completo  -> 3,074,446 filas, 11 años (2014-2024)
#
# PENDIENTE (continuación de Fase 4):
#   - Limpieza fina: normalización de texto, valores centinela,
#     tipificación de fechas, categorías homologadas.
#   - Deduplicación: primera presentación por estudiante (llave compuesta),
#     aplicada por igual a ambas pruebas.
#===============================================================================

# Para cada periodo, mira una muestra de cómo se ve estu_mcpio_reside
saber11_completo[, .(muestra = estu_mcpio_reside[1]), by = periodo]

# Revisamos si estu_cod_reside_mcpio existe en un archivo de cada punto de la ventana
readLines(here("data", "raw", "Saber11", "Examen_Saber_11_20141.txt"), n = 1) |> grepl("estu_cod_reside_mcpio", x = _)
readLines(here("data", "raw", "Saber11", "Examen_Saber_11_20252.txt"), n = 1) |> grepl("estu_cod_reside_mcpio", x = _)

saber11_completo[, .(muestra = estu_mcpio_reside[1]), by = periodo]

saber11_completo[, .(muestra_fecha = estu_fechanacimiento[1]), by = periodo]
saberpro_completo[, .(muestra_fecha = estu_fechanacimiento[1]), by = periodo]


saber11_completo[, estu_fechanacimiento := as.IDate(estu_fechanacimiento, format = "%d/%m/%Y")]
saberpro_completo[, estu_fechanacimiento := as.IDate(estu_fechanacimiento, format = "%d/%m/%Y")]

sum(is.na(saber11_completo$estu_fechanacimiento))
sum(is.na(saberpro_completo$estu_fechanacimiento))

saber11_completo[is.na(estu_fechanacimiento), .N, by = archivo_origen]
saberpro_completo[is.na(estu_fechanacimiento), .N, by = archivo_origen]

# Recargar solo la fecha cruda de 2016, sin convertir, para inspeccionar
ruta_2016 <- here("data", "raw", "SaberPro", "Examen_Saber_Pro_Genericas_2016.txt")
fechas_2016 <- fread(file = ruta_2016, select = "estu_fechanacimiento", encoding = "UTF-8")

# ¿Cómo se ven las fechas que fallaron al convertir?
fechas_crudas_problema <- fechas_2016[as.IDate(estu_fechanacimiento, format = "%d/%m/%Y") |> is.na()]
table(fechas_crudas_problema$estu_fechanacimiento)

# Cuántas celdas están realmente vacías (texto vacío) en la columna cruda completa de 2016
sum(fechas_2016$estu_fechanacimiento == "")

# NOTA: 913 casos de estu_fechanacimiento vacío en Saber Pro 2016 (de 245,181
# registros) corresponden a campo "no respondido" por el estudiante, no a un
# problema de formato ni de tipificación. Verificado contra el dato crudo.
# Categoría: "no respondido", distinta de "no preguntado" (ej. percentil_global
# en 2014-1, que no existía como variable).


str(saber11_completo[, .(punt_sociales_ciudadanas, punt_ingles, punt_lectura_critica, punt_matematicas, punt_c_naturales, punt_global)])
str(saberpro_completo[, .(punt_sociales_ciudadanas, punt_ingles, punt_lectura_critica, punt_matematicas, punt_comuni_escrita, punt_global, percentil_global)])

saberpro_completo[, .(min = min(punt_lectura_critica, na.rm = TRUE),
                      max = max(punt_lectura_critica, na.rm = TRUE),
                      promedio = mean(punt_lectura_critica, na.rm = TRUE)),
                  by = periodo][order(periodo)]

encabezado_2014 <- readLines(here("data", "raw", "SaberPro", "Examen_Saber_Pro_Genericas_2014.txt"), n = 1)
grepl("recaf|recalif|escala", encabezado_2014, ignore.case = TRUE)

# Si da TRUE, veamos exactamente qué nombre tiene:
strsplit(encabezado_2014, ";")[[1]][grepl("lectura|recaf|recalif", strsplit(encabezado_2014, ";")[[1]], ignore.case = TRUE)]

saberpro_completo[, puntaje_escala_comparable := periodo >= 20162]

# ¿Existe la columna nueva?
names(saberpro_completo)

# ¿Tiene los valores esperados? (FALSE antes de 2016-2, TRUE desde ahí)
table(saberpro_completo$periodo, saberpro_completo$puntaje_escala_comparable)
#==================================================================================================================

table(saber11_completo$fami_estratovivienda, useNA = "always")
table(saber11_completo$fami_nivelsisben, useNA = "always")
table(saber11_completo$estu_tipodocumento, useNA = "always")

table(saberpro_completo$fami_estratovivienda, useNA = "always")
table(saberpro_completo$fami_nivel_sisben, useNA = "always")

# "Sin Estrato" -> NA explícito (valor centinela, no información real)
saber11_completo[fami_estratovivienda == "Sin Estrato", fami_estratovivienda := NA]
saberpro_completo[fami_estratovivienda == "Sin Estrato", fami_estratovivienda := NA]

# Texto vacío -> NA explícito (Saber Pro)
saberpro_completo[fami_estratovivienda == "", fami_estratovivienda := NA]

saberpro_completo[fami_estratovivienda == "Estrato 0", .N, by = archivo_origen]

saberpro_completo[fami_estratovivienda == "Estrato 0", fami_estratovivienda := NA]

# "Estrato 0" (2016-2017, n=1726) tratado como valor centinela: no existe
# oficialmente en el sistema de estratificación colombiano (rango real 1-6).
# No se encontró documentación oficial del ICFES que lo defina como categoría
# válida — decisión tomada por ausencia de evidencia en contra, no por
# confirmación directa. Documentado como limitación de certeza en el informe.
#===================================================================================

saber11_completo[, .(valores = paste(unique(estu_genero), collapse = " | ")), by = periodo]

sum(saber11_completo$estu_genero == "")
saber11_completo[estu_genero == "", .N, by = archivo_origen]

saber11_completo[estu_genero == "", estu_genero := NA]

saberpro_completo[, .(valores = paste(unique(estu_genero), collapse = " | ")), by = periodo]

sum(saberpro_completo$estu_genero == "")
saberpro_completo[estu_genero == "", .N, by = archivo_origen]

saberpro_completo[estu_genero == "", estu_genero := NA]

saber11_completo[, .(valores = paste(unique(fami_estratovivienda), collapse = " | ")), by = periodo]

saberpro_completo[, .(valores = paste(unique(fami_estratovivienda), collapse = " | ")), by = periodo]

## --- Valores centinela restantes (texto vacío) ------------------------------
saber11_completo[estu_genero == "", estu_genero := NA]
saberpro_completo[estu_genero == "", estu_genero := NA]
saber11_completo[fami_estratovivienda == "", fami_estratovivienda := NA]
saberpro_completo[fami_estratovivienda == "", fami_estratovivienda := NA]

sum(saber11_completo$estu_genero == "", na.rm = TRUE)
sum(saberpro_completo$estu_genero == "", na.rm = TRUE)
sum(saber11_completo$fami_estratovivienda == "", na.rm = TRUE)
sum(saberpro_completo$fami_estratovivienda == "", na.rm = TRUE)

## --- Chequeo automatizado de homologación de categorías ---------------------
# Compara el número de categorías únicas contra el número de categorías únicas
# después de normalizar mayúsculas/espacios. Si difieren, hay inconsistencia
# de escritura entre periodos que debe corregirse.
verificar_homologacion <- function(tabla, columnas) {
  for (col in columnas) {
    if (col %in% names(tabla)) {
      x <- tabla[[col]]
      n_original <- length(unique(x))
      n_normalizado <- length(unique(toupper(trimws(x))))
      if (n_original != n_normalizado) {
        cat("INCONSISTENCIA en", col, "- únicos:", n_original, "| normalizados:", n_normalizado, "\n")
      } else {
        cat("OK:", col, "- sin inconsistencias de formato\n")
      }
    }
  }
}

cat("--- Saber 11 ---\n")
verificar_homologacion(saber11_completo, c("estu_tipodocumento", "estu_genero",
                                           "fami_estratovivienda", "fami_nivelsisben"))
cat("--- Saber Pro ---\n")
verificar_homologacion(saberpro_completo, c("estu_tipodocumento", "estu_genero",
                                            "fami_estratovivienda", "fami_nivel_sisben",
                                            "inst_nombre_institucion"))

verificar_homologacion(saber11_completo, c("estu_tipodocumento", "estu_genero",
                                           "fami_estratovivienda", "fami_nivelsisben"))

verificar_homologacion(saberpro_completo, c("estu_tipodocumento", "estu_genero",
                                            "fami_estratovivienda", "fami_nivel_sisben",
                                            "inst_nombre_institucion"))

saberpro_completo[, inst_nombre_institucion := toupper(trimws(gsub("\\s+", " ", inst_nombre_institucion)))]

## --- Normalización de texto libre (nombres de institución) ------------------
# Único campo de texto libre en la base final; se estandariza mayúsculas y
# espacios para reducir duplicados aparentes por formato inconsistente.
saberpro_completo[, inst_nombre_institucion := toupper(trimws(gsub("\\s+", " ", inst_nombre_institucion)))]

sum(saberpro_completo$estu_tipodocumento == "")
saberpro_completo[estu_tipodocumento == "", .N, by = archivo_origen]

sum(saberpro_completo$estu_tipodocumentosb11 == "")
saberpro_completo[estu_tipodocumentosb11 == "", .N, by = archivo_origen]


saber11_completo <- saber11_completo[
  order(periodo),
  .SD[1],
  by = .(estu_fechanacimiento, estu_genero, estu_tipodocumento,
         estu_mcpio_reside, cole_cod_dane_establecimiento, fami_estratovivienda)
]

nrow(saber11_completo)

saberpro_completo <- saberpro_completo[
  order(periodo),
  .SD[1],
  by = .(estu_fechanacimiento, estu_genero, estu_tipodocumentosb11,
         estu_mcpio_reside, estu_coddane_cole_termino, fami_estratovivienda,
         estu_mcpio_presentacion, estu_inst_municipio)
]

nrow(saberpro_completo)
table(saberpro_completo$periodo)

# La deduplicación inicial (sin variables de refuerzo) generaba pérdida
# artificial en 2023-2024 y 2016-2, porque data.table agrupa NA==NA como
# "iguales" al usar by= — estudiantes distintos con colegio/municipio
# de residencia faltantes (documentado en Fase 4) se fusionaban por error.
# Se corrigió agregando estu_mcpio_presentacion y estu_inst_municipio
# (mismo refuerzo ya usado para la llave de vinculación) al agrupamiento
# de deduplicación. Verificado: caída en 2024 pasó de 65-84% a 13-29%,
# consistente con el resto de la serie.

# Preserva el tipo de documento ACTUAL de Saber Pro con otro nombre, antes de
# liberar "estu_tipodocumento" para que sea el nombre común de la llave
setnames(saberpro_completo, "estu_tipodocumento", "estu_tipodocumento_actual_sbpro")
setnames(saberpro_completo, "estu_tipodocumentosb11", "estu_tipodocumento")
setnames(saberpro_completo, "estu_coddane_cole_termino", "cole_cod_dane_establecimiento")

#===============================================================================
# Cruce Saber11-SaberPro con llave condicional por periodo (parametrizada)
#===============================================================================

llave_estandar_sb11  <- config$llave_cruce$estandar$saber11
llave_estandar_spro  <- config$llave_cruce$estandar$saberpro
llave_reforzada_sb11 <- config$llave_cruce$reforzada$saber11
llave_reforzada_spro <- config$llave_cruce$reforzada$saberpro
periodo_ref_desde    <- config$llave_cruce$periodo_reforzada_desde
periodo_ref_hasta    <- config$llave_cruce$periodo_reforzada_hasta


# --- Fail-fast: las dos listas de cada llave deben tener el mismo largo ---
if (length(llave_estandar_sb11) != length(llave_estandar_spro)) {
  stop("La llave estandar tiene distinto numero de columnas entre saber11 y saberpro en config.yml.")
}
if (length(llave_reforzada_sb11) != length(llave_reforzada_spro)) {
  stop("La llave reforzada tiene distinto numero de columnas entre saber11 y saberpro en config.yml.")
}


# --- Fail-fast: las columnas de cada llave deben existir en su tabla ---
validar_columnas_llave <- function(datos, columnas, nombre_tabla) {
  faltantes <- setdiff(columnas, names(datos))
  if (length(faltantes) > 0) {
    stop(sprintf("[%s] Faltan columnas de la llave de cruce: %s", nombre_tabla, paste(faltantes, collapse = ", ")))
  }
}
validar_columnas_llave(saber11_completo, llave_estandar_sb11, "saber11_completo (estandar)")
validar_columnas_llave(saberpro_completo, llave_estandar_spro, "saberpro_completo (estandar)")
validar_columnas_llave(saber11_completo, llave_reforzada_sb11, "saber11_completo (reforzada)")
validar_columnas_llave(saberpro_completo, llave_reforzada_spro, "saberpro_completo (reforzada)")

# --- Partición de Saber Pro según qué tramo de periodo le corresponde ---
saberpro_estandar  <- saberpro_completo[periodo < periodo_ref_desde | periodo > periodo_ref_hasta]
saberpro_reforzada <- saberpro_completo[periodo >= periodo_ref_desde & periodo <= periodo_ref_hasta]

escribir_log(sprintf(
  "Particion Saber Pro para cruce: %d con llave estandar, %d con llave reforzada (periodos %s-%s).",
  nrow(saberpro_estandar), nrow(saberpro_reforzada), periodo_ref_desde, periodo_ref_hasta
), log_file = ruta_log)

# --- Cruce 1: llave estándar ---
base_cruzada_estandar <- merge(
  saber11_completo, saberpro_estandar,
  by.x = llave_estandar_sb11, by.y = llave_estandar_spro,
  suffixes = c("_saber11", "_saberpro"),
  all = FALSE
)
base_cruzada_estandar[, llave_reforzada_usada := FALSE]

# --- Cruce 2: llave reforzada (2023-2024) ---
base_cruzada_reforzada <- merge(
  saber11_completo, saberpro_reforzada,
  by.x = llave_reforzada_sb11, by.y = llave_reforzada_spro,
  suffixes = c("_saber11", "_saberpro"),
  all = FALSE
)
base_cruzada_reforzada[, llave_reforzada_usada := TRUE]

# --- Unión final ---
base_cruzada <- rbindlist(list(base_cruzada_estandar, base_cruzada_reforzada), fill = TRUE)

escribir_log(sprintf(
  "Cruce completado: %d registros totales (%d con llave estandar, %d con llave reforzada).",
  nrow(base_cruzada), nrow(base_cruzada_estandar), nrow(base_cruzada_reforzada)
), log_file = ruta_log)

conteo_llave <- base_cruzada[, .N, by = llave_cruce]
table(conteo_llave$N)

diccionario_homologacion_sb11[nombre_final == "estu_mcpio_presentacion" | nombre_en_archivo %like% "mcpio_presentacion"]
diccionario_homologacion_saberpro[nombre_final == "estu_mcpio_presentacion" | nombre_en_archivo %like% "mcpio_presentacion"]

nrow(base_cruzada)
table(base_cruzada$llave_reforzada_usada)

table(saber11_completo$estu_genero, saber11_completo$periodo)
table(saber11_completo$punt_sociales_ciudadanas, saber11_completo$periodo)

# ¿cómo vienen tus códigos reales del ICFES?
saber11_completo[, .N, by = nchar(estu_mcpio_reside)]

saber11_completo[nchar(estu_mcpio_reside) == 4, unique(estu_cod_reside_depto)][1:10]
saber11_completo[nchar(estu_mcpio_reside) == 9, unique(estu_mcpio_reside)][1:10]
saber11_completo[nchar(estu_mcpio_reside) == 11, unique(estu_mcpio_reside)][1:10]





saber11_completo[, .N, by = nchar(estu_cod_reside_mcpio)]
saber11_completo[, .N, by = nchar(estu_cod_reside_depto)]

# ¿cuántas filas de cada lado por combinación de llave? si el máximo es muy
# alto, el merge puede estar generando muchas más filas de las esperadas
saber11_completo[, .N, by = mget(config$llave_cruce$estandar$saber11)][, max(N)]
saberpro_completo[, .N, by = mget(config$llave_cruce$estandar$saberpro)][, max(N)]

# Encuentra cuál combinación específica tiene 37 repeticiones
grupos_spro <- saberpro_completo[, .N, by = mget(config$llave_cruce$estandar$saberpro)]
grupo_sospechoso <- grupos_spro[N == 37]
print(grupo_sospechoso)

# Mira esas 37 filas completas — ¿son la misma persona presentando en distintos
# periodos (legítimo), o hay algo raro (fechas de nacimiento idénticas por
# coincidencia real, o un valor centinela colándose como si fuera un valor real)?
saberpro_completo[grupo_sospechoso, on = config$llave_cruce$estandar$saberpro][, .(periodo, estu_consecutivo)]


table(conteo_identidad$N)
grupo_228 <- conteo_identidad[N == 228]
base_cruzada[grupo_228, on = names(grupo_228)[1:6]][, .(cole_cod_dane_establecimiento, periodo_saber11, periodo_saberpro)][1:5]

######################################3
setdiff(names(base_cruzada), NOMBRES_DEL_DICCIONARIO)  # columnas que tienes y no documenté






# Segmenta la verificación según qué llave produjo cada fila
conteo_identidad_estandar <- base_cruzada[llave_reforzada_usada == FALSE, .N,
                                          by = .(estu_fechanacimiento, estu_genero, estu_tipodocumento,
                                                 estu_cod_reside_mcpio, cole_cod_dane_establecimiento, fami_estratovivienda)]

conteo_identidad_reforzada <- base_cruzada[llave_reforzada_usada == TRUE, .N,
                                           by = .(estu_fechanacimiento, estu_genero, estu_tipodocumento,
                                                  fami_estratovivienda, estu_mcpio_presentacion_saber11)]  # ajusta el nombre exacto si quedó distinto

print(table(conteo_identidad_estandar$N))
print(table(conteo_identidad_reforzada$N))





nrow(base_cruzada)
ncol(base_cruzada)

matriz_cobertura
dim(matriz_cobertura)

tasa_vinculacion[order(periodo)]


base_cruzada[, .N, by = rezago_anios][order(rezago_anios)]


unique(saberpro_completo$periodo)[1:20]
saberpro_completo[, .N, by = nchar(as.character(periodo))]

