# Registro de Decisões do Projeto

> Este documento registra **todas as decisões** tomadas na definição e execução do trabalho, com a justificativa de cada uma.
> Ele é a base da seção **Materiais e métodos** do resumo expandido.
>
> Formato: cada decisão tem um código (`Dxx`), a data, a etapa da EAP a que pertence, o que foi decidido, as alternativas consideradas e a justificativa.

---

## Contexto fixo (vindo do enunciado da disciplina)

Fonte: *INSTRUÇÕES PARA FAZER O TRABALHO – INE5649*.

- **Disciplina:** INE5649 – Técnicas Estatísticas de Predição (Prof. Adriano Ferreti Borgatto).
- **Tema obrigatório:** problema real envolvendo **séries temporais**.
- **Modelos:** é obrigatório usar **todos os modelos da disciplina** que sejam adequados aos dados. Para cada modelo não aplicável, é preciso apresentar uma **justificativa técnica**. Outros modelos podem ser incluídos quando contribuírem para a análise.
- **Entrega:** resumo expandido em **PDF**, com no máximo **12 páginas** mais o anexo com a sintaxe do R. É postado no Moodle por **um** integrante.
- **Formatação:** Arial 11, espaçamento 1,5, margens de 2,0 cm.
- **Seções obrigatórias:**
  1. Título
  2. Identificação dos membros
  3. Introdução e objetivos
  4. Materiais e métodos
  5. Resultados e discussões
  6. Considerações finais
  7. Referências
  8. Anexo com a sintaxe R
- **Prazo:** **24/11/2026**. Atraso de até 24 h vale no máximo 8,0; depois disso a entrega não é aceita.

### Modelos de séries temporais vistos na disciplina (Aulas 22–25)

| Aula | Conteúdo |
|------|----------|
| 22 | Definições (tendência, sazonalidade, ciclo, erro); decomposição; **regressão** aplicada a séries temporais; separação treino/teste |
| 23 | **Suavização exponencial**: simples (SES), Holt, Holt-Winters aditivo e multiplicativo, ETS automático |
| 24 | Estacionariedade, autocorrelação (ACF), diferenciação, teste ADF; **modelo autorregressivo AR(p)** |
| 25 | **Médias móveis MA(q), ARIMA(p,d,q), SARIMA(p,d,q)(P,D,Q)s** |

Métricas de comparação usadas pelo professor: **EAM** (erro absoluto médio) e **RMSE** (raiz do erro quadrático médio).

---

## Decisões

