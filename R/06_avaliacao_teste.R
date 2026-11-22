# =============================================================================
# 06_avaliacao_teste.R — avaliação no teste por janela rolante (EAP 6.6, D41)
#
# Como usar (a partir da pasta raiz do repositório, depois do 04_modelagem.R):
#   Rscript R/06_avaliacao_teste.R
#
# Lê:
#   data/processed/base_analitica.rds   ENA (inclusive o teste) e preditoras
#   output/modelos_treino.rds           modelos ajustados no treino pelo 04
#
# Grava em output/:
#   avaliacao_teste_rolante.csv    EAM e RMSE de cada modelo nos 12 meses de teste
#   previsoes_teste_rolante.csv    previsão de cada modelo, mês a mês
#   teste_rolante_previsoes.png    observado x previsões dos melhores modelos
#   teste_rolante_erros.png        EAM e RMSE de todos os modelos
#
# Método (D41): 12 rodadas. Na rodada k, cada modelo usa os dados até o mês
# anterior ao previsto e prevê só o mês seguinte (horizonte de 1 mês). Os
# coeficientes ficam CONGELADOS como foram estimados no treino: os meses de
# teste entram só como dados de entrada (a ENA observada nos modelos
# univariados; o clima e as dummies nas regressões), nunca na estimação.
#   - SES, Holt, Holt-Winters e ETS: ets(..., model = ajuste,
#     use.initial.values = TRUE), que só filtra os dados novos pelo modelo;
#   - AR, MA, ARIMA, SARIMA e regressão com erros ARIMA: Arima(..., model = ajuste);
#   - regressões comuns: predict() com as preditoras defasadas do mês previsto;
#   - ingênuo sazonal: o valor do mesmo mês no ano anterior.
# Modelos em log: a previsão volta para MWmed com exp() e o fator de smearing
# de Duan, calculado só com os resíduos do treino (mesma ideia do 04).
#
# Regra D30: este é o primeiro script que lê a ENA do teste. Nenhuma escolha
# de modelo é feita aqui: a lista é a que saiu do treino (04, D39, D42).
# Obs.: R/05_validar_modelos.R faz outra avaliação, com horizonte fixo de 12
# meses; por isso este script grava arquivos com "rolante" no nome.
# =============================================================================

if (!file.exists("EAP.md")) {
  stop("Rode este script a partir da pasta raiz do repositório (onde está o EAP.md).")
}

suppressPackageStartupMessages(library(forecast))

base <- readRDS("data/processed/base_analitica.rds")
base <- base[order(base$ano_mes), ]
m    <- readRDS("output/modelos_treino.rds")
stopifnot(nrow(base) == 202, sum(base$conjunto == "treino") == 190,
          all(base$conjunto[191:202] == "teste"))

N_TR      <- 190
idx_teste <- (N_TR + 1):nrow(base)
y_mw      <- base$ena_mwmed
y_log     <- base$log_ena
obs       <- y_mw[idx_teste]

calc_eam  <- function(o, p) mean(abs(o - p))
calc_rmse <- function(o, p) sqrt(mean((o - p)^2))

# --- 1. Funções de previsão 1 passo à frente com modelo congelado ------------
serie_ate <- function(y, i) ts(y[1:(i - 1)], start = c(2010, 1), frequency = 12)

# Fator de smearing de Duan (resíduos de resposta do treino, escala log)
smearing <- function(obj) {
  r <- if (inherits(obj, "lm")) residuals(obj) else residuals(obj, type = "response")
  mean(exp(as.numeric(r)), na.rm = TRUE)
}

prev_ets <- function(obj, log = FALSE) {
  e <- if (inherits(obj, "ets")) obj else obj$model
  y <- if (log) y_log else y_mw
  p <- sapply(idx_teste, function(i) {
    f <- ets(serie_ate(y, i), model = e, use.initial.values = TRUE)
    as.numeric(forecast(f, h = 1)$mean)
  })
  if (log) exp(p) * smearing(obj) else p
}

prev_arima <- function(obj, log = FALSE, xvars = NULL) {
  y <- if (log) y_log else y_mw
  X <- if (!is.null(xvars)) as.matrix(base[, xvars, drop = FALSE]) else NULL
  p <- sapply(idx_teste, function(i) {
    if (is.null(X)) {
      f <- Arima(serie_ate(y, i), model = obj)
      as.numeric(forecast(f, h = 1)$mean)
    } else {
      f <- Arima(serie_ate(y, i), xreg = X[1:(i - 1), , drop = FALSE], model = obj)
      as.numeric(forecast(f, h = 1, xreg = X[i, , drop = FALSE])$mean)
    }
  })
  if (log) exp(p) * smearing(obj) else p
}

