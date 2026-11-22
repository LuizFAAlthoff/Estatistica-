# =============================================================================
# 04_modelagem.R — ajuste dos modelos candidatos no treino (EAP 5.1–5.5)
#
# Como usar (a partir da pasta raiz do repositório, depois do 03_preparar_dados.R):
#   Rscript R/04_modelagem.R
#
# Lê:
#   data/processed/base_analitica.rds
#
# Grava em output/:
#   modelos_treino.rds       lista com todos os modelos ajustados no treino
#   resumo_modelos_treino.csv  tabela comparativa de ajuste no treino (AIC, BIC, EAM, RMSE)
#
# Regra D30: usa EXCLUSIVAMENTE conjunto == "treino" (2010-01 a 2025-10, n = 190).
# O conjunto de teste não é lido, impresso nem avaliado neste script.
# =============================================================================

if (!file.exists("EAP.md")) {
  stop("Rode este script a partir da pasta raiz do repositório (onde está o EAP.md).")
}

suppressPackageStartupMessages({
  library(forecast)
})

dir.create("output", showWarnings = FALSE, recursive = TRUE)

# --- 1. Carga exclusiva do conjunto de treino (D30) --------------------------
base   <- readRDS("data/processed/base_analitica.rds")
treino <- base[base$conjunto == "treino", ]
stopifnot(nrow(treino) == 190, max(treino$ano_mes) == "2025-10")

ts_ena <- ts(treino$ena_mwmed, start = c(2010, 1), frequency = 12)
ts_log <- ts(treino$log_ena,   start = c(2010, 1), frequency = 12)

# Funções de métrica (D09) na escala original (MWmed)
calc_eam  <- function(obs, prev) mean(abs(obs - prev), na.rm = TRUE)
calc_rmse <- function(obs, prev) sqrt(mean((obs - prev)^2, na.rm = TRUE))

# Reconversão log -> MWmed com fator de correção de Smearing (evita viés de Jensen)
reconv_log <- function(ajuste_log, residuos_log) {
  smearing <- mean(exp(residuos_log), na.rm = TRUE)
  exp(ajuste_log) * smearing
}

# --- 2. Modelo de referência: Ingênuo Sazonal (D18) --------------------------
message("== Ajustando modelo de referência (Ingênuo Sazonal) ==")
mod_snaive <- snaive(ts_ena, h = 12)

# --- 3. Aula 22: Regressão Linear Múltipla (D07, D15, D17, D32–D34, D38) -----
message("== Ajustando modelos de Regressão ==")
dummies_txt <- paste(sprintf("mes_%02d", 2:12), collapse = " + ")
clima_txt   <- "precip_mm_h_lag1 + precip_mm_h_lag2 + umid_pct_lag1 + temp_c_lag1 + temp_c_lag2"
oni_txt     <- "oni_lag4 + oni_lag5"

reg_dummies   <- lm(as.formula(paste("log_ena ~", dummies_txt)), data = treino)
reg_clima     <- lm(as.formula(paste("log_ena ~", clima_txt)), data = treino)
reg_clima_oni <- lm(as.formula(paste("log_ena ~", clima_txt, "+", oni_txt)), data = treino)
reg_completa  <- lm(as.formula(paste("log_ena ~", clima_txt, "+", oni_txt, "+", dummies_txt)), data = treino)
reg_step_log  <- step(reg_completa, direction = "both", trace = 0)

# Versão na escala original (MWmed) para contraste da D32
reg_comp_orig <- lm(as.formula(paste("ena_mwmed ~", clima_txt, "+", oni_txt, "+", dummies_txt)), data = treino)
reg_step_orig <- step(reg_comp_orig, direction = "both", trace = 0)

# Testes F (ANOVA) para responder aos Objetivos 3 e 4
anova_clima_oni_vs_dummies <- anova(reg_dummies, reg_completa)
anova_oni_vs_clima         <- anova(reg_clima, reg_clima_oni)
anova_oni_vs_completa      <- anova(
  lm(as.formula(paste("log_ena ~", clima_txt, "+", dummies_txt)), data = treino),
  reg_completa
)