| Código | Data | Etapa EAP | Decisão | Alternativas consideradas | Justificativa |
|--------|------|-----------|---------|---------------------------|---------------|
| D01 | 19/11/2026 | 0.4 | Usar a linguagem **R** para a análise. | Python | É a linguagem da disciplina; todo o material do professor está em R. |
| D02 | 19/11/2026 | 0.4 | Versionar o projeto com **Git**, num repositório no GitHub compartilhado com os 4 membros: `github.com/LuizFAAlthoff/Estatistica-`. O conteúdo atual do repositório será descartado e o projeto começará do zero nele. | Somente Git local | Os 4 membros vão contribuir com arquivos. |
| D03 | 19/11/2026 | 1.1 | **Tema:** Energia Natural Afluente (ENA) da **bacia do Rio Grande**, com dados do ONS (Operador Nacional do Sistema Elétrico). | Passageiros aéreos, combustíveis, dengue etc. | Escolha do grupo. É um fenômeno hidrológico, com ciclo sazonal e influência de fenômenos climáticos (El Niño/La Niña). |
| D04 | 19/11/2026 | 1.5 | **Frequência:** a série diária será trabalhada em escala **mensal**. | Diária | Na escala mensal o ciclo sazonal anual fica visível e os modelos da disciplina se aplicam diretamente (frequência 12). |
| D05 | 19/11/2026 | 1.5 | **Variável resposta:** **ENA bruta, em MWmed**. A necessidade de transformação (ex.: logaritmo) será avaliada mais adiante. | ENA em % da MLT (média de longo termo) | A % da MLT divide cada valor pela média histórica do mês, o que remove parte da sazonalidade por construção e prejudica os modelos sazonais exigidos. A ENA bruta mantém a unidade física de interesse. |
| D06 | 19/11/2026 | 1.2 | **Objetivo:** **prever** a ENA mensal e **explicar** o comportamento dos modelos, ou seja, por que cada modelo se sai melhor ou pior com essa série. Uma possível explicação climática (El Niño/La Niña) fica em aberto. | Somente previsão; somente explicação | O enunciado exige aplicar e comparar todos os modelos (previsão). A discussão de por que cada modelo funciona ou não dá profundidade à seção de Resultados e discussões. |
| D07 | 19/11/2026 *(revisada na rodada 7)* | 1.4 / 5 | **Regressão — papel e estrutura:** a regressão serve para **previsão**. As variáveis explicativas serão **meteorológicas** (INMET, ver D19) e o **ONI** (D13), **com defasagem temporal**: valores de meses anteriores explicam a ENA do mês seguinte. A escolha das variáveis meteorológicas, das defasagens e da inclusão ou não de *dummies* de mês fica para as etapas 2–3 (D20). | Versão original: tendência + *dummies* de mês + ONI defasado; clima do mesmo mês (explicativa) | Com variáveis defasadas, a regressão faz previsão real: no teste, ela só usa informação disponível antes do mês previsto, o que deixa a comparação com os outros modelos justa. Há também sentido físico: a chuva infiltra no solo e chega aos rios nos meses seguintes. |
| D08 | 19/11/2026 | 1.7 / 6 | **Validação:** reservar os **últimos 12 meses** da série como conjunto de **teste**. | 24 ou 36 meses | Doze meses correspondem a um ciclo hidrológico completo e seguem o exemplo da aula de suavização. |
| D09 | 19/11/2026 | 1.7 | **Métricas de comparação:** **EAM** e **RMSE**. | Incluir MAPE | São as métricas usadas pelo professor na disciplina. |
| D10 | 19/11/2026 *(substituída por D26)* | 1.5 | **Período:** de **janeiro de 2000** até o **último mês completo** disponível. Os 12 meses de teste (D08) são os 12 últimos meses completos. | Começar em 2014/2015; fechar em dezembro de 2025; incluir o mês corrente incompleto | Usa todo o histórico disponível. Um mês incompleto distorceria a média mensal justamente no período de teste. |
| D11 | 19/11/2026 | 7.1 | **Redação:** **R Markdown (`.Rmd`) → DOCX → PDF**. Um documento Word de referência aplicará a formatação exigida. | Markdown puro; Google Docs; LaTeX | Gráficos, tabelas e o anexo com a sintaxe R são gerados automaticamente a partir do código. Todos os membros têm R instalado. |
| D12 | 19/11/2026 *(revisada)* | 0.2 | **Divisão do trabalho:** o trabalho foi organizado em blocos (ver abaixo), mas **a atribuição de responsáveis ainda não foi combinada** com o grupo. | Atribuir nomes já na etapa 1 | A atribuição precisa ser acordada entre os membros. |
| D13 | 19/11/2026 | 1.5 / 2 | **Indicador do El Niño:** índice **ONI** (*Oceanic Niño Index*) da NOAA. | Niño 3.4 mensal sem suavização | É o índice oficial e o mais citado na literatura, o que facilita justificar e referenciar. |
| D14 | 19/11/2026 | 3 | **Defasagem do ONI:** escolhida na **análise exploratória**, usando a defasagem com **maior correlação** com a ENA. | Fixar um valor da literatura | Deixa os dados indicarem a defasagem relevante para a bacia do Grande. O valor escolhido será registrado como nova decisão. |
| D15 | 19/11/2026 *(revisada)* | 1.4 | **ONI como variável candidata:** o El Niño/La Niña entra na regressão como **candidato**. Se a seleção de variáveis (D17) não indicar relação, o ONI **sai do modelo final**, e esse resultado é relatado na discussão. | Tratar como hipótese formal a ser provada | O trabalho não terá seção de hipóteses (D21). A regressão não remove variáveis sozinha; o critério de remoção fica em D17. |
| D16 | 19/11/2026 | 1.6 | **Tipo de estudo:** **observacional** e **longitudinal** (série temporal), com **dados secundários públicos** (ONS, NOAA e INMET). | — | Não há intervenção nem coleta própria. Dados públicos dispensam aprovação de comitê de ética. |
| D17 | — | 5 | **Critério de seleção na regressão** (combinação de teste t, ANOVA e AIC; regra para quando discordarem; nível de significância α). **Adiado** para depois da definição das variáveis (D20). | — | O critério depende de quais variáveis entram no modelo. |
| D18 | 19/11/2026 | 5 | **Modelo de referência:** incluir o **ingênuo sazonal** (`snaive`), que prevê cada mês com o valor do mesmo mês no ano anterior. | Também a média sazonal; nenhum modelo de referência | O enunciado permite "outros modelos que contribuam". O ingênuo sazonal é a régua mínima: um modelo sofisticado só agrega valor se o superar. |
| D21 | 19/11/2026 | 1.3 / 1.4 | **Sem seção formal de hipóteses.** As questões do trabalho entram como **objetivos específicos** na seção "Introdução e objetivos". | Seção de hipóteses H1–H3 | O enunciado não exige hipóteses. Os testes de coeficientes da regressão continuam sendo usados, mas apenas como ferramenta de seleção de variáveis (D17). |
| D19 | 19/11/2026 | 2 | **Fonte dos dados meteorológicos:** **INMET** (Instituto Nacional de Meteorologia). A base de ENA do ONS não traz variáveis meteorológicas, então elas precisam ser cruzadas a partir de outra fonte. | Outras bases (NASA POWER, CHIRPS, ERA5) | Escolha do grupo: é a base oficial brasileira. Os detalhes (estações, região e variáveis disponíveis) ficam para a etapa 2. |
| D20 | 19/11/2026 | 2–3 | **Adiado para as etapas 2–3:** (a) quais variáveis meteorológicas existem no INMET e quais serão candidatas; (b) a **região** dos dados meteorológicos (só a bacia do Grande ou também regiões vizinhas, como a Amazônia); (c) as **defasagens** de cada variável; (d) se as ***dummies* de mês** entram, considerando a possível **multicolinearidade** com as variáveis meteorológicas. | Decidir agora | Essas decisões dependem de conhecer os dados, o que ainda não foi feito. |
| D22 | 19/11/2026 | 2.1 | **Conjunto de dados da ENA:** **ENA diária por bacia** do portal de dados abertos do ONS, usando a bacia **GRANDE**. A cobertura desde 2000 e os nomes dos campos serão conferidos no item 2.3. | ENA diária por reservatório (somando as usinas da bacia); ENA diária por REE | É o recorte que corresponde ao tema (D03) e já vem agregado. A soma por reservatório daria mais trabalho e poderia mudar ao longo do tempo com a entrada de novas usinas. O REE não corresponde só ao Rio Grande. |
| D23 | 19/11/2026 *(substituída por D25)* | 2.1 | **Dados meteorológicos:** **estações convencionais** do INMET, obtidas pelo **BDMEP** (Banco de Dados Meteorológicos do INMET) em escala **mensal**. Se faltarem meses, a solução será definida mais adiante (etapa 4, limpeza). A forma de acesso (download direto ou pedido) será conferida no item 2.3. | Estações automáticas (arquivos anuais de hora em hora) | O histórico das convencionais cobre todo o período desde 2000 (D10). Muitas automáticas só começaram por volta de 2006–2008, o que cortaria o início da série. O dado mensal já vem na escala da análise (D04). |
| D24 | 19/11/2026 | 2.1 | **Dados do ONI:** tabela oficial do ONI do **CPC/NOAA** (Climate Prediction Center). Cada valor trimestral é associado ao **mês central** do trimestre (DJF → janeiro, JFM → fevereiro…). | Associar ao último mês do trimestre (DJF → fevereiro) | É a convenção da NOAA e da literatura. O valor do mês central só é conhecido depois que o mês seguinte termina; essa limitação entra na escolha da defasagem (D14) e na discussão. |
| D25 | 19/11/2026 | 2.3 | **Dados meteorológicos (revisa D23):** **estações automáticas** do INMET, dos arquivos anuais da página "Dados Históricos" (um CSV por estação, com registros de hora em hora). Na bacia do Grande, **12 estações** têm dados desde jan/2010 e **Barretos (A748)** desde 19/06/2010. Outras 6 começam entre 2015 e 2019 (São Sebastião do Paraíso, Bebedouro, Uberaba, Machado, Oliveira, São Simão); se entram ou não fica para a D20b. Ver `docs/verificacao-dados.md`. | Estações convencionais pelo BDMEP (D23) | Na bacia só existem 3 estações convencionais em operação, o que representa mal a chuva de uma bacia desse tamanho. As automáticas são cerca de 19, têm download direto (dá para automatizar, item 2.7) e evitam o pedido por e-mail do BDMEP. O custo é o período mais curto (D26) e a agregação de hora para mês. |
| D26 | 19/11/2026 | 1.5 / 2.3 | **Período (revisa D10):** de **janeiro de 2010** até o **último mês completo** (out/2026 na verificação de 19/11). Vale para **todas as séries** (ENA, ONI e INMET), de modo que todos os modelos usam o mesmo período. Os 12 meses de teste (D08) continuam sendo os 12 últimos meses completos. | Manter 2000 (D10); usar 2000 nos modelos univariados e 2010 só na regressão | Antes de 2010, quase nenhuma estação automática da bacia tem dados (só Franca, desde 2002). Começar em 2010 garante dados meteorológicos para toda a série, e o mesmo período em todos os modelos deixa a comparação justa. Ficam 202 meses (jan/2010 a out/2026, quase 17 anos), o suficiente para os modelos sazonais. |
| D27 | 19/11/2026 | 2.3 / 4 | **Estações que começam depois de 2010 (resolve parte da D20b):** as 6 estações que começam entre 2015 e 2019 **entram a partir do momento em que passam a ter dados**, assim como Barretos (jun/2010). **Cuidado na etapa 4:** quando uma estação entra na média da bacia, a composição da média muda, o que pode criar um degrau artificial na série (por exemplo, se a estação nova for mais seca que a média). Para evitar isso, a forma de agregar as estações (média simples, anomalias por estação etc.) será definida na preparação dos dados. | Usar só as 13 estações com dados desde 2010; deixar as 6 de fora | Escolha do grupo: as estações novas cobrem partes da bacia sem medição (Triângulo Mineiro, norte de SP). Descartá-las deixaria parte da variação da chuva na bacia sem explicação no modelo. |
| D28 | 20/11/2026 | 3.1 | **Cópia de trabalho mensal** (`R/02_base_mensal.R` → `data/processed/`): (a) **ENA:** média mensal dos valores diários da bacia GRANDE; (b) **ONI:** trimestre associado ao mês central (D24), guardado desde jan/2000 para sobrar histórico para as defasagens; (c) **INMET:** para cada estação, **média mensal** dos valores horários de chuva (mm/h), temperatura (°C) e umidade (%). Horas sem registro (`-9999` ou vazio) ficam de fora da média, e cada linha guarda quantas horas válidas teve. O mês é o da hora UTC do INMET. **Nenhum mês é descartado ou preenchido nesta fase.** | Chuva como soma mensal; descartar já os meses com poucas horas | Escolha do grupo pela média. A soma subestima a chuva dos meses com horas faltando; a média não, e o total do mês pode ser recuperado multiplicando pelas horas do mês. A regra de completude (ex.: Passos, out/2010, tem só 19 de 744 horas) fica para a etapa 4, quando se define como juntar as estações (D27). |
| D29 | 20/11/2026 | 0.4 / todas | **Protocolo de dados:** toda transformação ou manipulação de dados (agregar, juntar arquivos, separar, filtrar, criar sub-bases, recodificar, transformar) é feita **por um script em `R/`, versionado e commitado no Git**, nunca à mão nem só no console. Os arquivos gerados são commitados junto com o script que os gera, e toda escolha feita no script é registrada neste arquivo. Vale para os membros do grupo e para as IAs que eles usarem; as regras estão em `AGENTS.md` (lido por Claude, Copilot, Codex, Cursor etc.). | Manipular os dados em planilha ou no console e subir só o resultado | Qualquer colega consegue refazer e conferir cada passo a partir dos dados brutos, e o código vira o anexo pedido pelo professor. |
| D30 | 20/11/2026 | 3 / 4 / 5 | **Conjunto de teste cego:** os 12 meses de teste (D08: **nov/2025 a out/2026**) passam pelas **mesmas transformações** dos demais (os scripts de preparação processam a série inteira), mas **ninguém olha para eles** até a avaliação final dos modelos (etapas 5–6). Toda análise exploratória, escolha de transformação, defasagem, variável, regra de limpeza ou modelo usa **só o treino (jan/2010 a out/2025)**. Os scripts das etapas 3 e 4 filtram `ano_mes <= "2025-10"` antes de qualquer gráfico, estatística ou ajuste. Vale para os membros e para as IAs (`AGENTS.md`). **Observação:** na verificação dos dados (etapa 2), antes desta regra, foram anotados valores do período de teste (ENA alta em set e out/2026, ONI em +2,46). Eles **não podem** pesar em nenhuma decisão; só voltam na discussão dos resultados. | Explorar a série inteira | Se o teste influenciar as escolhas, as previsões ficam otimistas: o modelo foi ajustado, mesmo sem querer, para acertar justamente os meses usados para avaliá-lo. Isso tornaria a comparação entre os modelos enviesada. |
| D31 | 20/11/2026 | 2.4 / 3.1 | **Dados de 2009 do INMET:** as estações automáticas entram a partir de **jan/2009**, só como **histórico para as defasagens**. A ENA e os modelos continuam começando em jan/2010 (D26). O **ONI de 2009 também entra**: ele já está guardado desde jan/2000 (D28), o que cobre defasagens longas. O El Niño pode agir com atraso sobre o clima medido pelo INMET, que por sua vez age com atraso sobre a ENA; somando os dois atrasos, a defasagem do ONI pode passar de 12 meses. | Começar o INMET em 2010 e perder os primeiros meses da regressão | Com defasagem de k meses, a ENA de jan/2010 usa o clima de k meses antes. Sem 2009, os primeiros meses ficariam sem as variáveis meteorológicas e a regressão perderia observações. As 12 estações com dados desde jan/2010 já operavam em 2009. |
| D32 | 20/11/2026 | 3.4 / 3.6 | **Transformação da variável resposta (resolve D05):** adotar a transformação **logarítmica (`log(ENA)`)** na modelagem de regressão e nos modelos ARIMA/SARIMA (comparando com a série original quando aplicável), reconvertendo as previsões para MWmed no cálculo de EAM e RMSE. | Modelar apenas na escala original (MWmed); transformação Box-Cox | Na EDA (treino), a ENA bruta apresentou forte assimetria positiva (1,80), curtose elevada (6,67) e variância muito maior nos meses chuvosos. No QQ-plot, `log(ENA)` aproximou-se da normalidade e estabilizou a variância. A reconversão garante comparação justa com os demais modelos na mesma unidade. |
| D33 | 20/11/2026 | 3.5 | **Defasagem do ONI (resolve D14):** incluir **ONI defasado em 4 e/ou 5 meses (`oni_lag4`, `oni_lag5`)** como candidato na regressão. | ONI contemporâneo; outras defasagens entre 2 e 12 meses | No treino, a correlação contemporânea foi quase nula (−0,03), enquanto a função de correlação cruzada (CCF) apresentou o maior pico negativo em lag −4 e −5 (próximo ao limite de significância de −0,15). Ambas as defasagens respeitam o atraso de 1 mês de publicação do ONI (D24). |
| D34 | 20/11/2026 | 3.5 | **Variáveis meteorológicas e defasagens do INMET (resolve parte da D20):** candidatar na regressão **precipitação (`lag 1` e `lag 2`)**, **umidade relativa (`lag 1`)** e **temperatura (`lag 1` e `lag 2`)**, além das ***dummies* de mês**. | Usar todas as variáveis do INMET; excluir *dummies* de mês | No treino, a precipitação teve pico na CCF em lag −1 (> 0,75) e forte correlação em lag −2 (~0,60), refletindo o tempo de escoamento da chuva até os reservatórios. Umidade (pico em lag −1; Spearman contemporâneo = 0,86) e temperatura (picos em lag −2 e −1) complementam o efeito da evaporação. A multicolinearidade entre clima e *dummies* será tratada na seleção de variáveis (D17). |
| D35 | 20/11/2026 | 3.5 / 4 | **Agregação das 19 estações do INMET (resolve pendência da D27):** agregar as estações disponíveis em cada mês por **média simples** (com chuva já em `mm/h` pelo `02_base_mensal.R`). | Padronização por anomalias mensais por estação; restringir às 13 estações fixas desde 2010 | No período 2019–2025 (treino), a correlação entre a precipitação média das 13 estações fixas e a de todas as 19 estações foi de **0,9965**, mostrando que a entrada das 6 estações novas não introduz degrau artificial relevante na série e dispensando a complexidade adicional das anomalias. |

