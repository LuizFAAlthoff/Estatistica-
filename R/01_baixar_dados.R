# =============================================================================
# 01_baixar_dados.R — baixa todos os dados brutos do projeto (EAP 2.4 / 2.7)
#
# Como usar (a partir da pasta raiz do repositório):
#   Rscript R/01_baixar_dados.R
# ou, no RStudio, abrir este arquivo e clicar em "Source".
#
# O que baixa (período definido em D26: jan/2010 até o ano atual):
#   data/raw/ons/   ENA diária por bacia (ONS), um CSV por ano          (D22)
#   data/raw/noaa/  tabela do ONI (CPC/NOAA)                             (D24)
#   data/raw/inmet/ estações automáticas do INMET, um ZIP por ano (~1,5 GB) (D25)
#
# Arquivos que já existem são pulados, exceto os do ano atual e o ONI, que
# são atualizados a cada execução. Para forçar tudo de novo: FORCAR <- TRUE.
#
# Requisito: o programa `curl`, que já vem no Windows 10/11, no macOS e no Linux.
# =============================================================================

ANO_INICIAL <- 2010
ANO_FINAL   <- as.integer(format(Sys.Date(), "%Y"))
FORCAR      <- FALSE

if (!file.exists("EAP.md")) {
  stop("Rode este script a partir da pasta raiz do repositório (onde está o EAP.md).")
}
if (Sys.which("curl") == "") stop("O programa 'curl' não foi encontrado no PATH.")

UA <- "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0 Safari/537.36"
COOKIES <- tempfile(fileext = ".txt")

# Baixa uma URL para `destino` usando o curl do sistema.
# Baixa primeiro para um arquivo temporário: um download interrompido não
# deixa arquivo pela metade na pasta.
baixar <- function(url, destino, extra = character(), tentativas = 3) {
  dir.create(dirname(destino), recursive = TRUE, showWarnings = FALSE)
  tmp <- paste0(destino, ".parcial")
  for (i in seq_len(tentativas)) {
    status <- system2("curl", c("-sS", "-L", "--fail", "-A", shQuote(UA),
                                "-c", shQuote(COOKIES), "-b", shQuote(COOKIES),
                                extra, "-o", shQuote(tmp), shQuote(url)))
    if (status == 0 && file.exists(tmp) && file.size(tmp) > 0) {
      file.rename(tmp, destino)
      return(invisible(TRUE))
    }
    unlink(tmp)
    message("   falhou (tentativa ", i, "/", tentativas, ")")
    Sys.sleep(3)
  }
  warning("Não foi possível baixar: ", url)
  invisible(FALSE)
}

precisa_baixar <- function(destino, ano = NA) {
  FORCAR || !file.exists(destino) || (!is.na(ano) && ano == ANO_FINAL)
}

anos <- ANO_INICIAL:ANO_FINAL

# --- 1. ENA diária por bacia (ONS) -------------------------------------------
message("\n== ENA (ONS) ==")
for (ano in anos) {
  destino <- file.path("data/raw/ons", sprintf("ENA_DIARIO_BACIAS_%d.csv", ano))
  if (!precisa_baixar(destino, ano)) { message(ano, ": já existe"); next }
  message(ano, ": baixando")
  baixar(sprintf("https://ons-aws-prod-opendata.s3.amazonaws.com/dataset/ena_bacia_di/ENA_DIARIO_BACIAS_%d.csv", ano),
         destino)
}

# --- 2. ONI (CPC/NOAA) — sempre atualizado -----------------------------------
message("\n== ONI (NOAA) ==")
baixar("https://www.cpc.ncep.noaa.gov/data/indices/oni.ascii.txt", "data/raw/noaa/oni.ascii.txt")

# --- 3. INMET, estações automáticas ------------------------------------------
# O portal do INMET recusa downloads "diretos": é preciso abrir a página
# primeiro (para receber o cookie de sessão) e informá-la como origem (-e).
message("\n== INMET (estações automáticas) ==")
PAGINA_INMET <- "https://portal.inmet.gov.br/dadoshistoricos"
baixar(PAGINA_INMET, tempfile(fileext = ".html"))
for (ano in anos) {
  destino <- file.path("data/raw/inmet", sprintf("%d.zip", ano))
  if (!precisa_baixar(destino, ano)) { message(ano, ": já existe"); next }
  message(ano, ": baixando (pode levar alguns minutos)")
  ok <- baixar(sprintf("https://portal.inmet.gov.br/uploads/dadoshistoricos/%d.zip", ano),
               destino, extra = c("-e", PAGINA_INMET))
  # confere se o arquivo é um ZIP válido
  if (isTRUE(ok) && inherits(try(unzip(destino, list = TRUE), silent = TRUE), "try-error")) {
    unlink(destino)
    warning("O arquivo do INMET de ", ano, " veio corrompido e foi apagado. Rode o script de novo.")
  }
}

unlink(COOKIES)
message("\nConcluído. Arquivos em data/raw/ons, data/raw/noaa e data/raw/inmet.")
