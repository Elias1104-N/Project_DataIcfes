#===============================================================================
# 02_diagnostico_limpieza.R — Diagnóstico que respalda las decisiones de
# 04_limpieza.R. No forma parte del pipeline automatizado (run_all.R).
# Asume saber11_completo/saberpro_completo ya cargados en la sesión.
#===============================================================================

## --- Formato de municipio de residencia (antes de decidir usar el código) --
saber11_completo[, .(muestra = estu_mcpio_reside[1]), by = periodo]

readLines(here("data", "raw", "Saber11", "Examen_Saber_11_20141.txt"), n = 1) |> grepl("estu_cod_reside_mcpio", x = _)
readLines(here("data", "raw", "Saber11", "Examen_Saber_11_20252.txt"), n = 1) |> grepl("estu_cod_reside_mcpio", x = _)

# Verificación posterior al cambio de diccionario (ya debe mostrar códigos):
saber11_completo[, .(muestra = estu_mcpio_reside[1]), by = periodo]

## --- Formato de fecha de nacimiento -----------------------------------------
saber11_completo[, .(muestra_fecha = estu_fechanacimiento[1]), by = periodo]
saberpro_completo[, .(muestra_fecha = estu_fechanacimiento[1]), by = periodo]

## --- Verificación de NAs generados al convertir fecha -----------------------
sum(is.na(saber11_completo$estu_fechanacimiento))
sum(is.na(saberpro_completo$estu_fechanacimiento))
saber11_completo[is.na(estu_fechanacimiento), .N, by = archivo_origen]
saberpro_completo[is.na(estu_fechanacimiento), .N, by = archivo_origen]

# Investigación puntual del salto en 2016 (913 casos)
ruta_2016 <- here("data", "raw", "SaberPro", "Examen_Saber_Pro_Genericas_2016.txt")
fechas_2016 <- fread(file = ruta_2016, select = "estu_fechanacimiento", encoding = "UTF-8")
fechas_crudas_problema <- fechas_2016[as.IDate(estu_fechanacimiento, format = "%d/%m/%Y") |> is.na()]
table(fechas_crudas_problema$estu_fechanacimiento)
sum(fechas_2016$estu_fechanacimiento == "")   # RESULTADO: 913, coincide exacto

## --- Verificación de tipos de dato en puntajes -------------------------------
str(saber11_completo[, .(punt_sociales_ciudadanas, punt_ingles, punt_lectura_critica, punt_matematicas, punt_c_naturales, punt_global)])
str(saberpro_completo[, .(punt_sociales_ciudadanas, punt_ingles, punt_lectura_critica, punt_matematicas, punt_comuni_escrita, punt_global, percentil_global)])

## --- Investigación del cambio de escala en Saber Pro ------------------------
saberpro_completo[, .(min = min(punt_lectura_critica, na.rm = TRUE),
                      max = max(punt_lectura_critica, na.rm = TRUE),
                      promedio = mean(punt_lectura_critica, na.rm = TRUE)),
                  by = periodo][order(periodo)]

encabezado_2014 <- readLines(here("data", "raw", "SaberPro", "Examen_Saber_Pro_Genericas_2014.txt"), n = 1)
grepl("recaf|recalif|escala", encabezado_2014, ignore.case = TRUE)   # FALSE: no hay columna recalibrada alternativa

## --- Verificación de la columna puntaje_escala_comparable -------------------
names(saberpro_completo)
table(saberpro_completo$periodo, saberpro_completo$puntaje_escala_comparable)


## --- Diagnóstico de valores centinela: género y estrato ---------------------

# Muestra, por periodo, qué valores distintos existe en cada variable —
# permite detectar texto vacío ("") mezclado como si fuera una categoría más.
saber11_completo[, .(valores = paste(unique(estu_genero), collapse = " | ")), by = periodo]
saberpro_completo[, .(valores = paste(unique(estu_genero), collapse = " | ")), by = periodo]
saber11_completo[, .(valores = paste(unique(fami_estratovivienda), collapse = " | ")), by = periodo]
saberpro_completo[, .(valores = paste(unique(fami_estratovivienda), collapse = " | ")), by = periodo]

# Cuantifica cuántas filas tienen texto vacío, y en qué archivos se concentra
# (para distinguir "ruido disperso normal" de "problema concentrado en un año").
sum(saber11_completo$estu_genero == "")
saber11_completo[estu_genero == "", .N, by = archivo_origen]
sum(saberpro_completo$estu_genero == "")
saberpro_completo[estu_genero == "", .N, by = archivo_origen]

## --- Función de verificación automática de homologación de categorías ------
# Compara el número de categorías únicas contra el número de categorías únicas
# tras normalizar mayúsculas/espacios. Si difieren, hay inconsistencia de
# escritura entre periodos (ej. "Oficial" vs "OFICIAL") que debe corregirse.
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