# --- 4. Aula 23: Suavização Exponencial (SES, Holt, HW Adit/Mult, ETS) -------
message("== Ajustando modelos de Suavização Exponencial ==")
mod_ses     <- ses(ts_ena, h = 12)
mod_holt    <- holt(ts_ena, h = 12)
mod_hw_add  <- hw(ts_ena, seasonal = "additive", h = 12)
mod_hw_mult <- hw(ts_ena, seasonal = "multiplicative", h = 12)
mod_ets     <- ets(ts_ena)
mod_ets_log <- ets(ts_log)

# --- 5. Aulas 24–25: AR(p), MA(q), ARIMA(p,d,q) e SARIMA ---------------------
message("== Ajustando modelos AR, MA, ARIMA e SARIMA ==")
# Modelos não sazonais (em log_ena) para demonstrar limitação frente à sazonalidade
mod_ar       <- auto.arima(ts_log, max.q = 0, max.d = 0, seasonal = FALSE)
mod_ma       <- auto.arima(ts_log, max.p = 0, max.d = 0, seasonal = FALSE)
mod_arima_ns <- auto.arima(ts_log, seasonal = FALSE)

# Modelos sazonais SARIMA (em log_ena e na escala original, D32)
mod_sarima_log  <- auto.arima(ts_log, seasonal = TRUE, stepwise = FALSE, approximation = FALSE)
mod_sarima_orig <- auto.arima(ts_ena, seasonal = TRUE, stepwise = FALSE, approximation = FALSE)

# --- 6. Tabela comparativa de ajuste no treino (escala MWmed) ----------------
obs <- as.numeric(ts_ena)

extrai_linha <- function(nome, familia, fitted_mw, aic_val = NA, bic_val = NA, obs_nota = "") {
  data.frame(
    modelo      = nome,
    familia     = familia,
    AIC         = round(aic_val, 2),
    BIC         = round(bic_val, 2),
    EAM_treino  = round(calc_eam(obs, as.numeric(fitted_mw)), 2),
    RMSE_treino = round(calc_rmse(obs, as.numeric(fitted_mw)), 2),
    observacao  = obs_nota,
    stringsAsFactors = FALSE
  )
}