prev_lm <- function(obj, log = FALSE) {
  p <- as.numeric(predict(obj, newdata = base[idx_teste, ]))
  if (log) exp(p) * smearing(obj) else p
}

nome_arima <- function(obj) {
  o <- arimaorder(obj)
  if (length(o) > 3) sprintf("SARIMA(%d,%d,%d)(%d,%d,%d)[12]", o[1], o[2], o[3], o[4], o[5], o[6])
  else sprintf("ARIMA(%d,%d,%d)", o[1], o[2], o[3])
}

# --- 2. Previsões de todos os modelos (mesma lista do treino) ----------------
message("== Prevendo os 12 meses de teste por janela rolante (D41) ==")
vars_regarima <- m$regarima_sel$variaveis

modelos <- list(
  list(nome = "Ingênuo sazonal",                     familia = "Referência",  p = y_mw[idx_teste - 12]),
  list(nome = "Regressão: só dummies",               familia = "Regressão",   p = prev_lm(m$reg_dummies,   log = TRUE)),
  list(nome = "Regressão: só clima",                 familia = "Regressão",   p = prev_lm(m$reg_clima,     log = TRUE)),
  list(nome = "Regressão: clima + ONI",              familia = "Regressão",   p = prev_lm(m$reg_clima_oni, log = TRUE)),
  list(nome = "Regressão: stepwise AIC (D39)",       familia = "Regressão",   p = prev_lm(m$reg_step_log,  log = TRUE)),
  list(nome = "Regressão: stepwise AIC (MWmed)",     familia = "Regressão",   p = prev_lm(m$reg_step_orig)),
  list(nome = paste0("Regressão com erros ", nome_arima(m$regarima), " (D42)"), familia = "Regressão",
       p = prev_arima(m$regarima, log = TRUE, xvars = vars_regarima)),
  list(nome = "SES",                                 familia = "Suavização",  p = prev_ets(m$ses)),
  list(nome = "Holt",                                familia = "Suavização",  p = prev_ets(m$holt)),
  list(nome = "Holt-Winters aditivo",                familia = "Suavização",  p = prev_ets(m$hw_add)),
  list(nome = "Holt-Winters multiplicativo",         familia = "Suavização",  p = prev_ets(m$hw_mult)),
  list(nome = m$ets$method,                          familia = "Suavização",  p = prev_ets(m$ets)),
  list(nome = paste0(m$ets_log$method, " [log]"),    familia = "Suavização",  p = prev_ets(m$ets_log, log = TRUE)),
  list(nome = paste0("AR: ", nome_arima(m$ar), " [log]"), familia = "Box-Jenkins", p = prev_arima(m$ar, log = TRUE)),
  list(nome = paste0("MA: ", nome_arima(m$ma), " [log]"), familia = "Box-Jenkins", p = prev_arima(m$ma, log = TRUE)),
  list(nome = paste0(nome_arima(m$arima_ns), " [log]"),   familia = "Box-Jenkins", p = prev_arima(m$arima_ns, log = TRUE)),
  list(nome = paste0(nome_arima(m$sarima_log), " [log]"), familia = "Box-Jenkins", p = prev_arima(m$sarima_log, log = TRUE)),
  list(nome = paste0(nome_arima(m$sarima_orig), " [MWmed]"), familia = "Box-Jenkins", p = prev_arima(m$sarima_orig))
)

# --- 3. Checagem: a 1ª rodada deve reproduzir a previsão do modelo do treino -
# (garante que os coeficientes e estados ficaram congelados)
confere <- function(nome, rolante, original) {
  if (abs(rolante - original) > 1e-6 * abs(original)) {
    stop("A 1ª previsão rolante de ", nome, " difere da previsão do treino: ", rolante, " vs ", original)
  }
}
pega <- function(nome) modelos[[which(sapply(modelos, `[[`, "nome") == nome)]]$p[1]
confere("ETS", pega(m$ets$method), as.numeric(forecast(m$ets, h = 1)$mean))
confere("HW multiplicativo", pega("Holt-Winters multiplicativo"), as.numeric(m$hw_mult$mean[1]))
confere("SARIMA log", pega(paste0(nome_arima(m$sarima_log), " [log]")),
        exp(as.numeric(forecast(m$sarima_log, h = 1)$mean)) * smearing(m$sarima_log))
