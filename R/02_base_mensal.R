# =============================================================================
# 02_base_mensal.R — monta a cópia de trabalho mensal (EAP 3.1)
#
# Como usar (a partir da pasta raiz do repositório, depois do 01_baixar_dados.R):
#   Rscript R/02_base_mensal.R
#
# Lê os dados brutos de data/raw/ (sem alterá-los) e grava em data/processed/:
#   ena_mensal.csv          ENA bruta média mensal da bacia GRANDE        (D22, D05)
#   oni_mensal.csv          ONI pelo mês central do trimestre             (D24)
#   inmet_estacao_mes.csv   chuva, temperatura e umidade por estação e mês (D25, D27):
#                           MÉDIA dos valores horários do mês (chuva em mm/h);
#                           horas sem registro são ignoradas na média
#   inmet_estacoes.csv      metadados das 19 estações
#
# Nenhuma limpeza é feita aqui: meses com horas faltando NÃO são descartados nem
# imputados. Em vez disso, cada linha do INMET traz quantas horas válidas teve,
# para que a regra de completude seja decidida na etapa 4.
# =============================================================================

MES_FINAL <- "2026-10"   # último mês completo (D26)
ANOS      <- 2010:2026   # período D26 (ENA)
ANOS_INMET <- 2009:2026  # 2009 como histórico para as defasagens (D31)
# Os meses de teste (nov/2025 a out/2026, D08) recebem as mesmas transformações,
# mas não são olhados até a avaliação dos modelos (D30).

if (!file.exists("EAP.md")) {
  stop("Rode este script a partir da pasta raiz do repositório (onde está o EAP.md).")
}
dir.create("data/processed", showWarnings = FALSE, recursive = TRUE)

# Converte texto do INMET ("23,1", "-9999", "") em número, com NA nos ausentes.
num <- function(x) {
  v <- suppressWarnings(as.numeric(gsub(",", ".", x, fixed = TRUE)))
  v[!is.na(v) & v <= -9999] <- NA
  v
}
grava <- function(d, nome) {
  write.csv(d, file.path("data/processed", nome), row.names = FALSE, fileEncoding = "UTF-8")
  message("  gravado data/processed/", nome, " (", nrow(d), " linhas)")
}

# --- 1. ENA (ONS) ------------------------------------------------------------
message("== ENA ==")
ena <- do.call(rbind, lapply(ANOS, function(ano) {
  x <- read.csv2(sprintf("data/raw/ons/ENA_DIARIO_BACIAS_%d.csv", ano), dec = ".",
                 stringsAsFactors = FALSE, fileEncoding = "UTF-8")
  x[x$nom_bacia == "GRANDE", c("ena_data", "ena_bruta_bacia_mwmed")]
}))
ena$ano_mes <- substr(ena$ena_data, 1, 7)
ena <- ena[ena$ano_mes <= MES_FINAL, ]
ena_m <- aggregate(ena_bruta_bacia_mwmed ~ ano_mes, ena,
                   function(v) c(media = mean(v), n = length(v)))
ena_m <- data.frame(ano_mes = ena_m$ano_mes,
                    ena_mwmed = round(ena_m$ena_bruta_bacia_mwmed[, "media"], 2),
                    n_dias = ena_m$ena_bruta_bacia_mwmed[, "n"])
grava(ena_m, "ena_mensal.csv")

# --- 2. ONI (CPC/NOAA) -------------------------------------------------------
# Mês central: DJF -> jan, JFM -> fev, ..., NDJ -> dez. O ano de NDJ é o do
# início do trimestre (NDJ/2025 = nov/2025-jan/2026 -> dez/2025), então o ano
# de todos os trimestres já é o ano do mês central.
message("== ONI ==")
oni <- read.table("data/raw/noaa/oni.ascii.txt", header = TRUE, stringsAsFactors = FALSE)
trimestres <- c("DJF", "JFM", "FMA", "MAM", "AMJ", "MJJ", "JJA", "JAS", "ASO", "SON", "OND", "NDJ")
oni$mes <- match(oni$SEAS, trimestres)
oni_m <- data.frame(ano_mes = sprintf("%d-%02d", oni$YR, oni$mes), oni = oni$ANOM)
oni_m <- oni_m[oni_m$ano_mes >= "2000-01" & oni_m$ano_mes <= MES_FINAL, ]  # sobra antes de 2010 para as defasagens
grava(oni_m, "oni_mensal.csv")

