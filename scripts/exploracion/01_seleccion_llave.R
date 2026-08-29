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


chequeo_reforzado_SB11 <- saber11_2014_1[, .N, by = .(estu_fechanacimiento, estu_genero, estu_tipodocumento)]
table(chequeo_reforzado_SB11$N > 1)
sum(chequeo_reforzado_SB11[N > 1, N]) / nrow(saber11_2014_1) * 100

chequeo_reforzado_SaberPro <- saberpro_2016[, .N, by = .(estu_fechanacimiento, estu_genero, estu_tipodocumentosb11)]
table(chequeo_reforzado_SaberPro$N > 1)
sum(chequeo_reforzado_SaberPro[N > 1, N]) / nrow(saberpro_2016) * 100


chequeo_reforzado2_SB11 <- saber11_2014_1[, .N, by = .(estu_fechanacimiento, estu_genero, estu_tipodocumento, estu_cod_reside_mcpio)]
table(chequeo_reforzado2_SB11$N > 1)
sum(chequeo_reforzado2_SB11[N > 1, N]) / nrow(saber11_2014_1) * 100

chequeo_reforzado2_SaberPro <- saberpro_2016[, .N, by = .(estu_fechanacimiento, estu_genero, estu_tipodocumentosb11, estu_cod_reside_mcpio)]
table(chequeo_reforzado2_SaberPro$N > 1)
sum(chequeo_reforzado2_SaberPro[N > 1, N]) / nrow(saberpro_2016) * 100


chequeo_reforzado3_SB11 <- saber11_2014_1[, .N, by = .(estu_fechanacimiento, estu_genero, estu_tipodocumento, estu_cod_reside_mcpio, cole_cod_dane_establecimiento)]
table(chequeo_reforzado3_SB11$N > 1)
sum(chequeo_reforzado3_SB11[N > 1, N]) / nrow(saber11_2014_1) * 100

chequeo_reforzado3_SaberPro <- saberpro_2016[, .N, by = .(estu_fechanacimiento, estu_genero, estu_tipodocumentosb11, estu_cod_reside_mcpio, estu_coddane_cole_termino)]
table(chequeo_reforzado3_SaberPro$N > 1)
sum(chequeo_reforzado3_SaberPro[N > 1, N]) / nrow(saberpro_2016) * 100



sum(saberpro_2016$estu_coddane_cole_termino == "" | is.na(saberpro_2016$estu_coddane_cole_termino))
sum(saberpro_2016$estu_coddane_cole_termino == "" | is.na(saberpro_2016$estu_coddane_cole_termino)) / nrow(saberpro_2016) * 100



chequeo_reforzado4_SB11 <- saber11_2014_1[, .N, by = .(estu_fechanacimiento, estu_genero, estu_tipodocumento, estu_cod_reside_mcpio, cole_cod_dane_establecimiento, fami_estratovivienda)]
table(chequeo_reforzado4_SB11$N > 1)
sum(chequeo_reforzado4_SB11[N > 1, N]) / nrow(saber11_2014_1) * 100

chequeo_reforzado4_SaberPro <- saberpro_2016[, .N, by = .(estu_fechanacimiento, estu_genero, estu_tipodocumentosb11, estu_cod_reside_mcpio, estu_coddane_cole_termino, fami_estratovivienda)]
table(chequeo_reforzado4_SaberPro$N > 1)
sum(chequeo_reforzado4_SaberPro[N > 1, N]) / nrow(saberpro_2016) * 100
