# EAP – Trabalho de Estatística

> Estrutura Analítica do Projeto (EAP) adaptada do *Fluxo de Projeto de Aprendizado de Máquina* (INE5664, Prof. Eduardo Camilo Inacio – UFSC) para um projeto de **análise estatística**.
>
> **Como usar:** cada pacote de trabalho (nível 3) é uma unidade que vamos fechar em uma ou mais interações. Marque `[x]` quando concluir e registre as decisões na seção **Registro de Decisões**, no final.

## Mapeamento ML → Estatística

| # | Etapa no slide (ML)        | Etapa neste projeto (Estatística)               |
|---|----------------------------|-------------------------------------------------|
| 1 | Observar o Panorama Geral  | Definir o Problema e as Perguntas de Pesquisa   |
| 2 | Obter os Dados             | Obter os Dados (fonte, amostragem, dicionário)  |
| 3 | Explorar os Dados          | Análise Exploratória (estatística descritiva)   |
| 4 | Preparar os Dados          | Preparar os Dados (limpeza e transformação)     |
| 5 | Treinar o Modelo           | Inferência e Modelagem Estatística              |
| 6 | Ajustar o Modelo           | Validar e Refinar (pressupostos, diagnóstico)   |
| 7 | Entregar e Implantar       | Comunicar os Resultados (relatório/apresentação)|

O que **não** se transfere ao pé da letra:
- **Conjunto de teste reservado** → em estatística, o equivalente é **definir hipóteses e testes *antes* de olhar os dados** (evita *p-hacking* / *data snooping*). Se houver modelo preditivo, aí sim vale separar treino/teste.
- **Hiperparâmetros / Grid Search** → vira **seleção de modelo** (escolha de variáveis, transformações, AIC/BIC, testes alternativos).
- **Implantar em produção / monitorar** → vira **entrega do relatório, apresentação e reprodutibilidade** (código e dados organizados).

---

## 0. Gerenciamento do Projeto

- [x] **0.1 Escopo e requisitos da disciplina** – enunciado, critérios de avaliação, formato de entrega, prazo
- [ ] **0.2 Equipe e responsabilidades** – membros definidos (Bruno, Francisco, Jullya, Luiz); a divisão de tarefas ainda não foi combinada
- [x] **0.3 Cronograma** – datas-alvo por etapa (ver tabela abaixo)
- [x] **0.4 Ambiente e ferramentas** – R, R Markdown e repositório no GitHub

**Entregável:** este documento preenchido + estrutura de pastas do projeto.

## 1. Definir o Problema *(Observar o Panorama Geral)*

- [x] **1.1 Tema e contexto** – ENA da bacia do Rio Grande (D03)
- [x] **1.2 Objetivo geral e objetivos específicos** – prever e explicar (D06, D21)
- [x] **1.3 Perguntas de pesquisa** – transformadas em objetivos específicos (D21)
- [x] **1.4 Hipóteses** – não haverá seção de hipóteses (D21)
- [x] **1.5 Variáveis de interesse** – ENA bruta mensal em MWmed; explicativas: INMET e ONI defasados (D05, D07, D13)
- [x] **1.6 Tipo de estudo** – observacional, longitudinal, dados secundários (D16)
- [x] **1.7 Critérios de avaliação** – últimos 12 meses como teste; EAM e RMSE (D08, D09). α = 5% nos testes F (D39).

**Entregável:** *Documento de definição do problema* (1 página).

## 2. Obter os Dados

- [x] **2.1 Identificar fontes** – ENA diária por bacia (ONS), estações convencionais do INMET via BDMEP e ONI do CPC/NOAA (D22–D24)
- [x] **2.2 Plano amostral** – não se aplica: são dados secundários e a série é usada inteira, sem sorteio nem coleta própria. A cobertura é definida pelo período (D26) e pelas estações (D25, D27).
- [x] **2.3 Verificar adequação dos dados** – ENA (sem mudança de patamar em 2026) e ONI verificados; INMET: estações automáticas desde 2010 (D25, D26), com classificação aproximada das estações na bacia (ver [docs/verificacao-dados.md](docs/verificacao-dados.md))
- [x] **2.4 Aquisição e armazenamento** – dados brutos em `data/raw/` (ons, noaa, inmet), fora do Git
- [x] **2.5 Ética e sensibilidade** – não se aplica: são dados públicos e agregados (ONS, NOAA, INMET), sem dados pessoais nem questionário, então não há anonimização, TCLE nem comitê de ética (D16). Basta citar as fontes nas Referências.
- [x] **2.6 Dicionário de dados** – nome, descrição, tipo, unidade, valores possíveis
- [x] **2.7 Automatizar a obtenção** – `R/01_baixar_dados.R` baixa ENA, ONI e INMET de 2010 até o ano atual

