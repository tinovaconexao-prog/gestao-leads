# Roadmap técnico — Sistema de gestão de leads (Móvel e Fibra)

Guia de execução do projeto, do zero até produção. Siga na ordem — cada fase depende da anterior.

---

## Fase 0 — Preparação do ambiente ✅ concluída

- [x] PostgreSQL instalado (local, Windows)
- [x] Banco `leads_vivo` criado
- [x] Repositório Git criado e clonado (`gestao-leads`)
- [x] `.gitignore` configurado (Python + IntelliJ: `venv/`, `.env`, `.idea/`, `*.iml`)

---

## Fase 1 — Modelagem e criação do banco de dados ⚠️ schema.sql atualizado, banco ainda não migrado

- [x] Schema definido com 7 tabelas: `operadores`, `planos`, `base_cnpjs`, `lotes_extracao`, `leads`, `historico_status`, `agenda_retornos`
- [x] Campo `perfil` adicionado em `operadores` (`Operador` / `Supervisor`) — permite diferenciar acesso sem precisar de tabela separada de supervisão
- [x] **Nova tabela `base_cnpjs`** — catálogo de CNPJs disponíveis para prospecção (cnpj, razão social, telefone, UF, cidade, tipo de oferta disponível). Separa dado cadastral de dado comercial: `leads` guarda status/histórico, `base_cnpjs` guarda quem é o CNPJ.
- [x] `leads.cnpj` ganhou FK apontando pra `base_cnpjs(cnpj)` — garante que nenhum lead referencia CNPJ inexistente na base
- [x] `view_leads_operador` criada — isola a interface do operador do restante das colunas de segmentação de `base_cnpjs` (expõe só cnpj, razão social, telefone e dados do lead)
- [x] Índices criados: `idx_leads_cnpj`, `idx_leads_status`, `idx_leads_operador`, `idx_historico_lead`, `idx_agenda_operador`, `idx_agenda_data`, `idx_base_uf`, `idx_base_cidade`, `idx_base_tipo_oferta`
- [x] Constraints de integridade (foreign keys, `CHECK`, `NOT NULL`)
- [x] `schema.sql` atualizado no Git com o novo desenho (`base_cnpjs` + FK + view)
- [x] **Decisão resolvida:** `razao_social` e `telefone` existem, mas ficam em `base_cnpjs`, não em `leads` — acessados via `view_leads_operador`
- [ ] **Banco Postgres ainda não migrado** — o `schema.sql` já reflete o novo design, mas o banco local ainda está na versão anterior (sem `base_cnpjs`). Próximo passo: `DROP` + recriar.
- [ ] Popular tabela `planos` com os planos reais de Móvel e Fibra
- [ ] Popular tabela `operadores` com os operadores/supervisores atuais
- [ ] Popular `base_cnpjs` com CNPJs de teste (necessário antes de inserir qualquer `leads`, já que agora há FK)
- [ ] **Decisão em aberto:** carga de `base_cnpjs` é periódica (upsert por cnpj) ou estática/única?
- [ ] **Decisão em aberto:** reabordagem de CNPJ recusado — existe quarentena antes de nova tentativa, ou nunca mais tentar?
- [ ] **Decisão em aberto:** criar tabela `resultado_discador` agora ou só na fase de integração com o discador?

**Schema atual (referência rápida):**

```sql
operadores (id, nome, perfil, ativo, criado_em)
planos (id, nome_plano, tipo_oferta, ativo)
base_cnpjs (cnpj PK, razao_social, telefone, uf, cidade, tipo_oferta_disp, ativo, atualizado_em)
lotes_extracao (id_lote, data_extracao, tipo_oferta, origem_filtro, qtd_cnpjs, criado_por)
leads (id, cnpj FK->base_cnpjs, id_lote, tipo_oferta, operador_id, canal, status, plano_id,
       data_disparo, data_ultima_atualizacao, observacao)
historico_status (id, lead_id, status_anterior, status_novo, operador_id, data_mudanca)
agenda_retornos (id, lead_id, operador_id, data_agendamento, tipo_retorno,
                 status_agendamento, observacao, criado_em)
view_leads_operador (join entre leads e base_cnpjs, usada pela interface do operador)
```

**Como a atribuição do supervisor pro operador funciona:** `leads.operador_id` aceita `NULL` — o lead nasce sem dono, e o supervisor "envia" a lista fazendo um `UPDATE` nesse campo (via interface, mais pra frente). Nenhuma tabela nova é necessária pra isso.

**Entregável desta fase:** banco criado, validado e pronto para receber dados de referência e depois dados reais.

---

## Fase 2 — Pipeline de entrada de dados (ETL) — não iniciada

Você já tem ferramentas de tratamento de dados — aqui é sobre conectar o resultado delas ao banco. Com a chegada de `base_cnpjs`, o pipeline ganhou uma etapa a mais: agora existem dois fluxos de carga (a base e os lotes/leads).