X191 <- as.matrix(base[N_TR + 1, vars_regarima, drop = FALSE])
confere("Regressão com erros ARIMA", modelos[[7]]$p[1],
        exp(as.numeric(forecast(m$regarima, h = 1, xreg = X191)$mean)) * smearing(m$regarima))
message("  checagem ok: a 1ª rodada reproduz a previsão dos modelos do treino")

# --- 4. Métricas (D09) --------------------------------------------------------
aval <- do.call(rbind, lapply(modelos, function(x) {
  data.frame(modelo = x$nome, familia = x$familia,
             EAM = calc_eam(obs, x$p), RMSE = calc_rmse(obs, x$p), stringsAsFactors = FALSE)
}))
ref <- aval[aval$modelo == "Ingênuo sazonal", ]
aval$ganho_EAM_pct  <- round(100 * (1 - aval$EAM  / ref$EAM), 1)
aval$ganho_RMSE_pct <- round(100 * (1 - aval$RMSE / ref$RMSE), 1)
aval$EAM  <- round(aval$EAM, 1)
aval$RMSE <- round(aval$RMSE, 1)
aval <- aval[order(aval$RMSE), ]
aval$posicao <- seq_len(nrow(aval))
aval <- aval[, c("posicao", "modelo", "familia", "EAM", "RMSE", "ganho_EAM_pct", "ganho_RMSE_pct")]
rownames(aval) <- NULL

prev_tab <- data.frame(ano_mes = base$ano_mes[idx_teste], observado = round(obs, 1))
for (x in modelos) prev_tab[[x$nome]] <- round(x$p, 1)

dir.create("output", showWarnings = FALSE)
write.csv(aval, "output/avaliacao_teste_rolante.csv", row.names = FALSE, fileEncoding = "UTF-8")
write.csv(prev_tab, "output/previsoes_teste_rolante.csv", row.names = FALSE, fileEncoding = "UTF-8")
message("  gravado output/avaliacao_teste_rolante.csv e output/previsoes_teste_rolante.csv")

# --- 5. Gráficos ---------------------------------------------------------------
# Paleta categórica validada (ordem fixa) e tinta neutra para observado/referência
COR_FAMILIA <- c("Regressão" = "#2a78d6", "Suavização" = "#eb6834",
                 "Box-Jenkins" = "#1baf7a", "Referência" = "#8a8984")
COR_SERIES  <- c("#2a78d6", "#eb6834", "#1baf7a")
TINTA       <- "#0b0b0b"; TINTA2 <- "#52514e"; GRADE <- "#e4e3df"
MESES <- c("jan","fev","mar","abr","mai","jun","jul","ago","set","out","nov","dez")
rotulo_mes <- function(am) paste0(MESES[as.integer(substr(am, 6, 7))], "/", substr(am, 3, 4))

# 5a. Observado x previsões: os 3 melhores modelos e o ingênuo sazonal
top3 <- aval$modelo[aval$modelo != "Ingênuo sazonal"][1:3]
janela <- (N_TR - 11):nrow(base)           # 12 meses de treino para contexto + teste
x_all  <- seq_along(janela); x_te <- x_all[janela %in% idx_teste]
ylim   <- range(c(y_mw[janela], sapply(top3, function(n) modelos[[which(sapply(modelos, `[[`, "nome") == n)]]$p), y_mw[idx_teste - 12]))
ylim   <- c(0, ylim[2] * 1.08)

png("output/teste_rolante_previsoes.png", width = 1800, height = 1000, res = 150)
par(mar = c(4.2, 5.2, 3.6, 1), mgp = c(3.6, 0.7, 0), las = 1, col.axis = TINTA2, fg = TINTA2)
plot(NA, xlim = range(x_all), ylim = ylim, xaxt = "n", yaxt = "n", bty = "n",
     xlab = "", ylab = "ENA (MWmed)", col.lab = TINTA2,
     main = "Teste cego: observado e previsões 1 mês à frente (janela rolante, D41)",
     col.main = TINTA, font.main = 1, cex.main = 1.1)
