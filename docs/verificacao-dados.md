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

## 2. Base Analítica Consolidada (`data/processed/`) — Estrutura Prevista

Tabela mensal final usada nos modelos (os valores de $k$ e a inclusão final de cada variável serão fechados na Etapa 3 — decisões **D05**, **D14**, **D20** e **D27**).

| Nome (sugestão) | Descrição | Tipo | Unidade | Valores possíveis | Regra de construção |
|---|---|---|---|---|---|
| `ano_mes` | Mês de referência da observação | Data | `AAAA-MM` | `2010-01` a `2026-10` (~202 meses) | Índice mensal contínuo (D26) |
| `ena_mwmed` | ENA bruta média mensal da bacia do Rio Grande | Quantitativa contínua | MWmed | Reais $> 0$ (sem `NA`) | Média mensal dos valores diários do ONS; transformação a avaliar (D05) |
| `oni_lag_k` | Índice ONI defasado em $k$ meses | Quantitativa contínua | °C | Reais (tipicamente −2,5 a +2,6) | `ANOM` convertido para mês central e defasado em $k$ meses (D14) |
| `precip_mm_lag_k` | Precipitação mensal agregada da bacia defasada em $k$ meses | Quantitativa contínua | mm | Reais $\ge 0$ (ou reais positivos/negativos, se agregada como anomalia) | Soma mensal por estação → agregação entre estações (D27) → lag $k$ (D20) |
| `temp_c_lag_k` | Temperatura média mensal da bacia defasada em $k$ meses | Quantitativa contínua | °C | Reais (tipicamente 10 a 35 °C, ou anomalia em °C) | Média mensal por estação → agregação entre estações → lag $k$ (D20) |
| `umid_pct_lag_k` | Umidade relativa média mensal da bacia defasada em $k$ meses | Quantitativa contínua | % | Reais de `0` a `100` (ou anomalia em p.p.) | Média mensal por estação → agregação entre estações → lag $k$ (D20) |
| `mes_02` … `mes_12` | Variáveis indicadoras (*dummies*) do mês do ano | Qualitativa binária | — | `0` ou `1` (referência: janeiro) | Criadas a partir de `ano_mes`; inclusão sujeita à análise de multicolinearidade (D20) |