- [ ] Escrever/adaptar rotina de carga de `base_cnpjs` (upsert por `cnpj`, se a decisão for carga periódica)
- [ ] Adaptar seu processo atual de tratamento para gerar a saída no formato das tabelas `lotes_extracao` e `leads`
- [ ] Escrever script Python que:
  - Filtra `base_cnpjs` pelo critério do lote (uf, cidade, tipo_oferta_disp)
  - Aplica a regra de deduplicação contra `leads` (ver regra abaixo) antes de inserir
  - Gera automaticamente o `id_lote`, com `origem_filtro` descrevendo o critério usado
  - Insere no banco via SQLAlchemy/psycopg2
- [ ] **Regra de deduplicação definida:**
  - CNPJ não existe em `leads` → insere normalmente
  - CNPJ existe e está `Vendido` → não disparar de novo (salvo regra futura de renovação/upsell)
  - CNPJ existe e está `Recusado` → decisão pendente (ver tabela de decisões abaixo)
  - CNPJ existe e está `Em negociacao` ou `Disparado sem retorno` → não recriar lead, no máximo atualizar `data_ultima_atualizacao`
- [ ] Testar o pipeline com uma carga pequena (ex: 50 CNPJs) antes de rodar com volume real
- [ ] Testar com volume real (milhares de CNPJs) e medir tempo de execução

**Entregável desta fase:** processo repetível de carga mensal/semanal funcionando.

---

## Fase 3 — Interface dos operadores — não iniciada

- [ ] Prototipar tela em Streamlit: login simples → lista de leads atribuídos ao operador logado, consultando **`view_leads_operador`** (nunca `base_cnpjs` diretamente)
- [ ] Implementar atualização de status (dropdown com opções fixas, não texto livre)
- [ ] Implementar campo de plano vendido (dropdown filtrado por `tipo_oferta` do lead)
- [ ] Implementar a agenda de retornos:
  - Tela "meus retornos de hoje"
  - Ao marcar "Em negociação", exigir data do próximo retorno
  - Destacar retornos atrasados
- [ ] Testar com 1-2 operadores reais antes de liberar para todos (piloto)
- [ ] Ajustar UX com base no feedback do piloto

**Entregável desta fase:** operadores conseguem trabalhar 100% pela interface, sem tocar em Excel.

---

## Fase 4 — Painel do supervisor — não iniciada

- [ ] Tela de upload/criação de novo lote (ou conexão direta com o pipeline da Fase 2)
- [ ] Tela de distribuição de leads entre operadores (manual ou automática) — via `UPDATE` em `leads.operador_id`
- [ ] Dashboard com métricas: volume por lote, por operador, por tipo de oferta, taxa de conversão, leads parados sem atualização
- [ ] Filtro por período (semana, mês)

**Entregável desta fase:** supervisor tem visibilidade completa sem depender de relatório manual.

---

## Fase 5 — Relatórios e analytics — não iniciada

- [ ] Criar views SQL para as métricas recorrentes (ex: `view_funil_semanal`, `view_performance_operador`)
- [ ] Decidir ferramenta de BI: Metabase (self-hosted, gratuito) é o mais recomendado para começar
- [ ] Conectar Metabase (ou similar) ao Postgres
- [ ] Montar os dashboards recorrentes que hoje são feitos manualmente
- [ ] Automatizar envio semanal (e-mail ou link fixo) para a gestão, se fizer sentido

**Entregável desta fase:** relatório semanal deixa de ser trabalho manual.

---

## Fase 6 — Rollout e estabilização — não iniciada

- [ ] Migrar todos os operadores para o sistema (sair do Excel de vez)
- [ ] Definir rotina de backup do banco (mínimo: dump diário automatizado)
- [ ] Documentar o sistema (mesmo que resumido) para não depender só da memória
- [ ] Definir plano de suporte: o que fazer quando algo quebrar, quem aciona

---

## Riscos e decisões em aberto

| Tema | Decisão pendente |
|---|---|
| Dados de contato | ✅ Resolvido — `razao_social` e `telefone` ficam em `base_cnpjs`, acessados via `view_leads_operador` |
| Atualização de `base_cnpjs` | Carga periódica (upsert por cnpj) ou base estática/única? |
| Reabordagem de CNPJ recusado | Existe quarentena antes de nova tentativa, ou nunca mais tentar? |
| Resultado do discador | Tabela `resultado_discador` separada ou atualizar `leads`/`historico_status` direto? |
| Hospedagem do banco | Continua local, ou migra para nuvem/servidor da empresa em produção? |
| Autenticação dos operadores | Login simples (usuário/senha) ou algo mais robusto? |
| Distribuição de leads | Manual pelo supervisor ou regra automática? |
| Backup | Frequência e local de armazenamento (agora cobrindo também `base_cnpjs`) |
| Concorrência | Quantos operadores vão usar simultaneamente (dimensiona o servidor) |

---

## Stack consolidado

```
Banco de dados:       PostgreSQL (local, Windows)
ETL / scripts:         Python (pandas, psycopg2/SQLAlchemy)
Interface (operador
 e supervisor):        Streamlit
Dashboard/BI:          Metabase
Versionamento:         Git / GitHub
IDE:                   IntelliJ
```