### Objetivos específicos (D21)

1. Ajustar à série de ENA mensal todos os modelos da disciplina que se apliquem e justificar os que não se aplicam.
2. Comparar a previsão dos modelos nos últimos 12 meses com EAM e RMSE, usando o ingênuo sazonal como referência.
3. Verificar se variáveis meteorológicas de meses anteriores (INMET), inclusive de regiões distantes como a Amazônia, ajudam a prever a ENA da bacia do Grande.
4. Verificar se o El Niño/La Niña (ONI defasado) ajuda a prever a ENA.
5. Discutir por que cada modelo se comporta melhor ou pior com essa série.

### Divisão do trabalho (D12)

**Membros do grupo:** Bruno, Francisco, Jullya e Luiz. A divisão de tarefas ainda não foi combinada.

| Bloco | Conteúdo | Prazo-alvo |
|-------|----------|-----------|
| A | Obter e preparar os dados (ONS, INMET, NOAA), análise exploratória, decomposição, estacionariedade | 20–21/11 |
| B | Suavização exponencial: SES, Holt, Holt-Winters, ETS | 21–22/11 |
| C | AR, MA, ARIMA, SARIMA | 21–22/11 |
| D | Regressão e ingênuo sazonal | 21–22/11 |
| E | Redação: Introdução, Métodos, comparação dos modelos, Resultados e discussões, Considerações finais | 22–23/11 |
| F | Geração do PDF final e entrega no Moodle | 24/11 |

---

## Pendências

A etapa 1 aguarda a confirmação do grupo. As decisões adiadas estão em D17 e D20.
