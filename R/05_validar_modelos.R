# =============================================================================
# 05_validar_modelos.R — diagnóstico, robustez e avaliação no teste (EAP 6.1–6.6)
#
# Como usar (a partir da pasta raiz do repositório, depois do 04_modelagem.R):
#   Rscript R/05_validar_modelos.R
#
# Lê:
#   data/processed/base_analitica.rds
#   output/modelos_treino.rds
#
# Grava em output/:
#   validacao_resultados.rds   diagnósticos, testes de robustez e previsões
#   avaliacao_teste.csv        ranking final no conjunto de teste (EAM e RMSE)
#   previsoes_teste.csv        valores reais e previstos mês a mês (nov/2025–out/2026)
# =============================================================================

if (!file.exists("EAP.md")) {
  stop("Rode este script a partir da pasta raiz do repositório (onde está o EAP.md).")
}

suppressPackageStartupMessages({
  library(forecast)
  library(lmtest)
  library(car)
  library(sandwich)
})

# --- 1. Carga dos dados e modelos do treino ----------------------------------
base    <- readRDS("data/processed/base_analitica.rds")
modelos <- readRDS("output/modelos_treino.rds")

treino <- base[base$conjunto == "treino", ]
teste  <- base[base$conjunto == "teste", ]
stopifnot(nrow(treino) == 190, nrow(teste) == 12)

calc_eam  <- function(obs, prev) mean(abs(obs - prev), na.rm = TRUE)
calc_rmse <- function(obs, prev) sqrt(mean((obs - prev)^2, na.rm = TRUE))

# Reconversão log -> MWmed usando fator de Smearing calculado SÓ no treino (D30)
reconv_log <- function(prev_log, resid_treino_log) {
  smearing <- mean(exp(resid_treino_log), na.rm = TRUE)
  exp(prev_log) * smearing
}

# --- 2. Diagnóstico de Pressupostos no Treino (EAP 6.1 e 6.2) ----------------
message("== 6.1 / 6.2 Diagnóstico de pressupostos no treino ==")

reg_mod <- modelos$reg_step_log
res_reg <- residuals(reg_mod)

diag_reg <- list(
  shapiro = shapiro.test(res_reg),
  bp      = bptest(reg_mod),
  dw      = dwtest(reg_mod),
  lb      = Box.test(res_reg, lag = 12, type = "Ljung-Box"),
  vif     = vif(reg_mod),
  cook    = cooks.distance(reg_mod),
  corte_cook = 4 / nrow(treino)
)

# Diagnóstico de resíduos dos principais modelos de séries temporais
testa_res_ts <- function(nome, mod) {
  r  <- na.omit(as.numeric(residuals(mod)))
  lb <- Box.test(r, lag = 12, type = "Ljung-Box")
  sw <- shapiro.test(r)
  data.frame(
    Modelo      = nome,
    LB_stat     = round(as.numeric(lb$statistic), 2),
    LB_pvalor   = signif(lb$p.value, 3),
    Shapiro_W   = round(as.numeric(sw$statistic), 4),
    Shapiro_p   = signif(sw$p.value, 3),
    stringsAsFactors = FALSE
  )
}

diag_ts <- rbind(
  testa_res_ts("Regressão Stepwise (log)", reg_mod),
  testa_res_ts("Holt-Winters Aditivo", modelos$hw_add),
  testa_res_ts("Holt-Winters Multiplicativo", modelos$hw_mult),
  testa_res_ts("ETS (MWmed)", modelos$ets),
  testa_res_ts("ETS (log)", modelos$ets_log),
  testa_res_ts("SARIMA (log)", modelos$sarima_log),
  testa_res_ts("SARIMA (MWmed)", modelos$sarima_orig)
)

# --- 3. Alternativas quando pressupostos falham e Robustez (EAP 6.4 e 6.5) ---
message("== 6.4 / 6.5 Robustez, correção de Holm e Regressão com erros ARIMA ==")

# 6.4a Erros-padrão robustos Newey-West (HAC) para autocorrelação/heterocedasticidade
hac_reg <- coeftest(reg_mod, vcov = NeweyWest(reg_mod))

# 6.4b Regressão dinâmica (clima selecionado + erros SARIMA) no treino
vars_clima_sel <- c("precip_mm_h_lag1", "precip_mm_h_lag2", "umid_pct_lag1", "temp_c_lag2")
xreg_tr <- as.matrix(treino[, vars_clima_sel])
xreg_te <- as.matrix(teste[, vars_clima_sel])

ts_log_tr <- ts(treino$log_ena, start = c(2010, 1), frequency = 12)
mod_sarimax_log <- auto.arima(ts_log_tr, xreg = xreg_tr, seasonal = TRUE,
                              stepwise = FALSE, approximation = FALSE)
diag_ts <- rbind(diag_ts, testa_res_ts("SARIMAX Clima (log)", mod_sarimax_log))

# 6.5a Correção para comparações múltiplas (Holm e Bonferroni) na regressão
s_reg <- summary(reg_mod)$coefficients
tab_robustez <- data.frame(
  Termo      = rownames(s_reg),
  Estimativa = round(s_reg[, 1], 4),
  p_OLS      = signif(s_reg[, 4], 3),
  p_Holm     = signif(p.adjust(s_reg[, 4], method = "holm"), 3),
  p_HAC      = signif(hac_reg[, 4], 3),
  stringsAsFactors = FALSE
)