**Entregável:** base bruta + dicionário de dados + script de obtenção.

## 3. Análise Exploratória *(Explorar os Dados)*

- [x] **3.1 Cópia de trabalho** – `R/02_base_mensal.R` gera as tabelas mensais em `data/processed/` (ENA e INMET: média mensal dos valores diários/horários; ONI pelo mês central; sem limpeza, com o nº de horas válidas de cada estação e mês)
- [x] **3.2 Perfil de cada variável** – tipo (qualitativa nominal/ordinal, quantitativa discreta/contínua), % ausentes, valores discrepantes, relevância
- [x] **3.3 Estatística descritiva univariada** – média, mediana, moda, desvio-padrão, quartis, assimetria, curtose; tabelas de frequência
- [x] **3.4 Distribuições** – histogramas, boxplots, gráficos de barras, QQ-plots (normal? log-normal? assimétrica?)
- [x] **3.5 Análise bivariada** – correlações (Pearson/Spearman), tabelas de contingência, boxplots por grupo, dispersão
- [x] **3.6 Insights e transformações promissoras** – o que sugere a exploração? Falta algum dado extra?

*Feito em `notebooks/01_eda.Rmd`, só com o treino (D30). Decisões: D32 (modelar em `log(ENA)`), D33 (ONI com defasagem de 4 e 5 meses), D34 (chuva, umidade e temperatura defasadas e *dummies* de mês), D35 (média simples das 19 estações) e D40 (só estações da bacia; a Amazônia fica fora).*

**Entregável:** notebook de EDA + resumo de achados (bullet points).

## 4. Preparar os Dados

- [x] **4.1 Limpeza**
  - remover variáveis irrelevantes
  - tratar *outliers* (corrigir, remover ou manter com justificativa)
  - tratar ausentes (excluir, imputar por média/mediana/moda)
  - corrigir inconsistências e remover duplicatas
- [x] **4.2 Transformação**
  - recodificar categóricas (variáveis *dummy*; cuidado com ordinais)
  - discretizar contínuas em faixas, se útil (amplitudes iguais, quantis)
  - decompor/agregar variáveis (ex.: data → ano/mês; criar índices)
  - transformações (log, √x) para normalizar ou estabilizar variância
  - padronização (*z-score*) ou min-max, quando necessário
- [x] **4.3 Base analítica final** – salvar versão limpa separada da bruta
- [x] **4.4 Documentar e automatizar** – funções/script para cada transformação (reprodutibilidade)

*Feito em `R/03_preparar_dados.R`, que gera `data/processed/base_analitica.{csv,rds}` (202 meses, sem ausentes). Decisões: D36 (mínimo de 75% de horas válidas), D37 (manter extremos reais) e D38 (*dummies* de mês e escala das preditoras).*

**Entregável:** base limpa + script de preparação + log das decisões de limpeza.

## 5. Inferência e Modelagem *(Treinar o Modelo)*

- [x] **5.1 Escolher as técnicas por objetivo** – ingênuo sazonal (D18); regressão em `log_ena` com clima e ONI defasados e *dummies* de mês; SES, Holt, Holt-Winters aditivo e multiplicativo, ETS; AR, MA, ARIMA e SARIMA (`notebooks/02_modelagem.Rmd`, seção 5.1)
- [x] **5.2 Estimação** – coeficientes e intervalos de confiança de 95% da regressão *(executado em 22/11)*
- [x] **5.3 Testes de hipótese** – testes t dos coeficientes e três testes F (ANOVA) para os objetivos 3 e 4, com α = 5%; seleção de variáveis só pelo AIC (D39) *(executado em 22/11)*
- [x] **5.4 Ajustar modelos candidatos** – todos os modelos acima, só no treino *(`R/04_modelagem.R`, executado em 22/11)*
- [x] **5.5 Comparar e interpretar** – comparação no treino por AIC, BIC, EAM e RMSE *(executado em 22/11; `output/resumo_modelos_treino.csv`)*; a comparação no teste fica na 6.6

