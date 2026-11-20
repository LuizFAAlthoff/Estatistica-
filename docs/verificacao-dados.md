# Verificação dos dados (EAP 2.3)

> Primeiro contato com as três fontes (19/11/2026). Objetivo: conferir a estrutura dos arquivos, os tipos das variáveis, a cobertura das datas e os problemas antes do download completo (2.4).
> As amostras analisadas ficam em `data/raw/amostra/`. Os zips do INMET ficam em `data/raw/inmet/`, que está fora do Git por causa do tamanho (1,9 GB).

---

## 1. ENA — ONS, "ENA diária por bacia" (D22)

**Amostra:** arquivos de 2000, 2025 e 2026, baixados de `https://ons-aws-prod-opendata.s3.amazonaws.com/dataset/ena_bacia_di/ENA_DIARIO_BACIAS_<ano>.csv`. Há um arquivo por ano.

**Formato:** CSV separado por `;`, com ponto como separador decimal, codificação UTF-8 e uma linha de cabeçalho. Os dados estão em **formato longo**: uma linha por bacia por dia, com todas as bacias no mesmo arquivo.

| Coluna | Tipo | Descrição | Uso |
|---|---|---|---|
| `nom_bacia` | Qualitativa nominal (texto) | Nome da bacia | Filtrar `GRANDE` |
| `ena_data` | Data (`AAAA-MM-DD`) | Dia da observação | Índice de tempo |
| `ena_bruta_bacia_mwmed` | Quantitativa contínua (MWmed) | ENA bruta | **Variável resposta (D05)** |
| `ena_bruta_bacia_percentualmlt` | Quantitativa contínua (%) | ENA bruta em % da média de longo termo (MLT) | Não usada (D05) |
| `ena_armazenavel_bacia_mwmed` | Quantitativa contínua (MWmed) | Parcela da ENA que pode ser armazenada | Não usada |
| `ena_armazenavel_bacia_percentualmlt` | Quantitativa contínua (%) | A mesma parcela, em % da MLT | Não usada |

**Bacia GRANDE na amostra:**

- Não há dias faltando, datas repetidas, valores ausentes, zeros ou negativos nos três anos. As datas estão em ordem.
- O arquivo de 2026 vai até **18/11/2026**. O último mês completo é **out/2026**, então o teste da D08/D10 vai de **nov/2025 a out/2026**.
- A sazonalidade é forte. Em 2000, a média de janeiro foi de cerca de 11.400 MWmed e a de outubro, de cerca de 1.800. Em 2025, a média de setembro ficou em cerca de 1.100.

**Ponto de atenção:** a lista de bacias mudou com o tempo. Eram 24 em 2000, 23 em 2025 e 35 em 2026. Em 2026 aparecem bacias novas, como MADEIRA, XINGU e ANTAS, e em 2025 sumiram OUTRAS-SUDESTE e OUTRAS-SUL. A GRANDE mantém o nome em todos os anos. No download completo, é preciso conferir se a série não dá um salto na virada de 2025 para 2026, o que indicaria uma mudança na definição da bacia.

## 2. ONI — CPC/NOAA (D13, D24)

**Arquivo:** `https://www.cpc.ncep.noaa.gov/data/indices/oni.ascii.txt`. É texto separado por espaços, com cabeçalho.

| Coluna | Tipo | Descrição | Uso |
|---|---|---|---|
| `SEAS` | Qualitativa ordinal (texto) | Trimestre móvel: DJF, JFM, …, NDJ | Converter para o mês central (D24) |
| `YR` | Quantitativa discreta (ano) | Ano | Índice de tempo |
| `TOTAL` | Quantitativa contínua (°C) | Temperatura média do mar na região Niño 3.4 | Não usada |
| `ANOM` | Quantitativa contínua (°C) | Anomalia de temperatura, que é o **ONI** | **Variável explicativa** |

- Vai de DJF/1950 a **ASO/2026**, que pelo mês central corresponde a **set/2026**. São 921 linhas, sem valores faltando.
- **Cuidado na conversão:** o trimestre NDJ aparece com o ano em que começa (NDJ/2025 = nov/2025 a jan/2026). Pelo mês central, ele vira **dez/2025**. Os outros trimestres não têm esse problema: o mês central cai no próprio ano.
- O ONI está em **+2,46** em ASO/2026, um El Niño forte bem no período de teste. Vale comentar isso na discussão.

## 3. INMET

### 3.1 Estações convencionais (BDMEP, D23)