# 6.5b Sensibilidade: regressão sem pontos influentes (Cook > 4/n)
idx_influentes <- which(diag_reg$cook > diag_reg$corte_cook)
reg_sem_infl   <- update(reg_mod, data = treino[-idx_influentes, ])

# --- 4. Validação Preditiva no Conjunto de Teste Cego (EAP 6.6 / D08 / D30) --
message("== 6.6 Abrindo conjunto de teste (nov/2025 a out/2026) para avaliação ==")

obs_teste <- teste$ena_mwmed

prev_lista <- list(
  "Ingênuo Sazonal (snaive)"        = as.numeric(modelos$snaive$mean),
  "Regressão: Só Dummies (log)"     = reconv_log(predict(modelos$reg_dummies, newdata = teste), residuals(modelos$reg_dummies)),
  "Regressão: Só Clima (log)"       = reconv_log(predict(modelos$reg_clima, newdata = teste), residuals(modelos$reg_clima)),
  "Regressão: Clima + ONI (log)"    = reconv_log(predict(modelos$reg_clima_oni, newdata = teste), residuals(modelos$reg_clima_oni)),
  "Regressão: Stepwise AIC (log)"   = reconv_log(predict(modelos$reg_step_log, newdata = teste), residuals(modelos$reg_step_log)),
  "Regressão: Stepwise AIC (MWmed)" = as.numeric(predict(modelos$reg_step_orig, newdata = teste)),
  "SES (Simples)"                   = as.numeric(modelos$ses$mean),
  "Holt"                            = as.numeric(modelos$holt$mean),
  "Holt-Winters Aditivo"            = as.numeric(modelos$hw_add$mean),
  "Holt-Winters Multiplicativo"     = as.numeric(modelos$hw_mult$mean),
  "ETS (MWmed)"                     = as.numeric(forecast(modelos$ets, h = 12)$mean),
  "ETS (log)"                       = reconv_log(as.numeric(forecast(modelos$ets_log, h = 12)$mean), residuals(modelos$ets_log)),
  "AR (não sazonal) [log]"          = reconv_log(as.numeric(forecast(modelos$ar, h = 12)$mean), residuals(modelos$ar)),
  "MA (não sazonal) [log]"          = reconv_log(as.numeric(forecast(modelos$ma, h = 12)$mean), residuals(modelos$ma)),
  "ARIMA (não sazonal) [log]"       = reconv_log(as.numeric(forecast(modelos$arima_ns, h = 12)$mean), residuals(modelos$arima_ns)),
  "SARIMA [log]"                    = reconv_log(as.numeric(forecast(modelos$sarima_log, h = 12)$mean), residuals(modelos$sarima_log)),
  "SARIMA [MWmed]"                  = as.numeric(forecast(modelos$sarima_orig, h = 12)$mean),
  "SARIMAX Clima [log]"             = reconv_log(as.numeric(forecast(mod_sarimax_log, xreg = xreg_te, h = 12)$mean), residuals(mod_sarimax_log))
)

avaliacao_teste <- do.call(rbind, lapply(names(prev_lista), function(nm) {
  p <- prev_lista[[nm]]
  data.frame(
    Modelo     = nm,
    EAM_teste  = round(calc_eam(obs_teste, p), 2),
    RMSE_teste = round(calc_rmse(obs_teste, p), 2),
    stringsAsFactors = FALSE
  )
}))

# Ganho percentual em RMSE sobre o Ingênuo Sazonal (D18)
rmse_snaive <- avaliacao_teste$RMSE_teste[avaliacao_teste$Modelo == "Ingênuo Sazonal (snaive)"]
avaliacao_teste$Ganho_RMSE_pct <- round((1 - avaliacao_teste$RMSE_teste / rmse_snaive) * 100, 1)
avaliacao_teste <- avaliacao_teste[order(avaliacao_teste$RMSE_teste), ]
rownames(avaliacao_teste) <- NULL

# Tabela mês a mês com real e previstos
previsoes_teste <- data.frame(
  ano_mes   = teste$ano_mes,
  ena_real  = obs_teste,
  lapply(prev_lista, round, 2),
  check.names = FALSE
)

# --- 5. Salvar saídas --------------------------------------------------------
validacao <- list(
  diag_reg        = diag_reg,
  diag_ts         = diag_ts,
  hac_reg         = hac_reg,
  tab_robustez    = tab_robustez,
  idx_influentes  = idx_influentes,
  reg_sem_infl    = reg_sem_infl,
  mod_sarimax_log = mod_sarimax_log,
  avaliacao_teste = avaliacao_teste,
  previsoes_teste = previsoes_teste
)

saveRDS(validacao, "output/validacao_resultados.rds")
write.csv(avaliacao_teste, "output/avaliacao_teste.csv", row.names = FALSE, fileEncoding = "UTF-8")
write.csv(previsoes_teste, "output/previsoes_teste.csv", row.names = FALSE, fileEncoding = "UTF-8")

message("\n== Top 5 modelos no conjunto de teste (RMSE em MWmed) ==")
print(head(avaliacao_teste, 5))
message("\nConcluído! Resultados salvos em output/.")
