#===============================================================================
# 04_limpieza.R — Tipificación y estandarización (Fase 4)
# Requiere: saber11_completo, saberpro_completo ya cargados (ver 03_cargar_datos.R)
#===============================================================================

## --- Tipificación de fechas -------------------------------------------------
saber11_completo[, estu_fechanacimiento := as.IDate(estu_fechanacimiento, format = "%d/%m/%Y")]
saberpro_completo[, estu_fechanacimiento := as.IDate(estu_fechanacimiento, format = "%d/%m/%Y")]

# NOTA: 913 casos de estu_fechanacimiento vacío en Saber Pro 2016 (de 245,181
# registros) corresponden a campo "no respondido" por el estudiante, no a un
# problema de formato ni de tipificación. Verificado contra el dato crudo
# (ver scripts/exploracion/02_diagnostico_limpieza.R).
# Categoría: "no respondido", distinta de "no preguntado" (ej. percentil_global
# en 2014-1, que no existía como variable). Otros ~17-40 casos por archivo en
# el resto de periodos son ruido normal de captura, sin patrón de concentración.

## --- Marca de comparabilidad de escala en puntajes Saber Pro ---------------
# El ICFES cambió la escala de calificación de Saber Pro en 2016 (de un rango
# aprox. 0-20 a 0-300), confirmado por la Resolución 455 de 2016: "las escalas
# de calificación... serán las producidas para la primera aplicación 2016...
# la línea de base... se construirá a partir de 2016". Confirmado también
# empíricamente (salto abrupto de min/max/promedio en el periodo 20162) y
# descartada la existencia de una columna recalibrada alternativa en años
# anteriores (ver scripts/exploracion/02_diagnostico_limpieza.R).
# Aplica a todos los módulos genéricos, no solo lectura crítica, porque fue
# un cambio de metodología de calificación completo (modelo TRI 3 parámetros).

saberpro_completo[, puntaje_escala_comparable := periodo >= 20162]


## --- Valores centinela: texto vacío en género y estrato --------------------

# "Sin Estrato" -> NA explícito (valor centinela, no información socioeconómica real)
saber11_completo[fami_estratovivienda == "Sin Estrato", fami_estratovivienda := NA]
saberpro_completo[fami_estratovivienda == "Sin Estrato", fami_estratovivienda := NA]


# "Estrato 0" (Saber Pro 2016-2017, n=1,726) tratado como valor centinela: no
# existe oficialmente en el sistema de estratificación colombiano (rango 1-6).
# No se encontró documentación oficial del ICFES que lo defina como categoría
# válida — decisión tomada por ausencia de evidencia en contra, no por
# confirmación directa. Documentado como limitación de certeza en el informe.

saberpro_completo[fami_estratovivienda == "Estrato 0", fami_estratovivienda := NA]

# Texto vacío ("") en estas variables significa "no respondido", no una
# categoría válida. Se convierte a NA explícito. Verificado en
# scripts/exploracion/02_diagnostico_limpieza.R.
saber11_completo[estu_tipodocumento == "", estu_tipodocumento := NA]
saberpro_completo[estu_tipodocumento == "", estu_tipodocumento := NA]

# estu_tipodocumentosb11 vacío es más frecuente de lo esperado (29,682 casos
# en 2014, decreciendo a ~4,000-8,000/año en periodos posteriores) — no es
# ruido disperso, representa una limitación real de la llave de vinculación
# para esos estudiantes específicos (menor refuerzo disponible). Se convierte
# a NA para tratamiento consistente; el impacto en la tasa de colisión de la
# llave debe evaluarse en Fase 5 al ejecutar el cruce real.

saberpro_completo[estu_tipodocumentosb11 == "", estu_tipodocumentosb11 := NA]

saber11_completo[estu_genero == "", estu_genero := NA]
saberpro_completo[estu_genero == "", estu_genero := NA]
saber11_completo[fami_estratovivienda == "", fami_estratovivienda := NA]
saberpro_completo[fami_estratovivienda == "", fami_estratovivienda := NA]

## --- Normalización de texto libre (nombre de institución, Saber Pro) -------
# Único campo de texto libre en la base final: colapsa espacios múltiples,
# quita espacios al inicio/final, y unifica mayúsculas — evita que la misma
# institución cuente como "distinta" solo por diferencias de formato.
saberpro_completo[, inst_nombre_institucion := toupper(trimws(gsub("\\s+", " ", inst_nombre_institucion)))]