# --- 3. INMET, estações automáticas da bacia (D25, D27) ---------------------
# Classificação aproximada aceita pelo grupo (docs/verificacao-dados.md, 3.2).
ESTACOES <- c("A708", "A516", "A515", "A530", "A531", "A514", "A525", "A520", "A529",
              "A738", "A747", "A753", "A748", "A561", "A764", "A568", "A567", "A570", "A770")

# As colunas estão sempre na mesma posição (conferido em 2010, 2019 e 2026):
# 1 data, 2 hora, 3 precipitação, 8 temperatura do ar (bulbo seco), 16 umidade relativa.
COLS <- c(precip = 3, temp = 8, umid = 16)
CONFERE <- c(precip = "^PRECIPITA", temp = "BULBO SECO", umid = "^UMIDADE RELATIVA DO AR")

message("== INMET ==")
meta <- list(); lin <- list()
for (ano in ANOS_INMET) {
  zip <- sprintf("data/raw/inmet/%d.zip", ano)
  arqs <- unzip(zip, list = TRUE)$Name
  arqs <- arqs[grepl(paste0("_(", paste(ESTACOES, collapse = "|"), ")_"), arqs)]
  message(ano, ": ", length(arqs), " estações")
  for (a in arqs) {
    txt <- readLines(unz(zip, a), encoding = "latin1", warn = FALSE)
    txt <- iconv(txt, "latin1", "UTF-8")
    cab <- sub("^[^;]*;", "", txt[1:8])
    cod <- cab[4]
    meta[[cod]] <- data.frame(codigo = cod, estacao = cab[3], uf = cab[2],
                              latitude = num(cab[5]), longitude = num(cab[6]), altitude_m = num(cab[7]))
    nomes <- strsplit(txt[9], ";", fixed = TRUE)[[1]]
    for (v in names(COLS)) {
      if (!grepl(CONFERE[v], toupper(nomes[COLS[v]]))) stop("Coluna inesperada em ", a, ": ", nomes[COLS[v]])
    }
    campos <- strsplit(txt[-(1:9)], ";", fixed = TRUE)
    campos <- campos[lengths(campos) >= 16]
    d <- data.frame(ano_mes = substr(gsub("/", "-", vapply(campos, `[`, "", 1)), 1, 7),
                    precip = num(vapply(campos, `[`, "", COLS["precip"])),
                    temp   = num(vapply(campos, `[`, "", COLS["temp"])),
                    umid   = num(vapply(campos, `[`, "", COLS["umid"])))
    d <- d[d$ano_mes <= MES_FINAL, ]
    if (nrow(d) == 0) next
    s <- do.call(rbind, lapply(split(d, d$ano_mes), function(g) data.frame(
      codigo = cod, ano_mes = g$ano_mes[1],
      precip_mm_h = if (all(is.na(g$precip))) NA else mean(g$precip, na.rm = TRUE),
      temp_c    = if (all(is.na(g$temp)))   NA else mean(g$temp,   na.rm = TRUE),
      umid_pct  = if (all(is.na(g$umid)))   NA else mean(g$umid,   na.rm = TRUE),
      horas_precip = sum(!is.na(g$precip)),
      horas_temp   = sum(!is.na(g$temp)),
      horas_umid   = sum(!is.na(g$umid)))))
    lin[[a]] <- s
  }
}
inmet <- do.call(rbind, lin)
# horas que o mês tem, para calcular a completude
ini <- as.Date(paste0(inmet$ano_mes, "-01"))
fim <- as.Date(paste0(format(ini + 31, "%Y-%m"), "-01"))
inmet$horas_mes <- as.integer(fim - ini) * 24L
inmet <- inmet[order(inmet$codigo, inmet$ano_mes), ]
inmet$precip_mm_h <- round(inmet$precip_mm_h, 4)
inmet[c("temp_c", "umid_pct")] <- lapply(inmet[c("temp_c", "umid_pct")], round, 2)
rownames(inmet) <- NULL
grava(inmet, "inmet_estacao_mes.csv")

est <- do.call(rbind, meta)
est$primeiro_mes <- tapply(inmet$ano_mes, inmet$codigo, min)[est$codigo]
est <- est[match(ESTACOES, est$codigo), ]
rownames(est) <- NULL
grava(est, "inmet_estacoes.csv")

message("\nConcluído.")
