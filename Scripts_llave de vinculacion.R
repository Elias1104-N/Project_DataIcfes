## Cargamos el paquete Here para ayudarnos a verificar la ruta de la carpeta,
## y corroborar la existencia de la ruta.

library(here)

ruta_saber11 <- here("Data", "Raw", "Saber11", "Examen_Saber_11_20141.txt")
file.exists(ruta_saber11)   # confirma que da TRUE
readLines(ruta_saber11, n = 1)

## Usamos la funcion fread del paquete data.table para seleccionar las variables,
## y dar el formato UTF - 8  a los datos.

library(data.table)
saber11_2014_1 <- fread(
  ruta_saber11,
  select = c("estu_consecutivo", "periodo", "estu_tipodocumento", 
             "estu_fechanacimiento", "estu_genero"),
  encoding = "UTF-8"
)
str(saber11_2014_1)

ruta_saberpro <- here("Data","Raw","SaberPro", 
                      "Examen_Saber_Pro_Genericas_2012.txt")
readLines(ruta_saberpro, n = 1)

saberpro_2012 <- fread(
  ruta_saberpro, select = c("estu_consecutivo", "periodo", "estu_tipodocumento", 
                            "estu_tipodocumentosb11", "estu_fechanacimiento", "estu_genero"),
  encoding = "UTF-8"
)
str(saberpro_2012)

## Ahora vamos a hacer un chequeo de unicidad para estos dos archivos para tener
## una idea de su viabilidad de una posible llave de vinculacion

chequeo_unicidadSaber11 <- saber11_2014_1[, .N, 
                                          by = .(estu_fechanacimiento, estu_genero)]

## Con el codigo anterior vemos el numero de personas que comparten el mismo
## y fecha de nacimiento para hacernos una idea de la presicion de clasificacion
## que nos puede brindar esta combinacion.

# Cuántas combinaciones son únicas (N == 1) vs. cuántas colisionan (N > 1)
combi_unicavsrepe_SB11 <- table(chequeo_unicidadSaber11$N > 1)
combi_unicavsrepe_SB11

# Qué porcentaje de TODOS los estudiantes queda en una combinación no única
porcen_colisiones_SB11 <- sum(chequeo_unicidadSaber11[N > 1, N]) / nrow(saber11_2014_1) * 100
porcen_colisiones_SB11

str(combi_unicavsrepe_SB11)
str(porcen_colisiones_SB11)  
  
## Saber Pro

chequeo_unicidadSaberPro <- saberpro_2012[, .N, 
                                          by = .(estu_fechanacimiento, estu_genero)]

combi_unicavsrepe_SaberPro <- table(chequeo_unicidadSaberPro$N > 1) 
combi_unicavsrepe_SaberPro 

porcen_colisiones_SaberPro <- sum(chequeo_unicidadSaberPro[N > 1, N]) / nrow(saberpro_2012) * 100  
porcen_colisiones_SaberPro 

## 92.65% en Saber 11 y 98.33% en Saber Pro de los estudiantes comparten su 
## combinación de fecha de nacimiento + género con al menos otra persona. Es decir, 
## la llave núcleo, sola, es prácticamente inútil,  casi todos los estudiantes tienen
## algún "gemelo" en la combinación. 

## Hay decenas de miles de estudiantes, todos con edades muy similares (nacidos en
## una ventana de 1-2 años, porque presentan el mismo examen a la misma edad), y 
## género solo tiene 2 valores posibles. Es matemáticamente esperable que haya 
## muchísimas coincidencias — no había forma de que esta combinación por sí sola 
## fuera fuerte.

## Por eso, desde el principio dijimos que fecha de nacimiento + género era el 
## núcleo obligatorio, pero que necesitaría refuerzo con tipo de documento y 
## ubicación. Este resultado confirma que el refuerzo no es opcional, es indispensable.
  
## Agregamos tipo de docuemnto a la llave

chequeo_reforzado_SB11 <- saber11_2014_1[, .N, by = .(estu_fechanacimiento, estu_genero, estu_tipodocumento)]
table(chequeo_reforzado_SB11$N > 1)
sum(chequeo_reforzado_SB11[N > 1, N]) / nrow(saber11_2014_1) * 100

chequeo_reforzado_SaberPro <- saberpro_2012[, .N, by = .(estu_fechanacimiento, estu_genero, estu_tipodocumentosb11)]
table(chequeo_reforzado_SaberPro$N > 1)
sum(chequeo_reforzado_SaberPro[N > 1, N]) / nrow(saberpro_2012) * 100


















  
  