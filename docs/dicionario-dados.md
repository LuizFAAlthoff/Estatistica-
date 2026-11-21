# Dicionário de Dados

> Descrição das fontes, variáveis brutas (`data/raw/`) e estrutura prevista para a base mensal consolidada (`data/processed/`) do projeto **Previsão da ENA da Bacia do Rio Grande** (INE5649 – UFSC).
>
> **Período de análise (D26):** janeiro de 2010 a outubro de 2026 (último mês completo disponível).
> **Escala da modelagem (D04):** mensal (`frequência = 12`).
> **Conjunto de teste (D08):** últimos 12 meses completos (nov/2025 a out/2026).

---

## 1. Dados Brutos (`data/raw/`)

### 1.1 ONS — ENA Diária por Bacia (D22)

- **Fonte:** Operador Nacional do Sistema Elétrico (Portal de Dados Abertos).
- **Arquivos:** `ENA_DIARIO_BACIAS_<ano>.csv` (um arquivo por ano).
- **Formato:** CSV, codificação `UTF-8`, separador `;`, decimal `.`, formato longo (uma linha por bacia por dia).

| Nome | Descrição | Tipo | Unidade | Valores possíveis | Uso no projeto |
|---|---|---|---|---|---|
| `nom_bacia` | Nome da bacia hidrográfica | Qualitativa nominal (texto) | — | Nomes das bacias do SIN (ex.: `GRANDE`, `PARANA`, `PARANAIBA`, etc.) | Filtro (`GRANDE`) |
| `ena_data` | Data da observação diária | Data | `AAAA-MM-DD` | `2000-01-01` a `2026-11-18` (recorte do projeto: `2010-01-01` a `2026-10-31`) | Chave temporal |
| `ena_bruta_bacia_mwmed` | Energia Natural Afluente bruta da bacia | Quantitativa contínua | MWmed | Reais $> 0$ (na amostra da GRANDE: ~1.100 a >11.400) | **Variável resposta (D05)** |
| `ena_bruta_bacia_percentualmlt` | ENA bruta em percentual da Média de Longo Termo (MLT) | Quantitativa contínua | % | Reais $> 0$ | Descartada (D05) |
| `ena_armazenavel_bacia_mwmed` | Parcela da ENA passível de armazenamento | Quantitativa contínua | MWmed | Reais $\ge 0$ | Descartada |
| `ena_armazenavel_bacia_percentualmlt` | Parcela armazenável em percentual da MLT | Quantitativa contínua | % | Reais $\ge 0$ | Descartada |

---

### 1.2 CPC/NOAA — Índice ONI (*Oceanic Niño Index*) (D13, D24)

- **Fonte:** Climate Prediction Center / NOAA (`oni.ascii.txt`).
- **Formato:** texto delimitado por espaços, com cabeçalho.

| Nome | Descrição | Tipo | Unidade | Valores possíveis | Uso no projeto |
|---|---|---|---|---|---|
| `SEAS` | Trimestre móvel de 3 meses | Qualitativa ordinal (texto) | — | `DJF`, `JFM`, `FMA`, `MAM`, `AMJ`, `MJJ`, `JJA`, `JAS`, `ASO`, `SON`, `OND`, `NDJ` | Conversão para o mês central (D24) |
| `YR` | Ano de referência do trimestre | Quantitativa discreta | Ano (`AAAA`) | Inteiros de `1950` a `2026` | Chave temporal |
| `TOTAL` | Temperatura média da superfície do mar na região Niño 3.4 | Quantitativa contínua | °C | Reais positivos (tipicamente entre ~24 e ~30 °C) | Descartada |
| `ANOM` | Anomalia de temperatura (índice **ONI**) | Quantitativa contínua | °C | Reais positivos ou negativos (tipicamente entre −2,5 e +2,6; $\ge +0{,}5$ El Niño, $\le -0{,}5$ La Niña) | **Variável explicativa candidata (D15)** |

**Regras de conversão:** cada trimestre é associado ao mês central (`DJF` → jan, …, `NDJ` → dez). Para `NDJ`, o ano em `YR` é o do início do trimestre (`NDJ/2025` → **dez/2025**). Por ser média móvel centrada, o valor do mês $t$ só é conhecido ao fim do mês $t+1$ (atraso de 1 mês considerado na D14/D24).

