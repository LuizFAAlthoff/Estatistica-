# =============================================================================
# 03_preparar_dados.R — limpeza e transformação da base mensal (EAP 4.1–4.4)
#
# Como usar (a partir da pasta raiz do repositório, depois do 02_base_mensal.R):
#   Rscript R/03_preparar_dados.R
#
# Lê as cópias de trabalho em data/processed/ (D28, D29):
#   ena_mensal.csv          ENA bruta média mensal da bacia GRANDE
#   oni_mensal.csv          ONI pelo mês central do trimestre
#   inmet_estacao_mes.csv   chuva, temperatura, umidade e horas válidas/mês
#
# Grava em data/processed/:
#   base_analitica.csv      base mensal limpa e transformada (treino + teste)
#   base_analitica.rds      mesma base em formato nativo R
#
# Regras aplicadas: D08, D26, D30–D38. Os 12 meses de teste (2025-11 a 2026-10)
# recebem as mesmas transformações, mas nenhum parâmetro é estimado neles e
# nenhum valor do teste é exibido (D30).
# =============================================================================

INICIO_HIST    <- "2009-01"  # histórico extra para defasagens (D31)
INICIO_MODELO  <- "2010-01"  # início oficial da série modelada (D26)
FIM_TREINO     <- "2025-10"  # limite do conjunto de treino (D30)
FIM_TESTE      <- "2026-10"  # último mês completo do teste (D08, D26)
MIN_COMPLETUDE <- 0.75       # mínimo de 75% de horas válidas no mês (D36)

if (!file.exists("EAP.md")) {
  stop("Rode este script a partir da pasta raiz do repositório (onde está o EAP.md).")
}

# --- Funções auxiliares e de transformação (EAP 4.4) -------------------------

grava <- function(d, nome) {
  write.csv(d, file.path("data/processed", nome), row.names = FALSE, fileEncoding = "UTF-8")
  message("  gravado data/processed/", nome, " (", nrow(d), " linhas)")
}

defasar <- function(x, k) {
  c(rep(NA, k), head(x, length(x) - k))
}

limpar_ena <- function(df, inicio, fim) {
  df <- df[df$ano_mes >= inicio & df$ano_mes <= fim, ]
  df <- df[!duplicated(df$ano_mes), c("ano_mes", "ena_mwmed")]
  df$ena_mwmed[!is.na(df$ena_mwmed) & df$ena_mwmed <= 0] <- NA  # D37
  df
}

limpar_oni <- function(df, inicio, fim) {
  df <- df[df$ano_mes >= inicio & df$ano_mes <= fim, ]
  df[!duplicated(df$ano_mes), c("ano_mes", "oni")]
}

limpar_agregar_inmet <- function(df, inicio, fim, min_comp) {
  df <- df[df$ano_mes >= inicio & df$ano_mes <= fim, ]
  df <- df[!duplicated(paste(df$codigo, df$ano_mes)), ]

  # Remove apenas valores fisicamente impossíveis (preserva extremos reais, D37)
  df$precip_mm_h[!is.na(df$precip_mm_h) & df$precip_mm_h < 0] <- NA
  df$temp_c[!is.na(df$temp_c) & (df$temp_c < -15 | df$temp_c > 50)] <- NA
  df$umid_pct[!is.na(df$umid_pct) & (df$umid_pct < 0 | df$umid_pct > 100)] <- NA

  # Filtro de completude horária mínima por estação/mês (D36)
  df$precip_mm_h[(df$horas_precip / df$horas_mes) < min_comp] <- NA
  df$temp_c[(df$horas_temp / df$horas_mes) < min_comp] <- NA
  df$umid_pct[(df$horas_umid / df$horas_mes) < min_comp] <- NA

  media_valida <- function(v) if (all(is.na(v))) NA_real_ else mean(v, na.rm = TRUE)

  # Média simples entre estações válidas no mês (D35)
  out <- do.call(rbind, lapply(split(df, df$ano_mes), function(g) {
    data.frame(
      ano_mes     = g$ano_mes[1],
      precip_mm_h = media_valida(g$precip_mm_h),
      temp_c      = media_valida(g$temp_c),
      umid_pct    = media_valida(g$umid_pct),
      stringsAsFactors = FALSE
    )
  }))
  rownames(out) <- NULL
  out
}

imputar_climatologia_treino <- function(df, vars, inicio_tr, fim_tr) {
  idx_tr <- df$ano_mes >= inicio_tr & df$ano_mes <= fim_tr
  for (v in vars) {
    clim <- tapply(df[[v]][idx_tr], df$mes[idx_tr], mean, na.rm = TRUE)
    falt <- is.na(df[[v]])
    if (any(falt)) {
      df[[v]][falt] <- as.numeric(clim[as.character(df$mes[falt])])
    }
  }
  df
}

