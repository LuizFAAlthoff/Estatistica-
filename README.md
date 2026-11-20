# Previsão da ENA da Bacia do Rio Grande

Trabalho da disciplina **INE5649 – Técnicas Estatísticas de Predição** (UFSC, Prof. Adriano Ferreti Borgatto).

**Grupo:** Bruno, Francisco, Jullya e Luiz
**Entrega:** **24/11/2026**, resumo expandido em PDF no Moodle (só um integrante posta).

> **Estado atual (19/11):** a etapa 1 (definição do problema) está concluída. Na etapa 2, as fontes estão definidas (D22, D24, D25), os dados foram verificados ([docs/verificacao-dados.md](docs/verificacao-dados.md)) e o download está automatizado (`R/01_baixar_dados.R`).

---

## 1. O que é o trabalho

O enunciado completo está em **[docs/enunciado.md](docs/enunciado.md)**. O professor pede um **resumo expandido** (até 12 páginas, mais um anexo com o código R) analisando **uma série temporal real** com **todos os modelos vistos na disciplina** que se apliquem aos dados. Os modelos que não se aplicarem precisam de uma justificativa técnica.

O grupo escolheu a **ENA – Energia Natural Afluente** da **bacia do Rio Grande**. A ENA mede a água que chega aos reservatórios das hidrelétricas, convertida em energia. Os dados são públicos e vêm do ONS (Operador Nacional do Sistema Elétrico). Por ser uma variável hidrológica, ela tem um ciclo sazonal forte (período chuvoso e período seco) e pode sofrer influência do El Niño/La Niña.

## 2. O que já foi decidido

Cada decisão está registrada com alternativas e justificativa em **[docs/decisoes.md](docs/decisoes.md)** (D01–D31). Esse arquivo vai servir de base para a seção *Materiais e métodos*. Resumo:

| Item | Decisão |
|------|---------|
| Variável estudada | **ENA bruta** da bacia do Rio Grande, em MWmed. Os dados diários do ONS são convertidos para **média mensal**. |
| Período | De **jan/2010** até o **último mês completo** disponível (D26; antes de 2010 quase não há estações automáticas do INMET na bacia) |
| Teste | Os **últimos 12 meses** (nov/2025 a out/2026) ficam separados e **cegos**: ninguém olha nem decide nada com base neles até a avaliação dos modelos (D30) |
| Métricas | **EAM** (erro absoluto médio) e **RMSE** (raiz do erro quadrático médio) |
| Modelos | Regressão; SES, Holt, Holt-Winters, ETS; AR, MA, ARIMA, SARIMA; mais o **ingênuo sazonal** como referência mínima |
| Regressão | Usada para **previsão**, com variáveis **meteorológicas do INMET** e o índice **ONI** (El Niño) **com defasagem** (valores de meses anteriores) |
| Ferramentas | **R** + **R Markdown** → DOCX → PDF (Arial 11, espaçamento 1,5, margens de 2 cm) |

**Objetivos específicos**
1. Ajustar todos os modelos da disciplina que se aplicam e justificar os que não se aplicam.
2. Comparar as previsões nos últimos 12 meses (EAM e RMSE), usando o ingênuo sazonal como referência.
3. Verificar se o clima de meses anteriores (INMET) ajuda a prever a ENA.
4. Verificar se o El Niño/La Niña (ONI) ajuda a prever a ENA.
5. Discutir por que cada modelo funciona melhor ou pior com essa série.

## 3. O que ainda está em aberto

Estes pontos dependem de conhecer os dados e serão decididos nas próximas etapas:

- **D20:** quais variáveis o INMET disponibiliza e quais entram; qual **região** usar (só a bacia ou também regiões como a Amazônia); quais **defasagens** usar; se entram ***dummies* de mês** na regressão (variáveis 0/1 que indicam o mês).
- **D14:** a defasagem do ONI, escolhida pela maior correlação com a ENA.
- **D17:** o critério para manter ou tirar variáveis da regressão (teste t, ANOVA, AIC) e o nível de significância.
- **D05:** a necessidade de transformar a série (por exemplo, com logaritmo).

## 4. Próximos passos

O plano completo, etapa por etapa, está na **[EAP.md](EAP.md)**.

| Quando | Etapa | O que fazer |
|--------|-------|-------------|
| 20/11 | 2. Obter os dados | Baixar a ENA (ONS), os dados do INMET e o ONI (NOAA); montar o dicionário de dados |
| 20/11 | 3. Análise exploratória | Gráficos, decomposição, estacionariedade, correlações e defasagens; resolver D14, D20 e D05 |
| 21/11 | 4. Preparar os dados | Base mensal final; separação em treino e teste |
| 21–22/11 | 5–6. Modelos | Suavização (SES, Holt, Holt-Winters, ETS); AR, MA, ARIMA, SARIMA; regressão (resolver D17); ingênuo sazonal |
| 22–23/11 | 7. Redação | Introdução, Métodos, comparação dos modelos, Resultados e discussões, Considerações finais |
| 24/11 | Entrega | Gerar o PDF final e postar no Moodle |

> A divisão de tarefas entre os membros ainda não foi combinada. Os modelos só podem começar depois que a base de dados estiver pronta.

## 5. Organização do repositório

```
├── README.md          ← este arquivo
├── EAP.md             ← plano do projeto (etapas e pacotes de trabalho)
├── docs/
│   └── decisoes.md    ← registro de todas as decisões (base para "Materiais e métodos")
├── data/
│   ├── raw/           ← dados brutos baixados (nunca editar à mão)
│   └── processed/     ← dados tratados
├── R/                 ← scripts R (obtenção, preparação, modelos)
├── notebooks/         ← arquivos R Markdown
└── output/            ← figuras e tabelas
```

## 6. Como colaborar

1. Clone o repositório: `git clone https://github.com/LuizFAAlthoff/Estatistica-.git`
2. Antes de começar, rode **`git pull`** para pegar a versão mais recente.
3. **Baixe os dados** (só na primeira vez; leva alguns minutos e ocupa ~1,5 GB). Na pasta raiz do repositório, rode `Rscript R/01_baixar_dados.R`, ou abra o arquivo no RStudio e clique em *Source*. Os dados ficam em `data/raw/`, que não vai para o GitHub.
4. Mexa nos arquivos do seu bloco, faça commits pequenos com mensagens claras e envie com `git push`.
5. **Toda transformação de dados é feita por um script em `R/` e commitada** junto com os arquivos que ele gera (D29). As regras completas, que também valem para as IAs, estão no **[AGENTS.md](AGENTS.md)**. Para recriar a base mensal, rode `Rscript R/02_base_mensal.R`.
6. Toda decisão nova (variável, defasagem, transformação, modelo descartado) vai para o **[docs/decisoes.md](docs/decisoes.md)** com uma justificativa, para não se perder na hora de escrever o resumo.
