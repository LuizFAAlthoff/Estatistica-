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
| D10 | 19/11/2026 | 1.5 | **Período:** de **janeiro de 2000** até o **último mês completo** disponível. Os 12 meses de teste (D08) são os 12 últimos meses completos. | Começar em 2014/2015; fechar em dezembro de 2025; incluir o mês corrente incompleto | Usa todo o histórico disponível. Um mês incompleto distorceria a média mensal justamente no período de teste. |
| D11 | 19/11/2026 | 7.1 | **Redação:** **R Markdown (`.Rmd`) → DOCX → PDF**. Um documento Word de referência aplicará a formatação exigida. | Markdown puro; Google Docs; LaTeX | Gráficos, tabelas e o anexo com a sintaxe R são gerados automaticamente a partir do código. Todos os membros têm R instalado. |
| D12 | 19/11/2026 | 0.2 | **Divisão do trabalho** por blocos (ver abaixo). Na prática, é provável que uma pessoa conduza a maior parte do projeto. | — | Prazo curto (5 dias). |
| D13 | 19/11/2026 | 1.5 / 2 | **Indicador do El Niño:** índice **ONI** (*Oceanic Niño Index*) da NOAA. | Niño 3.4 mensal sem suavização | É o índice oficial e o mais citado na literatura, o que facilita justificar e referenciar. |
| D14 | 19/11/2026 | 3 | **Defasagem do ONI:** escolhida na **análise exploratória**, usando a defasagem com **maior correlação** com a ENA. | Fixar um valor da literatura | Deixa os dados indicarem a defasagem relevante para a bacia do Grande. O valor escolhido será registrado como nova decisão. |
| D15 | 19/11/2026 *(revisada)* | 1.4 | **ONI como variável candidata:** o El Niño/La Niña entra na regressão como **candidato**. Se a seleção de variáveis (D17) não indicar relação, o ONI **sai do modelo final**, e esse resultado é relatado na discussão. | Tratar como hipótese formal a ser provada | O trabalho não terá seção de hipóteses (D21). A regressão não remove variáveis sozinha; o critério de remoção fica em D17. |
| D16 | 19/11/2026 | 1.6 | **Tipo de estudo:** **observacional** e **longitudinal** (série temporal), com **dados secundários públicos** (ONS, NOAA e INMET). | — | Não há intervenção nem coleta própria. Dados públicos dispensam aprovação de comitê de ética. |
| D17 | — | 5 | **Critério de seleção na regressão** (combinação de teste t, ANOVA e AIC; regra para quando discordarem; nível de significância α). **Adiado** para depois da definição das variáveis (D20). | — | O critério depende de quais variáveis entram no modelo. |
| D18 | 19/11/2026 | 5 | **Modelo de referência:** incluir o **ingênuo sazonal** (`snaive`), que prevê cada mês com o valor do mesmo mês no ano anterior. | Também a média sazonal; nenhum modelo de referência | O enunciado permite "outros modelos que contribuam". O ingênuo sazonal é a régua mínima: um modelo sofisticado só agrega valor se o superar. |
| D21 | 19/11/2026 | 1.3 / 1.4 | **Sem seção formal de hipóteses.** As questões do trabalho entram como **objetivos específicos** na seção "Introdução e objetivos". | Seção de hipóteses H1–H3 | O enunciado não exige hipóteses. Os testes de coeficientes da regressão continuam sendo usados, mas apenas como ferramenta de seleção de variáveis (D17). |
| D19 | 19/11/2026 | 2 | **Fonte dos dados meteorológicos:** **INMET** (Instituto Nacional de Meteorologia). A base de ENA do ONS não traz variáveis meteorológicas, então elas precisam ser cruzadas a partir de outra fonte. | Outras bases (NASA POWER, CHIRPS, ERA5) | Escolha do grupo: é a base oficial brasileira. Os detalhes (estações, região e variáveis disponíveis) ficam para a etapa 2. |
| D20 | 19/11/2026 | 2–3 | **Adiado para as etapas 2–3:** (a) quais variáveis meteorológicas existem no INMET e quais serão candidatas; (b) a **região** dos dados meteorológicos (só a bacia do Grande ou também regiões vizinhas, como a Amazônia); (c) as **defasagens** de cada variável; (d) se as ***dummies* de mês** entram, considerando a possível **multicolinearidade** com as variáveis meteorológicas. | Decidir agora | Essas decisões dependem de conhecer os dados, o que ainda não foi feito. |

### Objetivos específicos (D21)

1. Ajustar à série de ENA mensal todos os modelos da disciplina que se apliquem e justificar os que não se aplicam.
2. Comparar a previsão dos modelos nos últimos 12 meses com EAM e RMSE, usando o ingênuo sazonal como referência.
3. Verificar se variáveis meteorológicas de meses anteriores (INMET), inclusive de regiões distantes como a Amazônia, ajudam a prever a ENA da bacia do Grande.
4. Verificar se o El Niño/La Niña (ONI defasado) ajuda a prever a ENA.
5. Discutir por que cada modelo se comporta melhor ou pior com essa série.

### Divisão do trabalho (D12)

**Membros do grupo:** Bruno, Francisco, Jullya e Luiz. A atribuição dos blocos é uma proposta inicial e pode ser trocada.

| Bloco | Responsável | Conteúdo | Prazo-alvo |
|-------|-------------|----------|-----------|
| A | Luiz | Obter e preparar os dados (ONS, INMET, NOAA), análise exploratória, decomposição, estacionariedade; coordenação | 20/11 |
| B | Bruno | Suavização exponencial: SES, Holt, Holt-Winters, ETS | 21–22/11 |
| C | Francisco | AR, MA, ARIMA, SARIMA | 21–22/11 |
| D | Jullya | Regressão; redação de Introdução e Métodos | 21–22/11 |
| Todos | — | Comparação dos modelos, Resultados e discussões, Considerações finais | 22–23/11 |
| — | — | Geração do PDF final e entrega no Moodle | 24/11 |

---

## Pendências

A etapa 1 aguarda a confirmação do grupo. As decisões adiadas estão em D17 e D20.