---

### 1.3 INMET — Estações Meteorológicas Automáticas (D19, D25)

- **Fonte:** Instituto Nacional de Meteorologia (*Dados Históricos*, `2010.zip` a `2026.zip`).
- **Formato:** CSV por estação/ano, codificação `latin-1`, separador `;`, decimal `,`, 8 linhas iniciais de metadados + registros horários.
- **Cobertura espacial (D25, D27):** 19 estações na bacia do Rio Grande (12 desde jan/2010, Barretos desde jun/2010 e 6 iniciadas entre 2015 e 2019).

| Nome | Descrição | Tipo | Unidade | Valores possíveis | Status / Candidata (D20) |
|---|---|---|---|---|---|
| `Data` | Data do registro horário | Data | `AAAA/MM/DD` | `2010/01/01` a `2026/10/31` | Chave temporal |
| `Hora UTC` | Hora da leitura em tempo universal | Hora | `HHMM UTC` | `0000 UTC` a `2300 UTC` (de hora em hora) | Chave temporal |
| Precipitação total | Volume de chuva acumulado na hora | Quantitativa contínua | mm | Reais $\ge 0$; ausentes como `-9999` ou vazio | **Candidata principal** |
| Temperatura do ar (bulbo seco, máx., mín.) | Temperatura do ar na hora, máxima e mínima horária | Quantitativa contínua | °C | Reais (tipicamente −5 a 45 °C na bacia); ausentes como `-9999` ou vazio | **Candidata** |
| Umidade relativa (na hora, máx., mín.) | Umidade relativa do ar | Quantitativa contínua | % | Reais de `0` a `100`; ausentes como `-9999` ou vazio | **Candidata** |
| Radiação global | Radiação solar incidente na hora | Quantitativa contínua | kJ/m² | Reais $\ge 0$ (zero à noite); ausentes como `-9999` ou vazio | A avaliar na etapa 3 |
| Pressão atmosférica (na hora, máx., mín.) | Pressão atmosférica no nível da estação | Quantitativa contínua | mB | Reais positivos (tipicamente 850 a 1050 mB); ausentes como `-9999` ou vazio | A avaliar na etapa 3 |
| Temperatura do ponto de orvalho (na hora, máx., mín.) | Temperatura de condensação do vapor d'água | Quantitativa contínua | °C | Reais $\le$ temperatura do ar; ausentes como `-9999` ou vazio | A avaliar na etapa 3 |
| Vento — velocidade e rajada máxima | Velocidade média e rajada máxima do vento | Quantitativa contínua | m/s | Reais $\ge 0$; ausentes como `-9999` ou vazio | A avaliar na etapa 3 |
| Vento — direção | Direção de origem do vento | Quantitativa contínua | ° (graus) | `0` a `360`; ausentes como `-9999` ou vazio | A avaliar na etapa 3 |

---

## 2. Base Analítica Consolidada (`data/processed/base_analitica.{csv,rds}`, EAP 4.3)

Gerada por `Rscript R/03_preparar_dados.R` (202 meses: `2010-01` a `2026-10`, sem valores ausentes).