resumo <- rbind(
  extrai_linha("Ingênuo Sazonal (snaive)", "Referência", fitted(mod_snaive), NA, NA, "Régua mínima (D18)"),
  extrai_linha("Regressão: Só Dummies (log)", "Regressão",
               reconv_log(fitted(reg_dummies), residuals(reg_dummies)), AIC(reg_dummies), BIC(reg_dummies), "Sazonalidade pura"),
  extrai_linha("Regressão: Só Clima (log)", "Regressão",
               reconv_log(fitted(reg_clima), residuals(reg_clima)), AIC(reg_clima), BIC(reg_clima), "INMET defasado"),
  extrai_linha("Regressão: Clima + ONI (log)", "Regressão",
               reconv_log(fitted(reg_clima_oni), residuals(reg_clima_oni)), AIC(reg_clima_oni), BIC(reg_clima_oni), "INMET + ONI"),
  extrai_linha("Regressão: Stepwise AIC (log)", "Regressão",
               reconv_log(fitted(reg_step_log), residuals(reg_step_log)), AIC(reg_step_log), BIC(reg_step_log), "Modelo selecionado (D17/D32)"),
  extrai_linha("Regressão: Stepwise AIC (MWmed)", "Regressão",
               fitted(reg_step_orig), AIC(reg_step_orig), BIC(reg_step_orig), "Escala original"),
  extrai_linha("SES (Simples)", "Suavização", fitted(mod_ses), mod_ses$model$aic, mod_ses$model$bic, "Sem tendência/sazonalidade"),
  extrai_linha("Holt", "Suavização", fitted(mod_holt), mod_holt$model$aic, mod_holt$model$bic, "Sem sazonalidade"),
  extrai_linha("Holt-Winters Aditivo", "Suavização", fitted(mod_hw_add), mod_hw_add$model$aic, mod_hw_add$model$bic, "Sazonalidade constante"),
  extrai_linha("Holt-Winters Multiplicativo", "Suavização", fitted(mod_hw_mult), mod_hw_mult$model$aic, mod_hw_mult$model$bic, "Sazonalidade proporcional"),
  extrai_linha(paste0("ETS (", mod_ets$method, ")"), "Suavização", fitted(mod_ets), AIC(mod_ets), BIC(mod_ets), "Automático (MWmed)"),
  extrai_linha(paste0("ETS log (", mod_ets_log$method, ")"), "Suavização",
               reconv_log(fitted(mod_ets_log), residuals(mod_ets_log)), AIC(mod_ets_log), BIC(mod_ets_log), "Automático (log)"),
  extrai_linha(paste0("AR (", paste(arimaorder(mod_ar), collapse = ","), ") [log]"), "Box-Jenkins",
               reconv_log(fitted(mod_ar), residuals(mod_ar)), AIC(mod_ar), BIC(mod_ar), "Não sazonal"),
  extrai_linha(paste0("MA (", paste(arimaorder(mod_ma), collapse = ","), ") [log]"), "Box-Jenkins",
               reconv_log(fitted(mod_ma), residuals(mod_ma)), AIC(mod_ma), BIC(mod_ma), "Não sazonal"),
  extrai_linha(paste0("ARIMA (", paste(arimaorder(mod_arima_ns), collapse = ","), ") [log]"), "Box-Jenkins",
               reconv_log(fitted(mod_arima_ns), residuals(mod_arima_ns)), AIC(mod_arima_ns), BIC(mod_arima_ns), "Não sazonal"),
  extrai_linha(paste0("SARIMA ", capture.output(mod_sarima_log)[2], " [log]"), "Box-Jenkins",
               reconv_log(fitted(mod_sarima_log), residuals(mod_sarima_log)), AIC(mod_sarima_log), BIC(mod_sarima_log), "Sazonal (log)"),
  extrai_linha(paste0("SARIMA ", capture.output(mod_sarima_orig)[2], " [MWmed]"), "Box-Jenkins",
               fitted(mod_sarima_orig), AIC(mod_sarima_orig), BIC(mod_sarima_orig), "Sazonal (MWmed)")
)

# --- 7. Salvar saídas --------------------------------------------------------
modelos <- list(
  snaive        = mod_snaive,
  reg_dummies   = reg_dummies,
  reg_clima     = reg_clima,
  reg_clima_oni = reg_clima_oni,
  reg_completa  = reg_completa,
  reg_step_log  = reg_step_log,
  reg_step_orig = reg_step_orig,
  anovas        = list(
    clima_oni_vs_dummies = anova_clima_oni_vs_dummies,
    oni_vs_clima         = anova_oni_vs_clima,
    oni_vs_completa      = anova_oni_vs_completa
  ),
  ses           = mod_ses,
  holt          = mod_holt,
  hw_add        = mod_hw_add,
  hw_mult       = mod_hw_mult,
  ets           = mod_ets,
  ets_log       = mod_ets_log,
  ar            = mod_ar,
  ma            = mod_ma,
  arima_ns      = mod_arima_ns,
  sarima_log    = mod_sarima_log,
  sarima_orig   = mod_sarima_orig
)

saveRDS(modelos, "output/modelos_treino.rds")
write.csv(resumo, "output/resumo_modelos_treino.csv", row.names = FALSE, fileEncoding = "UTF-8")

message("Concluído! Modelos salvos em output/modelos_treino.rds e resumo em output/resumo_modelos_treino.csv.")
