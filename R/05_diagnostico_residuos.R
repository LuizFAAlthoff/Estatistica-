# =============================================================================
# 05_diagnostico_residuos.R — diagnóstico dos resíduos no treino (EAP 6.1–6.2)
#
# Como usar (a partir da pasta raiz do repositório, depois do 04_modelagem.R):
#   Rscript R/05_diagnostico_residuos.R
#
# Lê:
#   output/modelos_treino.rds        modelos ajustados no treino pelo 04
#
# Grava em output/:
#   diagnostico_residuos.csv         Ljung-Box e Shapiro-Wilk de cada modelo
#   residuos_acf_todos.png           ACF dos resíduos dos 18 modelos
#   residuos_<modelo>.png            série, ACF e histograma de 6 modelos-chave
#
# Ideia: se o modelo capturou toda a estrutura da série, o que sobra (o
# resíduo) deve parecer ruído aleatório, sem correlação entre um mês e outro.
#   - Ljung-Box: H0 = não há autocorrelação até o lag 24 (dois ciclos
#     sazonais, como recomendam Hyndman e Athanasopoulos). p < 0,05 => sobrou
#     padrão que o modelo não explicou.
#   - Shapiro-Wilk: H0 = resíduos normais (pressuposto dos intervalos de
#     previsão e dos testes t/F).
# Resíduos usados: os de inovação de cada modelo. Estão na escala log nos
# modelos ajustados em log_ena, em MWmed nos de erro aditivo e em termos
# relativos (0,5 = 50% acima do previsto) nos ETS/Holt-Winters de erro
# multiplicativo.
# Período: jan/2011 a out/2025. O primeiro ano fica de fora porque vários
# modelos o usam para se inicializar (o ingênuo sazonal não tem resíduo nele e
# os SARIMA dão resíduos quase nulos), o que distorceria a comparação.
#
# Regra D30: os modelos foram ajustados só no treino (2010-01 a 2025-10).
# O conjunto de teste não é lido.
# =============================================================================

if (!file.exists("EAP.md")) {
  stop("Rode este script a partir da pasta raiz do repositório (onde está o EAP.md).")
}

suppressPackageStartupMessages(library(forecast))

LAG_LB  <- 24   # lags do Ljung-Box
LAG_ACF <- 36   # lags mostrados nos gráficos de ACF
FIM_TR  <- c(2025, 10)
INI_DIAG <- c(2011, 1)  # início do período diagnosticado

m <- readRDS("output/modelos_treino.rds")

# --- 1. Lista de modelos (mesma ordem do resumo do 04) -----------------------
nome_arima <- function(obj) {
  o <- arimaorder(obj)
  if (length(o) > 3) sprintf("SARIMA(%d,%d,%d)(%d,%d,%d)[12]", o[1], o[2], o[3], o[4], o[5], o[6])
  else sprintf("ARIMA(%d,%d,%d)", o[1], o[2], o[3])
}

modelos <- list(
  list(id = "snaive",        nome = "Ingênuo sazonal",                    obj = m$snaive,        escala = "MWmed"),
  list(id = "reg_dummies",   nome = "Regressão: só dummies",              obj = m$reg_dummies,   escala = "log"),
  list(id = "reg_clima",     nome = "Regressão: só clima",                obj = m$reg_clima,     escala = "log"),
  list(id = "reg_clima_oni", nome = "Regressão: clima + ONI",             obj = m$reg_clima_oni, escala = "log"),
  list(id = "reg_step_log",  nome = "Regressão: stepwise AIC (D39)",      obj = m$reg_step_log,  escala = "log"),
  list(id = "reg_step_orig", nome = "Regressão: stepwise AIC (MWmed)",    obj = m$reg_step_orig, escala = "MWmed"),
  list(id = "regarima",      nome = paste0("Regressão com erros ", nome_arima(m$regarima), " (D42)"), obj = m$regarima, escala = "log"),
  list(id = "ses",           nome = "SES",                                obj = m$ses,           escala = "MWmed"),
  list(id = "holt",          nome = "Holt",                               obj = m$holt,          escala = "MWmed"),
  list(id = "hw_add",        nome = "Holt-Winters aditivo",               obj = m$hw_add,        escala = "MWmed"),
  list(id = "hw_mult",       nome = "Holt-Winters multiplicativo",        obj = m$hw_mult,       escala = "MWmed"),
  list(id = "ets",           nome = paste0(m$ets$method, ""),             obj = m$ets,           escala = "MWmed"),
  list(id = "ets_log",       nome = paste0(m$ets_log$method, " [log]"),   obj = m$ets_log,       escala = "log"),
  list(id = "ar",            nome = paste0("AR: ", nome_arima(m$ar), " [log]"),       obj = m$ar,          escala = "log"),
  list(id = "ma",            nome = paste0("MA: ", nome_arima(m$ma), " [log]"),       obj = m$ma,          escala = "log"),
  list(id = "arima_ns",      nome = paste0(nome_arima(m$arima_ns), " [log]"),         obj = m$arima_ns,    escala = "log"),
  list(id = "sarima_log",    nome = paste0(nome_arima(m$sarima_log), " [log]"),       obj = m$sarima_log,  escala = "log"),
  list(id = "sarima_orig",   nome = paste0(nome_arima(m$sarima_orig), " [MWmed]"),    obj = m$sarima_orig, escala = "MWmed")
)

# Resíduos como série mensal terminando em out/2025 (lm não guarda as datas)
residuos_ts <- function(obj) {
  r <- as.numeric(residuals(obj))
  window(ts(r, end = FIM_TR, frequency = 12), start = INI_DIAG)
}

