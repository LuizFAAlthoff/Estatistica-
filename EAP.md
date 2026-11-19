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
- [x] **1.7 Critérios de avaliação** – últimos 12 meses como teste; EAM e RMSE (D08, D09). O α ficou adiado para D17.

**Entregável:** *Documento de definição do problema* (1 página).

## 2. Obter os Dados

- [ ] **2.1 Identificar fontes** – dados públicos (IBGE, DATASUS, INEP, Kaggle…), coleta própria (questionário) ou base fornecida
- [ ] **2.2 Plano amostral** – tipo de amostragem, tamanho da amostra, cálculo de *n* (se coleta própria)
- [ ] **2.3 Verificar adequação dos dados** – qualitativa (têm as variáveis certas?) e quantitativamente (*n* suficiente?)
- [ ] **2.4 Aquisição e armazenamento** – baixar/coletar, converter para formato conveniente (CSV), guardar versão bruta intocada
- [ ] **2.5 Ética e sensibilidade** – anonimizar dados pessoais, licença de uso, TCLE se houver questionário
- [ ] **2.6 Dicionário de dados** – nome, descrição, tipo, unidade, valores possíveis
- [ ] **2.7 Automatizar a obtenção** – script que baixa/lê os dados do zero

**Entregável:** base bruta + dicionário de dados + script de obtenção.

## 3. Análise Exploratória *(Explorar os Dados)*

- [ ] **3.1 Cópia de trabalho** – explorar sobre uma cópia; documentar em notebook
- [ ] **3.2 Perfil de cada variável** – tipo (qualitativa nominal/ordinal, quantitativa discreta/contínua), % ausentes, valores discrepantes, relevância
- [ ] **3.3 Estatística descritiva univariada** – média, mediana, moda, desvio-padrão, quartis, assimetria, curtose; tabelas de frequência
- [ ] **3.4 Distribuições** – histogramas, boxplots, gráficos de barras, QQ-plots (normal? log-normal? assimétrica?)
- [ ] **3.5 Análise bivariada** – correlações (Pearson/Spearman), tabelas de contingência, boxplots por grupo, dispersão
- [ ] **3.6 Insights e transformações promissoras** – o que sugere a exploração? Falta algum dado extra?

**Entregável:** notebook de EDA + resumo de achados (bullet points).

## 4. Preparar os Dados

- [ ] **4.1 Limpeza**
  - remover variáveis irrelevantes
  - tratar *outliers* (corrigir, remover ou manter com justificativa)
  - tratar ausentes (excluir, imputar por média/mediana/moda)
  - corrigir inconsistências e remover duplicatas
- [ ] **4.2 Transformação**
  - recodificar categóricas (variáveis *dummy*; cuidado com ordinais)
  - discretizar contínuas em faixas, se útil (amplitudes iguais, quantis)
  - decompor/agregar variáveis (ex.: data → ano/mês; criar índices)
  - transformações (log, √x) para normalizar ou estabilizar variância
  - padronização (*z-score*) ou min-max, quando necessário
- [ ] **4.3 Base analítica final** – salvar versão limpa separada da bruta
- [ ] **4.4 Documentar e automatizar** – funções/script para cada transformação (reprodutibilidade)

**Entregável:** base limpa + script de preparação + log das decisões de limpeza.

## 5. Inferência e Modelagem *(Treinar o Modelo)*

- [ ] **5.1 Escolher as técnicas por pergunta de pesquisa** – ex.:
  - comparar médias: teste t, ANOVA (ou Mann-Whitney, Kruskal-Wallis)
  - associação entre categóricas: qui-quadrado, Fisher
  - relação entre quantitativas: correlação, regressão linear
  - resposta binária: regressão logística
- [ ] **5.2 Estimação** – estimativas pontuais e intervalos de confiança
- [ ] **5.3 Testes de hipótese** – estatística de teste, p-valor, decisão ao nível α
- [ ] **5.4 Ajustar modelos candidatos** – mais de uma especificação, quando fizer sentido
- [ ] **5.5 Comparar e interpretar** – tamanho de efeito, coeficientes, variáveis mais relevantes

**Entregável:** notebook de análise com resultados de cada pergunta.

## 6. Validar e Refinar *(Ajustar o Modelo)*

- [ ] **6.1 Verificar pressupostos** – normalidade (Shapiro-Wilk, QQ-plot), homocedasticidade (Levene, Breusch-Pagan), independência, multicolinearidade (VIF)
- [ ] **6.2 Diagnóstico de resíduos e pontos influentes** (se houver regressão)
- [ ] **6.3 Seleção do modelo final** – AIC/BIC, R² ajustado, parcimônia
- [ ] **6.4 Alternativas quando pressupostos falham** – testes não paramétricos, transformações, *bootstrap*
- [ ] **6.5 Correções e robustez** – comparações múltiplas (Bonferroni/Holm), análise de sensibilidade
- [ ] **6.6 Validação preditiva** *(opcional, se o objetivo for prever)* – treino/teste ou validação cruzada

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
| 2. Obter os Dados       | 20/11 | 20/11 | ⬜ |
| 3. Análise Exploratória | 20/11 | 20/11 | ⬜ |
| 4. Preparar os Dados    | 20/11 | 21/11 | ⬜ |
| 5. Modelagem            | 21/11 | 22/11 | ⬜ |
| 6. Validar e Refinar    | 22/11 | 22/11 | ⬜ |
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

Ver o [README](README.md) (próximos passos) e as decisões adiadas D17 e D20 em [docs/decisoes.md](docs/decisoes.md).