**Entregável:** notebook de análise com resultados de cada pergunta.

## 6. Validar e Refinar *(Ajustar o Modelo)*

- [x] **6.1 Verificar pressupostos** – normalidade (Shapiro-Wilk, QQ-plot), homocedasticidade (Levene, Breusch-Pagan), independência, multicolinearidade (VIF) *(feito em `R/05_diagnostico_residuos.R`: independência por Ljung-Box e normalidade por Shapiro-Wilk em todos os modelos; VIF da regressão em `notebooks/02_modelagem.Rmd`. A homocedasticidade não foi testada formalmente; o `log(ENA)` da D32 trata a variância)*
- [x] **6.2 Diagnóstico de resíduos e pontos influentes** (se houver regressão) *(gráficos em `output/residuos_*.png`; só a regressão comum deixa padrão nos resíduos, D42)*
- [x] **6.3 Seleção do modelo final** – AIC/BIC, R² ajustado, parcimônia *(regressão: AIC, D39 e D42)*
- [x] **6.4 Alternativas quando pressupostos falham** – testes não paramétricos, transformações, *bootstrap* *(regressão com erros ARIMA, D42)*
- [ ] **6.5 Correções e robustez** – comparações múltiplas (Bonferroni/Holm), análise de sensibilidade *(há código em `R/05_validar_modelos.R`, ainda não conferido pelo grupo; ver pendências)*
- [x] **6.6 Validação preditiva** – previsão dos 12 meses de teste e cálculo de EAM e RMSE (D08, D09). Método: **janela rolante de 1 mês**, com o modelo congelado no treino (D41) *(feito em `R/06_avaliacao_teste.R`: os 18 modelos superam o ingênuo sazonal; as regressões com clima lideram pelo RMSE, em torno de 1.040 MWmed, e a regressão com erros ARIMA (D42) tem o menor EAM, 528 MWmed. Fev/2026, um mês extremo, responde pela maior parte do erro quadrático de todos os modelos. Tabelas e gráficos em `output/*teste_rolante*`)*

**Entregável:** resultados finais validados + justificativa do modelo escolhido.

## 7. Comunicar os Resultados *(Entregar e Implantar)*

- [ ] **7.1 Relatório final** – introdução, metodologia, resultados, discussão, conclusão, referências
- [ ] **7.2 Visualizações finais** – gráficos limpos e autoexplicativos
- [ ] **7.3 Discussão crítica** – como os resultados respondem às perguntas; o que funcionou e o que não funcionou; suposições e limitações
- [ ] **7.4 Apresentação** – slides com mensagens "fáceis de lembrar"
- [ ] **7.5 Reprodutibilidade** – código, dados e README organizados para quem for avaliar

**Entregável:** relatório + slides + pasta do projeto reprodutível.

---

## Cronograma

| Etapa | Início | Fim | Status |
|-------|--------|-----|--------|
| 0. Gerenciamento        | 19/11 | 19/11 | ✅ |
| 1. Definir o Problema   | 19/11 | 19/11 | ✅ |
| 2. Obter os Dados       | 20/11 | 20/11 | ✅ |
| 3. Análise Exploratória | 20/11 | 20/11 | ✅ |
| 4. Preparar os Dados    | 20/11 | 21/11 | ✅ |
| 5. Modelagem            | 21/11 | 22/11 | ✅ |
| 6. Validar e Refinar    | 22/11 | 22/11 | 🔄 |
| 7. Comunicar Resultados | 22/11 | 24/11 | ⬜ |

## Estrutura de pastas sugerida

```
trabalhoestatistica/
├── EAP.md                 ← este documento
├── docs/                  ← definição do problema, dicionário de dados, relatório
├── data/
│   ├── raw/               ← dados brutos (nunca editar)
│   └── processed/         ← dados limpos
├── notebooks/             ← 01_eda, 02_analise, ...
├── R/                     ← scripts R de obtenção e preparação
└── output/                ← figuras e tabelas finais
```

## Registro de Decisões

Todas as decisões estão em [docs/decisoes.md](docs/decisoes.md).

## Pendências / Perguntas em aberto

Ver o [README](README.md) (seção 3) e as pendências no final de [docs/decisoes.md](docs/decisoes.md): o que fazer com `R/05_validar_modelos.R` e a redação (etapa 7).
