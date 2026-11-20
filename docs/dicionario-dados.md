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
- **Filtro aplicado:** `nom_bacia == "GRANDE"`.

| Variável | Tipo | Unidade / Formato | Descrição | Uso no projeto |
|---|---|---|---|---|
| `nom_bacia` | Qualitativa nominal | Texto | Nome da bacia hidrográfica | Filtro (`GRANDE`) |
| `ena_data` | Data | `AAAA-MM-DD` | Data da observação diária | Chave temporal (agregação mensal) |
| `ena_bruta_bacia_mwmed` | Quantitativa contínua | MWmed | Energia Natural Afluente bruta da bacia | **Variável resposta (D05)** |
| `ena_bruta_bacia_percentualmlt` | Quantitativa contínua | % | ENA bruta expressa em percentual da Média de Longo Termo (MLT) | Descartada (remove sazonalidade, D05) |
| `ena_armazenavel_bacia_mwmed` | Quantitativa contínua | MWmed | Parcela da ENA passível de armazenamento nos reservatórios | Descartada |
| `ena_armazenavel_bacia_percentualmlt` | Quantitativa contínua | % | Parcela armazenável em percentual da MLT | Descartada |

---

### 1.2 CPC/NOAA — Índice ONI (*Oceanic Niño Index*) (D13, D24)

- **Fonte:** Climate Prediction Center / NOAA (`oni.ascii.txt`).
- **Formato:** texto delimitado por espaços, com cabeçalho, cobertura a partir de DJF/1950 até ASO/2026 (set/2026).

| Variável | Tipo | Unidade / Formato | Descrição | Uso no projeto |
|---|---|---|---|---|
| `SEAS` | Qualitativa ordinal | Texto (`DJF`, `JFM`, …, `NDJ`) | Trimestre móvel de 3 meses | Conversão para o **mês central** (D24) |
| `YR` | Quantitativa discreta | Ano (`AAAA`) | Ano de referência do trimestre | Chave temporal |
| `TOTAL` | Quantitativa contínua | °C | Temperatura média da superfície do mar na região Niño 3.4 | Descartada |
| `ANOM` | Quantitativa contínua | °C | Anomalia de temperatura (índice **ONI**: ≥ +0,5 El Niño; ≤ −0,5 La Niña) | **Variável explicativa candidata (D15)** |

**Regras de conversão e uso:**
- Cada trimestre é mapeado para seu mês central (`DJF` → jan, `JFM` → fev, …, `NDJ` → dez).
- Atenção ao trimestre `NDJ`: o ano em `YR` corresponde ao início do trimestre (ex.: `NDJ/2025` refere-se a nov/2025–jan/2026 e deve ser atribuído a **dez/2025**).
- Por ser uma média móvel centrada, o valor do mês $t$ só é publicado ao fim do mês $t+1$ (atraso de 1 mês considerado na escolha da defasagem, D14/D24).

---

### 1.3 INMET — Estações Meteorológicas Automáticas (D19, D25)

- **Fonte:** Instituto Nacional de Meteorologia (arquivos anuais de *Dados Históricos*, `2010.zip` a `2026.zip`).
- **Formato:** um CSV por estação por ano, codificação `latin-1`, separador `;`, decimal `,`, 8 linhas iniciais de metadados (região, UF, estação, código WMO, latitude, longitude, altitude, data de fundação) seguidas por registros horários.
- **Valores ausentes:** codificados como `-9999` ou campo vazio (`""`).
- **Cobertura espacial (D25, D27):** 19 estações automáticas na bacia do Rio Grande — 12 com dados desde jan/2010, 1 desde jun/2010 (Barretos) e 6 iniciadas entre 2015 e 2019 (incluídas a partir da disponibilidade, D27).

| Variável bruta (horária) | Tipo | Unidade / Formato | Descrição | Status / Candidata (D20) |
|---|---|---|---|---|
| `Data` | Data | `AAAA/MM/DD` | Data do registro | Chave temporal |
| `Hora UTC` | Hora | `HHMM UTC` | Hora da leitura em tempo universal | Chave temporal |
| Precipitação total | Quantitativa contínua | mm | Volume de chuva acumulado na hora | **Candidata principal** |
| Temperatura do ar (bulbo seco, máx., mín.) | Quantitativa contínua | °C | Temperatura do ar na hora, máxima e mínima horária | **Candidata** (evaporação) |
| Umidade relativa (na hora, máx., mín.) | Quantitativa contínua | % | Umidade relativa do ar | **Candidata** (evaporação) |
| Radiação global | Quantitativa contínua | kJ/m² | Radiação solar incidente na hora | A avaliar na etapa 3 |
| Pressão atmosférica (na hora, máx., mín.) | Quantitativa contínua | mB | Pressão atmosférica no nível da estação | A avaliar na etapa 3 |
| Temperatura do ponto de orvalho (na hora, máx., mín.) | Quantitativa contínua | °C | Temperatura de condensação do vapor d'água | A avaliar na etapa 3 |
| Vento (velocidade, rajada máx., direção) | Quantitativa contínua | m/s, ° | Velocidade, rajada máxima e direção do vento | A avaliar na etapa 3 |

---

## 2. Base Analítica Consolidada (`data/processed/`) — Estrutura Prevista

Tabela mensal final usada nos modelos de suavização, ARIMA/SARIMA, ingênuo sazonal e regressão (a ser fechada após a Etapa 3 — análise exploratória).

| Variável (sugestão de nome) | Tipo | Unidade | Regra de agregação / construção | Pendência vinculada |
|---|---|---|---|---|
| `ano_mes` | Data | `AAAA-MM` | Índice mensal (`2010-01` a `2026-10`) | Definida (D26) |
| `ena_mwmed` | Quantitativa contínua | MWmed | Média mensal dos valores diários de `ena_bruta_bacia_mwmed` | Transformação (`log`/Box-Cox) a avaliar em **D05** |
| `oni_lag_k` | Quantitativa contínua | °C | Valor de `ANOM` defasado em $k$ meses | Defasagem $k$ a definir em **D14** |
| `precip_mm_lag_k` | Quantitativa contínua | mm | Soma mensal por estação → agregação entre estações, defasada em $k$ meses | Agregação (média simples vs. anomalia, **D27**) e defasagens (**D20**) |
| `temp_c_lag_k` | Quantitativa contínua | °C | Média mensal por estação → agregação entre estações, defasada em $k$ meses | Seleção e defasagens em **D20** |
| `umid_pct_lag_k` | Quantitativa contínua | % | Média mensal por estação → agregação entre estações, defasada em $k$ meses | Seleção e defasagens em **D20** |
| `mes_02` … `mes_12` | Qualitativa binária (dummy) | `0` ou `1` | Indicadoras de mês (referência: janeiro) | Inclusão a avaliar considerando multicolinearidade (**D20**) |

---

## 3. Pontos de Atenção para a Limpeza (Etapa 4)

1. **Quebra na lista de bacias do ONS:** conferir na série completa se não há salto abrupto na `GRANDE` na virada de 2025 para 2026 (quando novas bacias entraram no arquivo do ONS).
2. **Dados faltantes no INMET:** entre 3% e 31% das horas nas 19 estações têm chuva ausente (`-9999` ou vazio). Definir regra mínima de horas válidas por mês para não subestimar a soma mensal de precipitação.
3. **Entrada escalonada de estações (D27):** avaliar na etapa 3/4 se a entrada das 6 estações de 2015–2019 cria degrau artificial na média da bacia e definir o método de agregação (média simples vs. anomalias por estação).
