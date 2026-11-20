# Instruções para quem trabalha neste repositório (pessoas e IAs)

Trabalho de INE5649 (UFSC): previsão da ENA mensal da bacia do Rio Grande, em R. O plano está em [EAP.md](EAP.md), e as decisões estão em [docs/decisoes.md](docs/decisoes.md).

## Protocolo de dados (D29), obrigatório

1. **Toda transformação de dados é feita por um script R em `R/`.** Isso inclui agregar, juntar arquivos, separar, filtrar, criar uma sub-base mais leve, renomear colunas, recodificar e transformar (log, defasagens…). Não edite dados à mão, em planilha ou só no console.
2. **Os scripts são numerados na ordem em que rodam** (`01_baixar_dados.R`, `02_base_mensal.R`, `03_...`). Cada um lê só dados brutos ou a saída de um script anterior, e tem um cabeçalho dizendo o que lê, o que grava e como rodar (`Rscript R/NN_nome.R`, a partir da raiz do repositório).
3. **`data/raw/` nunca é alterado.** Ele é recriado por `R/01_baixar_dados.R` e fica fora do Git. Os resultados vão para `data/processed/`.
4. **Commite o script junto com os arquivos que ele gera.** Assim, quem fizer `git pull` recebe os dados e o código que os produziu.
5. **Registre toda escolha em [docs/decisoes.md](docs/decisoes.md).** Isso vale para regras de corte, tipos de média, defasagens, variáveis descartadas e afins. Use o próximo código livre (D30, D31…), com data, etapa da EAP, alternativas e justificativa. Se a escolha muda uma decisão anterior, marque a antiga como substituída.
6. **Atualize [docs/dicionario-dados.md](docs/dicionario-dados.md)** quando criar ou mudar colunas de uma base em `data/processed/`.
7. **Atualize a [EAP.md](EAP.md)** marcando o item concluído.

## Outras regras

- **IAs:** perguntem ao grupo antes de tomar uma decisão de análise (variáveis, períodos, regras de limpeza, modelos). Expliquem os termos técnicos de forma simples e não apliquem a escolha sem confirmação.
- **Cálculos:** são feitos em R, com scripts que qualquer membro consiga rodar e conferir.
- **Idioma:** documentação e comentários em português.
