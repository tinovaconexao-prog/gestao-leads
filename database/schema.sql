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

CREATE TABLE lotes_extracao
(
    id_lote       SERIAL PRIMARY KEY,
    data_extracao TIMESTAMP DEFAULT NOW(),
    tipo_oferta   VARCHAR(10) NOT NULL CHECK (tipo_oferta IN ('Movel', 'Fibra')),
    origem_filtro TEXT,
    qtd_cnpjs     INTEGER,
    criado_por    VARCHAR(100)
);

CREATE TABLE leads
(
    id                      SERIAL PRIMARY KEY,
    cnpj                    VARCHAR(14) NOT NULL,
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

CREATE TABLE historico_status -- guarda a informação que o caminho lead percorreu
(
    id              SERIAL PRIMARY KEY,
    lead_id         INTEGER REFERENCES leads (id),
    status_anterior VARCHAR(30),
    status_novo     VARCHAR(30) NOT NULL,
    operador_id     INTEGER REFERENCES operadores (id),
    data_mudanca    TIMESTAMP DEFAULT NOW()
    --Sem esse histórico, você perde a informação de
    -- todo o caminho que o lead percorreu
    -- (quando saiu de "Não disparado" pra "Em negociação", quando virou "Vendido").
    -- É essa tabela que vai permitir você calcular, por exemplo, "tempo médio até fechar venda
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
CREATE INDEX idx_agenda_data ON agenda_retornos (data_agendamento);
