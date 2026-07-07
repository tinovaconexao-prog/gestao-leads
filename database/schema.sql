
CREATE TABLE operadores
(
    id        SERIAL PRIMARY KEY,
    nome      VARCHAR(100) NOT NULL,
    perfil    VARCHAR(20)  NOT NULL DEFAULT 'Operador'
        CHECK (perfil IN ('Operador', 'Supervisor')),
    ativo     BOOLEAN               DEFAULT TRUE,
    criado_em TIMESTAMP             DEFAULT NOW()
);

CREATE TABLE planos
(
    id          SERIAL PRIMARY KEY,
    nome_plano  VARCHAR(100) NOT NULL,
    tipo_oferta VARCHAR(10)  NOT NULL CHECK ( tipo_oferta IN ('Movel', 'Fibra')), --trava no banco pra impedir qualquer valor diferente desses dois — segurança extra, mesmo que a interface também valide isso depois.
    ativo       BOOLEAN DEFAULT TRUE
);

-- ==========================================================
-- Nova tabela: catálogo de CNPJs disponíveis para prospecção
-- (separada de "leads" — não guarda status comercial, só dado
-- cadastral e de segmentação usado para montar o filtro do lote)
-- ==========================================================

CREATE TABLE base_cnpjs
(
    cnpj             VARCHAR(14) PRIMARY KEY,
    razao_social     VARCHAR(200),
    telefone         VARCHAR(20),
    uf               CHAR(2),
    cidade           VARCHAR(100),
    tipo_oferta_disp VARCHAR(10) CHECK (tipo_oferta_disp IN ('Movel', 'Fibra', 'Ambos')),
    ativo            BOOLEAN   DEFAULT TRUE,
    atualizado_em    TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_base_uf          ON base_cnpjs (uf);
CREATE INDEX idx_base_cidade      ON base_cnpjs (cidade);
CREATE INDEX idx_base_tipo_oferta ON base_cnpjs (tipo_oferta_disp);

CREATE TABLE lotes_extracao
(
    id_lote       SERIAL PRIMARY KEY,
    data_extracao TIMESTAMP DEFAULT NOW(),
    tipo_oferta   VARCHAR(10) NOT NULL CHECK (tipo_oferta IN ('Movel', 'Fibra')),
    origem_filtro TEXT,
    qtd_cnpjs     INTEGER,
    criado_por    VARCHAR(100)
);

-- ==========================================================
-- leads: ganhou a FK pra base_cnpjs (cnpj continua NOT UNIQUE,
-- pois o mesmo CNPJ pode voltar a virar lead ao longo do tempo)
-- ==========================================================

CREATE TABLE leads
(
    id                      SERIAL PRIMARY KEY,
    cnpj                    VARCHAR(14) NOT NULL REFERENCES base_cnpjs (cnpj),
    id_lote                 INTEGER REFERENCES lotes_extracao (id_lote),
    tipo_oferta             VARCHAR(10) NOT NULL CHECK ( tipo_oferta IN ('Movel', 'Fibra')),
    operador_id             INTEGER REFERENCES operadores (id),
    canal                   VARCHAR(20) CHECK ( canal IN ('WhatsApp', 'Discador', 'Ambos')),
    status                  VARCHAR(30) NOT NULL DEFAULT 'Nao disparado'
        CHECK ( status IN ('Nao disparado', 'Disparado sem retorno', 'Em negociacao', 'Vendido', 'Recusado')),
    plano_id                INTEGER REFERENCES planos (id),
    data_disparo            TIMESTAMP,
    data_ultima_atualizacao TIMESTAMP            DEFAULT NOW(),
    observacao              TEXT
);

CREATE INDEX idx_leads_cnpj     ON leads (cnpj);
CREATE INDEX idx_leads_status   ON leads (status);
CREATE INDEX idx_leads_operador ON leads (operador_id);

CREATE TABLE historico_status -- guarda a informação que o caminho lead percorreu
(
    id              SERIAL PRIMARY KEY,
    lead_id         INTEGER REFERENCES leads (id),
    status_anterior VARCHAR(30),
    status_novo     VARCHAR(30) NOT NULL,
    operador_id     INTEGER REFERENCES operadores (id),
    data_mudanca    TIMESTAMP DEFAULT NOW()
    -- Sem esse histórico, você perde a informação de
    -- todo o caminho que o lead percorreu
    -- (quando saiu de "Não disparado" pra "Em negociação", quando virou "Vendido").
    -- É essa tabela que vai permitir você calcular, por exemplo, "tempo médio até fechar venda"
);
CREATE INDEX idx_historico_lead ON historico_status (lead_id);

CREATE TABLE agenda_retornos
(
    id                 SERIAL PRIMARY KEY,
    lead_id            INTEGER REFERENCES leads (id),
    operador_id        INTEGER REFERENCES operadores (id),
    data_agendamento   TIMESTAMP   NOT NULL,
    tipo_retorno       VARCHAR(20) CHECK (tipo_retorno IN ('Ligacao', 'WhatsApp')),
    status_agendamento VARCHAR(20) NOT NULL DEFAULT 'Pendente'
        CHECK ( status_agendamento IN ('Pendente', 'Concluido', 'Remarcado', 'Perdido')),
    observacao         TEXT,
    criado_em          TIMESTAMP            DEFAULT NOW()
);
CREATE INDEX idx_agenda_operador ON agenda_retornos (operador_id);
CREATE INDEX idx_agenda_data     ON agenda_retornos (data_agendamento);

-- ==========================================================
-- Nova view: o que a interface do operador deve consultar
-- (nunca acessar base_cnpjs diretamente)
-- ==========================================================

CREATE VIEW view_leads_operador AS
SELECT
    l.id,
    b.cnpj,
    b.razao_social,
    b.telefone,
    l.tipo_oferta,
    l.status,
    l.canal,
    l.plano_id,
    l.operador_id,
    l.data_disparo,
    l.data_ultima_atualizacao,
    l.observacao
FROM leads l
         JOIN base_cnpjs b ON b.cnpj = l.cnpj;



