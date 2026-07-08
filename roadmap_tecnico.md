# Roadmap técnico — Sistema de gestão de leads (Móvel e Fibra)

Guia de execução do projeto, do zero até produção. Siga na ordem — cada fase depende da anterior.

> **Nota de correção (jul/2026):** a versão anterior deste arquivo tinha itens marcados como `[x]` que na verdade eram decisões de negócio em aberto ou etapas não concluídas. Essas foram separadas na seção "Decisões em aberto" no final do arquivo, para não ficarem misturadas com o checklist de progresso técnico.

---

## Fase 0 — Preparação do ambiente ✅ concluída

- [x] PostgreSQL instalado (local, Windows)
- [x] Banco `leads_vivo` criado
- [x] Git e `.gitignore` configurados

---

## Fase 1 — Modelagem do banco ✅ concluída

- [x] Schema original completo (`operadores`, `planos`, `lotes_extracao`, `leads`, `historico_status`, `agenda_retornos`)
- [x] Tabela `base_cnpjs` criada, com índices (`uf`, `cidade`, `tipo_oferta_disp`)
- [x] FK `fk_leads_cnpj` adicionada em `leads` referenciando `base_cnpjs`
- [x] View `view_leads_operador` criada
- [x] `planos` e `operadores` populados (dados de teste)

**Pendente (não bloqueia a Fase 2, mas precisa de decisão antes da Fase 2/6 avançarem de vez — ver seção de decisões em aberto):**
- Regra de atualização de `base_cnpjs` (carga periódica vs. estática)
- Regra de reabordagem de CNPJ recusado (quarentena vs. nunca mais)
- Modelagem de `resultado_discador` (tabela própria vs. atualizar `leads`/`historico_status`)

---

## Fase 2 — Pipeline de entrada (ETL) 🔄 em andamento

- [x] Ambiente Python configurado (venv, `requirements.txt`)
- [x] `.env` criado com credenciais do banco
- [x] `etl/conexao.py` criado e testado — conexão validada com sucesso
- [] Script de carga/upsert de `base_cnpjs`
- [ ] Filtro de extração por UF/cidade/tipo de oferta
- [ ] Regra de deduplicação (seção 5.1 da documentação)
- [ ] Criação de registro em `lotes_extracao`
- [ ] Inserção de CNPJs aprovados em `leads`

---

## Fase 3 — Interface dos operadores ⬜ não iniciada

- [ ] Tela "meus leads" em Streamlit consumindo `view_leads_operador`
- [ ] Atualização de status, plano vendido, agenda de retornos
- [ ] Autenticação dos operadores (ver decisão em aberto)

---

## Fase 4 — Painel do supervisor ⬜ não iniciada

- [ ] Visibilidade em tempo real de volume, status da carteira e conversão

---

## Fase 5 — Relatórios e analytics ⬜ não iniciada

- [ ] Métricas de conversão por operador, canal e plano
- [ ] Dashboard no Metabase

---

## Fase 6 — Rollout e estabilização ⬜ não iniciada

- [ ] Backup automatizado do banco (cobrindo também `base_cnpjs`)
- [ ] Decisão de hospedagem (local vs. nuvem/servidor da empresa)
- [ ] Dimensionamento por concorrência (nº de operadores simultâneos)

---

## Decisões em aberto (aguardando validação de negócio)

| Tema | Decisão pendente |
|---|---|
| Atualização de `base_cnpjs` | Carga periódica (upsert por cnpj) ou base estática/única? |
| Reabordagem de CNPJ recusado | Existe período de quarentena antes de nova tentativa, ou nunca mais tentar? |
| `resultado_discador` | Tabela separada, ou atualizar `leads`/`historico_status` diretamente? |
| Hospedagem do banco | Continua local, ou migra para nuvem/servidor da empresa em produção? |
| Autenticação dos operadores | Login simples (usuário/senha) ou algo mais robusto? |
| Distribuição de leads | Manual pelo supervisor ou regra automática? |
| Backup | Frequência e local de armazenamento a definir. |
| Concorrência | Quantos operadores usarão simultaneamente (dimensiona o servidor)? |