- Não há download direto. O BDMEP (`bdmep.inmet.gov.br`) é um **formulário de pedido**: o usuário escolhe estações, variáveis, período e escala (diária ou mensal), e o link chega por e-mail (remetente `bdmep@inmet.gov.br`). Os pedidos entram numa fila.
- A API do INMET (`apitempo.inmet.gov.br/estacoes/M`) lista **85 estações convencionais em operação** no Brasil. Dentro da bacia do Grande, estão só **Franca (83630, SP)**, **Lavras (83687, MG)** e **Passa Quatro (83737, MG)**, todas em operação desde 1910–1912. Araxá fica na bacia do Paranaíba e Belo Horizonte, na do São Francisco.
- A lista só mostra as estações que operam hoje. Estações desativadas podem ter histórico no BDMEP.

### 3.2 Estações automáticas ("Dados Históricos", zips anuais)

**Arquivos:** `data/raw/inmet/2000.zip` a `2026.zip`, baixados manualmente do portal do INMET. Cada zip tem **um CSV por estação por ano**.

**Formato de cada CSV:**

- Codificação latin-1, separador `;` e **vírgula** como separador decimal.
- As **8 primeiras linhas são metadados**: região, UF, nome da estação, código WMO (ex.: A502), latitude, longitude, altitude e data de fundação.
- Depois vem uma linha de cabeçalho e **um registro por hora** (`Data` em `AAAA/MM/DD`, `Hora UTC`).
- Valor faltando aparece como `-9999` ou vazio.

| Variáveis horárias (todas quantitativas contínuas) | Unidade |
|---|---|
| Precipitação total | mm |
| Pressão atmosférica (na hora, máxima e mínima) | mB |
| Radiação global | kJ/m² |
| Temperatura do ar (bulbo seco, máxima e mínima) | °C |
| Temperatura do ponto de orvalho (na hora, máxima e mínima) | °C |
| Umidade relativa (na hora, máxima e mínima) | % |
| Vento (direção, rajada máxima e velocidade) | °, m/s |

**Cobertura:** o INMET tem 705 estações automáticas distintas entre 2000 e 2026. Na região da bacia, porém, quase todas começaram tarde:

| Ano | Estações automáticas na região ampla da bacia (MG/SP/RJ/GO/MS) |
|---|---|
| 2000 | 1 |
| 2005 | 9 |
| 2008 | 49 |
| 2015 | 52 |
| 2026 | 69 |

**Estações automáticas que provavelmente ficam dentro da bacia do Grande:** a classificação é aproximada, pela localização. A confirmação exige o contorno oficial da bacia.

| Código | Estação | UF | Desde | % de horas com chuva válida |
|---|---|---|---|---|
| A708 | Franca | SP | 2002 | 83 |
| A516 | Passos | MG | 2006 | 92 |
| A515 | Varginha | MG | 2006 | 89 |
| A530 | Caldas | MG | 2006 | 93 |
| A531 | Maria da Fé | MG | 2006 | 97 |
| A514 | São João del Rei | MG | 2006 | 94 |
| A525 | Sacramento | MG | 2006 | 91 |
| A520 | Conceição das Alagoas | MG | 2006 | 91 |
| A529 | Passa Quatro | MG | 2007 | 89 |
| A738 | Casa Branca | SP | 2007 | 80 |
| A747 | Pradópolis | SP | 2008 | 85 |
| A753 | Ituverava | SP | 2008 | 84 |
| A748 | Barretos | SP | 2010 | 80 |
| A561 | São Sebastião do Paraíso | MG | 2015 | 69 |
| A764 | Bebedouro | SP | 2016 | 76 |
| A568 | Uberaba | MG | 2017 | 96 |
| A567 | Machado | MG | 2017 | 93 |
| A570 | Oliveira | MG | 2017 | 96 |
| A770 | São Simão | SP | 2019 | 92 |

São cerca de 19 estações, mas só Franca tem dados antes de 2006. Elas também têm entre 3% e 31% das horas sem registro de chuva.

### 3.3 Escolha entre convencionais e automáticas

Os zips baixados são das **estações automáticas**, e a D23 escolheu as **convencionais (BDMEP)**. As duas opções têm um custo:

- **Convencionais:** só 3 estações na bacia, mas com o período todo desde 2000. Dependem de um pedido por e-mail.
- **Automáticas:** cerca de 19 estações na bacia, mas quase todas só a partir de 2006–2008. Isso cortaria o início do período (D10) ou deixaria a regressão sem dados meteorológicos nos primeiros anos.

**Decisão (D25, D26):** usar as **estações automáticas** e começar todas as séries em **jan/2010**. Em jan/2010, 12 das estações da tabela já tinham dados, e Barretos começa em 19/06/2010. As outras 6 (de 2015 em diante) ficam para a D20b.