abline(h = pretty(ylim), col = GRADE, lwd = 1)
axis(2, at = pretty(ylim), labels = format(pretty(ylim), big.mark = ".", decimal.mark = ",", scientific = FALSE), lwd = 0)
axis(1, at = x_all, labels = rotulo_mes(base$ano_mes[janela]), lwd = 0, cex.axis = 0.8)
rect(min(x_te) - 0.5, ylim[1], max(x_te) + 0.5, ylim[2], col = "#f4f3f0", border = NA)
abline(h = pretty(ylim), col = GRADE, lwd = 1)
text(mean(x_te), ylim[2] * 0.985, "período de teste", col = TINTA2, cex = 0.85)
lines(x_all, y_mw[janela], col = TINTA, lwd = 2.4)
points(x_te, obs, pch = 19, col = TINTA, cex = 0.9)
lines(x_te, y_mw[idx_teste - 12], col = "#8a8984", lwd = 2, lty = 2)
for (k in 1:3) {
  p <- modelos[[which(sapply(modelos, `[[`, "nome") == top3[k])]]$p
  lines(x_te, p, col = COR_SERIES[k], lwd = 2)
  points(x_te, p, pch = 21, bg = COR_SERIES[k], col = "white", cex = 1.1)
}
legend("topleft", bty = "n", cex = 0.85, text.col = TINTA,
       legend = c("Observado", paste0(1:3, "º  ", top3), "Ingênuo sazonal (referência)"),
       col = c(TINTA, COR_SERIES, "#8a8984"), lwd = c(2.4, 2, 2, 2, 2), lty = c(1, 1, 1, 1, 2),
       pch = c(19, 21, 21, 21, NA), pt.bg = c(TINTA, COR_SERIES, NA))
invisible(dev.off())
message("  gravado output/teste_rolante_previsoes.png")

# 5b. EAM e RMSE de todos os modelos (mesma ordem, pelo RMSE)
ord <- rev(seq_len(nrow(aval)))
cores <- COR_FAMILIA[aval$familia[ord]]
png("output/teste_rolante_erros.png", width = 1900, height = 1300, res = 150)
par(oma = c(3.5, 0, 0, 0))
layout(matrix(1:2, 1), widths = c(1.55, 1))
painel <- function(v, titulo, com_nomes) {
  par(mar = c(4, if (com_nomes) 21 else 1, 3.2, 3.5), mgp = c(2.4, 0.6, 0), las = 1,
      col.axis = TINTA2, fg = TINTA2)
  ref_v <- v[aval$modelo == "Ingênuo sazonal"]
  lim <- c(0, max(v) * 1.18)
  bp <- barplot(v[ord], horiz = TRUE, col = cores, border = "white", space = 0.35,
                xlim = lim, names.arg = if (com_nomes) aval$modelo[ord] else rep("", length(ord)),
                cex.names = 0.8, axes = FALSE, main = titulo, col.main = TINTA, font.main = 1)
  abline(v = pretty(lim), col = GRADE)
  barplot(v[ord], horiz = TRUE, col = cores, border = "white", space = 0.35, add = TRUE,
          axes = FALSE, names.arg = rep("", length(ord)))
  abline(v = ref_v, lty = 2, col = TINTA2)
  axis(1, at = pretty(lim), labels = format(pretty(lim), big.mark = ".", decimal.mark = ",", scientific = FALSE), lwd = 0, cex.axis = 0.8)
  text(v[ord], bp, format(round(v[ord]), big.mark = ".", decimal.mark = ","), pos = 4, cex = 0.72, col = TINTA, xpd = TRUE)
}
painel(aval$RMSE, "RMSE no teste (MWmed)", TRUE)
painel(aval$EAM, "EAM no teste (MWmed)", FALSE)
# Legenda e nota no rodapé, fora da área das barras
par(fig = c(0, 1, 0, 1), oma = c(0, 0, 0, 0), mar = c(0, 0, 0, 0), new = TRUE)
plot(0, 0, type = "n", bty = "n", xaxt = "n", yaxt = "n", xlab = "", ylab = "")
legend("bottom", inset = c(0, 0.04), horiz = TRUE, bty = "n", cex = 0.85, text.col = TINTA,
       fill = COR_FAMILIA, border = "white", legend = names(COR_FAMILIA), x.intersp = 0.6, text.width = 0.22)
mtext("Linha tracejada: ingênuo sazonal (referência mínima, D18). Ordem pelo RMSE.",
      side = 1, line = -0.9, cex = 0.75, col = TINTA2)
invisible(dev.off())
message("  gravado output/teste_rolante_erros.png")

message("\nConcluído.")