| Nome | Descrição | Tipo | Unidade | Valores possíveis | Regra de construção |
|---|---|---|---|---|---|
| `ano_mes` | Mês de referência da observação | Data | `AAAA-MM` | `2010-01` a `2026-10` (202 meses) | Índice mensal contínuo (D26) |
| `ano`, `mes` | Ano e mês numérico extraídos de `ano_mes` | Quantitativa discreta | — | `2010`–`2026`; `1`–`12` | Decomposição temporal de `ano_mes` |
| `conjunto` | Partição da série para modelagem e avaliação cega | Qualitativa nominal | — | `"treino"` (`2010-01` a `2025-10`, $n=190$) ou `"teste"` (`2025-11` a `2026-10`, $n=12$) | Separação treino/teste (D08, D30) |
| `ena_mwmed` | ENA bruta média mensal da bacia do Rio Grande | Quantitativa contínua | MWmed | Reais $> 0$ (sem `NA`) | Média mensal dos valores diários do ONS (D05, D28) |
| `log_ena` | Logaritmo natural da ENA bruta mensal | Quantitativa contínua | $\ln(\text{MWmed})$ | Reais (sem `NA`) | `log(ena_mwmed)` para normalizar e estabilizar variância (D32) |
| `oni_lag4`, `oni_lag5` | Índice ONI defasado em 4 e 5 meses | Quantitativa contínua | °C | Reais (sem `NA`) | `ANOM` pelo mês central (D24) com defasagens de 4 e 5 meses (D33) |
| `precip_mm_h_lag1`, `precip_mm_h_lag2` | Precipitação horária média mensal da bacia defasada em 1 e 2 meses | Quantitativa contínua | mm/h | Reais $\ge 0$ (sem `NA`) | Média simples das estações com $\ge 75\%$ de horas válidas (D35, D36) com *lags* 1 e 2 (D34) |
| `umid_pct_lag1` | Umidade relativa média mensal da bacia defasada em 1 mês | Quantitativa contínua | % | Reais em $[0, 100]$ (sem `NA`) | Média simples das estações válidas (D35, D36) com *lag* 1 (D34) |
| `temp_c_lag1`, `temp_c_lag2` | Temperatura média mensal da bacia defasada em 1 e 2 meses | Quantitativa contínua | °C | Reais (sem `NA`) | Média simples das estações válidas (D35, D36) com *lags* 1 e 2 (D34) |
| `mes_02` … `mes_12` | Variáveis indicadoras (*dummies*) do mês do ano | Qualitativa binária | — | `0` ou `1` (referência: janeiro) | Criadas a partir de `mes` (D34, D38) |

---

## 3. Cópia de trabalho mensal (`data/processed/`, EAP 3.1, D28)

Gerada por `Rscript R/02_base_mensal.R`. Os dados ainda **não foram limpos**: nenhum mês foi descartado nem preenchido. Os 12 meses de teste (nov/2025 a out/2026) estão nas tabelas, mas não devem ser olhados até a avaliação dos modelos (D30).

| Arquivo | Coluna | Descrição | Tipo | Unidade |
|---|---|---|---|---|
| `ena_mensal.csv` | `ano_mes` | Mês (`AAAA-MM`), de 2010-01 a 2026-10 | Data | — |
| | `ena_mwmed` | Média dos valores diários de ENA bruta da bacia GRANDE | Quantitativa contínua | MWmed |
| | `n_dias` | Dias com dado no mês | Quantitativa discreta | dias |
| `oni_mensal.csv` | `ano_mes` | Mês central do trimestre (`AAAA-MM`), de 2000-01 ao último publicado | Data | — |
| | `oni` | Índice ONI (`ANOM`) | Quantitativa contínua | °C |
| `inmet_estacao_mes.csv` | `codigo` | Código WMO da estação (ex.: `A516`) | Qualitativa nominal | — |
| | `ano_mes` | Mês (`AAAA-MM`, pela hora UTC), desde 2009-01 (2009 serve só de histórico para as defasagens, D31) | Data | — |
| | `precip_mm_h` | Média das precipitações horárias válidas do mês (× horas do mês = total mensal) | Quantitativa contínua | mm/h |
| | `temp_c` | Média das temperaturas horárias válidas (bulbo seco) | Quantitativa contínua | °C |
| | `umid_pct` | Média das umidades relativas horárias válidas | Quantitativa contínua | % |
| | `horas_precip`, `horas_temp`, `horas_umid` | Horas com valor válido de cada variável no mês | Quantitativa discreta | horas |
| | `horas_mes` | Horas que o mês tem (672 a 744) | Quantitativa discreta | horas |
| `inmet_estacoes.csv` | `codigo`, `estacao`, `uf` | Código, nome e UF da estação | Qualitativa nominal | — |
| | `latitude`, `longitude`, `altitude_m` | Localização da estação | Quantitativa contínua | graus, m |
| | `primeiro_mes` | Primeiro mês com arquivo no período | Data | — |