criar_defasagens <- function(df) {
  df$oni_lag4         <- defasar(df$oni, 4)          # D33
  df$oni_lag5         <- defasar(df$oni, 5)          # D33
  df$precip_mm_h_lag1 <- defasar(df$precip_mm_h, 1)  # D34
  df$precip_mm_h_lag2 <- defasar(df$precip_mm_h, 2)  # D34
  df$umid_pct_lag1    <- defasar(df$umid_pct, 1)     # D34
  df$temp_c_lag1      <- defasar(df$temp_c, 1)       # D34
  df$temp_c_lag2      <- defasar(df$temp_c, 2)       # D34
  df
}

criar_dummies_mes <- function(df) {
  # Referência: janeiro (mes == 1), D34 / D38
  for (m in 2:12) {
    df[[sprintf("mes_%02d", m)]] <- as.integer(df$mes == m)
  }
  df
}

# --- 1. Leitura das cópias de trabalho (D28) ---------------------------------
message("== Lendo bases mensais em data/processed/ ==")
ena_raw   <- read.csv("data/processed/ena_mensal.csv", stringsAsFactors = FALSE, fileEncoding = "UTF-8")
oni_raw   <- read.csv("data/processed/oni_mensal.csv", stringsAsFactors = FALSE, fileEncoding = "UTF-8")
inmet_raw <- read.csv("data/processed/inmet_estacao_mes.csv", stringsAsFactors = FALSE, fileEncoding = "UTF-8")

# --- 2. Limpeza e agregação espacial (EAP 4.1) -------------------------------
ena_limpa   <- limpar_ena(ena_raw, INICIO_MODELO, FIM_TESTE)
oni_limpo   <- limpar_oni(oni_raw, INICIO_HIST, FIM_TESTE)
inmet_bacia <- limpar_agregar_inmet(inmet_raw, INICIO_HIST, FIM_TESTE, MIN_COMPLETUDE)

# --- 3. Grade mensal contínua (2009-01 a 2026-10) e imputação (EAP 4.1) ------
datas <- seq.Date(
  from = as.Date(paste0(INICIO_HIST, "-01")),
  to   = as.Date(paste0(FIM_TESTE, "-01")),
  by   = "month"
)
d <- data.frame(ano_mes = format(datas, "%Y-%m"), stringsAsFactors = FALSE)
d <- merge(d, ena_limpa, by = "ano_mes", all.x = TRUE)
d <- merge(d, oni_limpo, by = "ano_mes", all.x = TRUE)
d <- merge(d, inmet_bacia, by = "ano_mes", all.x = TRUE)
d <- d[order(d$ano_mes), ]

d$ano <- as.integer(substr(d$ano_mes, 1, 4))
d$mes <- as.integer(substr(d$ano_mes, 6, 7))
d <- imputar_climatologia_treino(d, c("precip_mm_h", "temp_c", "umid_pct"), INICIO_MODELO, FIM_TREINO)

# --- 4. Transformações: lags, log(ENA) e dummies mensais (EAP 4.2) -----------
d <- criar_defasagens(d)

base <- d[d$ano_mes >= INICIO_MODELO & d$ano_mes <= FIM_TESTE, ]
base$conjunto <- ifelse(base$ano_mes <= FIM_TREINO, "treino", "teste")
base$log_ena  <- round(log(base$ena_mwmed), 6)  # D32

base$precip_mm_h_lag1 <- round(base$precip_mm_h_lag1, 4)
base$precip_mm_h_lag2 <- round(base$precip_mm_h_lag2, 4)
base$umid_pct_lag1    <- round(base$umid_pct_lag1, 2)
base$temp_c_lag1      <- round(base$temp_c_lag1, 2)
base$temp_c_lag2      <- round(base$temp_c_lag2, 2)

base <- criar_dummies_mes(base)

colunas_finais <- c(
  "ano_mes", "ano", "mes", "conjunto",
  "ena_mwmed", "log_ena",
  "oni_lag4", "oni_lag5",
  "precip_mm_h_lag1", "precip_mm_h_lag2",
  "umid_pct_lag1",
  "temp_c_lag1", "temp_c_lag2",
  sprintf("mes_%02d", 2:12)
)
base <- base[, colunas_finais]
rownames(base) <- NULL

# --- 5. Checagem de integridade sem expor valores do teste (D30) -------------
treino_chk <- base[base$conjunto == "treino", ]
teste_pred <- base[base$conjunto == "teste", setdiff(colunas_finais, c("ena_mwmed", "log_ena"))]

message("== Verificação da base analítica (D30) ==")
message("  Meses de treino (2010-01 a 2025-10): ", nrow(treino_chk),
        " | NAs no treino: ", sum(is.na(treino_chk)))
message("  Meses de teste  (2025-11 a 2026-10): ", nrow(teste_pred),
        " | NAs nas preditoras do teste: ", sum(is.na(teste_pred)))

stopifnot(
  nrow(base) == 202,
  sum(base$conjunto == "treino") == 190,
  sum(base$conjunto == "teste") == 12,
  sum(is.na(base)) == 0
)

# --- 6. Exportação da base analítica final (EAP 4.3) -------------------------
grava(base, "base_analitica.csv")
saveRDS(base, "data/processed/base_analitica.rds")
message("  gravado data/processed/base_analitica.rds (", nrow(base), " linhas)")
message("\nConcluído.")