# Escala do resíduo: relativa quando o erro do ETS é multiplicativo
escala_residuo <- function(obj, escala) {
  e <- if (inherits(obj, "ets")) obj else if (inherits(obj$model, "ets")) obj$model else NULL
  if (!is.null(e) && e$components[1] == "M") return("relativo")
  escala
}

# p-valor legível nos gráficos (o R arredonda p muito pequeno para 0)
fmt_p <- function(p) if (p < 0.001) "< 0,001" else trimws(formatC(p, digits = 2, format = "fg", decimal.mark = ","))

# Graus de liberdade gastos pelo modelo (só os termos ARMA, como no forecast)
gl_modelo <- function(obj) {
  if (!inherits(obj, "Arima")) return(0)
  o <- arimaorder(obj)
  unname(o[1] + o[3] + if (length(o) > 3) o[4] + o[6] else 0)
}

# Escala correta do resíduo de cada modelo
for (i in seq_along(modelos)) {
  modelos[[i]]$escala <- escala_residuo(modelos[[i]]$obj, modelos[[i]]$escala)
}

# --- 2. Testes de Ljung-Box e Shapiro-Wilk -----------------------------------
tab <- do.call(rbind, lapply(modelos, function(x) {
  r  <- residuos_ts(x$obj)
  rr <- na.omit(r)
  lb <- Box.test(rr, lag = LAG_LB, type = "Ljung-Box", fitdf = gl_modelo(x$obj))
  sw <- shapiro.test(as.numeric(rr))
  ac <- acf(as.numeric(rr), lag.max = 12, plot = FALSE)$acf
  data.frame(
    modelo        = x$nome,
    escala        = x$escala,
    n_residuos    = length(rr),
    acf_lag1      = round(ac[2], 3),
    acf_lag12     = round(ac[13], 3),
    ljung_box_Q   = round(unname(lb$statistic), 2),
    ljung_box_gl  = unname(lb$parameter),
    ljung_box_p   = signif(lb$p.value, 3),
    ruido_branco  = ifelse(lb$p.value >= 0.05, "sim", "não"),
    shapiro_p     = signif(sw$p.value, 3),
    normal        = ifelse(sw$p.value >= 0.05, "sim", "não"),
    stringsAsFactors = FALSE
  )
}))
dir.create("output", showWarnings = FALSE)
write.csv(tab, "output/diagnostico_residuos.csv", row.names = FALSE, fileEncoding = "UTF-8")
message("  gravado output/diagnostico_residuos.csv (", nrow(tab), " modelos)")

# --- 3. Painel com a ACF dos resíduos de todos os modelos --------------------
png("output/residuos_acf_todos.png", width = 1800, height = 2200, res = 140)
par(mfrow = c(6, 3), mar = c(3.2, 3.2, 4.2, 0.8), mgp = c(2, 0.6, 0), oma = c(2.5, 0, 0, 0))
for (i in seq_along(modelos)) {
  x <- modelos[[i]]
  r <- residuos_ts(x$obj)
  Acf(as.numeric(r), lag.max = LAG_ACF, na.action = na.pass, ylim = c(-0.5, 1),
      main = sprintf("%s\nLjung-Box: p %s", x$nome, sub("^([0-9])", "= \\1", fmt_p(tab$ljung_box_p[i]))),
      xlab = "Defasagem (meses)", ylab = "ACF", cex.main = 0.85)
  abline(v = c(12, 24, 36), lty = 3, col = "grey50")
}
mtext("Barras dentro das faixas azuis: correlação compatível com zero.  Linhas pontilhadas: lags 12, 24 e 36 (mesmo mês em anos anteriores).",
      side = 1, outer = TRUE, line = 1, cex = 0.9, col = "grey30")
invisible(dev.off())
message("  gravado output/residuos_acf_todos.png")

# --- 4. Painel detalhado dos modelos-chave -----------------------------------
chave <- c("snaive", "reg_step_log", "regarima", "hw_mult", "ets", "sarima_log")
for (id in chave) {
  x  <- modelos[[which(sapply(modelos, `[[`, "id") == id)]]
  r  <- residuos_ts(x$obj)
  rr <- na.omit(as.numeric(r))
  i  <- which(tab$modelo == x$nome)
  png(sprintf("output/residuos_%s.png", id), width = 1600, height = 1100, res = 140)
  layout(matrix(c(1, 1, 2, 3), 2, byrow = TRUE))
  par(mar = c(4, 4, 3.5, 1), oma = c(0, 0, 2, 0))
  plot(r, type = "l", col = "#1f77b4", xlab = "Ano",
       ylab = sprintf("Resíduo (%s)", x$escala), main = "Resíduos ao longo do tempo")
  abline(h = 0, col = "red")
  Acf(as.numeric(r), lag.max = LAG_ACF, na.action = na.pass, main = "ACF dos resíduos",
      xlab = "Defasagem (meses)")
  abline(v = c(12, 24, 36), lty = 3, col = "grey50")
  hist(rr, breaks = 25, freq = FALSE, col = "#9ecae1", border = "white",
       main = "Histograma (linha: normal)", xlab = sprintf("Resíduo (%s)", x$escala))
  curve(dnorm(x, mean(rr), sd(rr)), add = TRUE, col = "red", lwd = 2)
  mtext(sprintf("%s  |  Ljung-Box (lag %d): p %s  |  Shapiro-Wilk: p %s",
                x$nome, LAG_LB, sub("^([0-9])", "= \\1", fmt_p(tab$ljung_box_p[i])), sub("^([0-9])", "= \\1", fmt_p(tab$shapiro_p[i]))),
        outer = TRUE, cex = 1, font = 2)
  invisible(dev.off())
  message("  gravado output/residuos_", id, ".png")
}

message("\nConcluído.")
