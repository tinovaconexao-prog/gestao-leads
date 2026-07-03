CREATE TABLE operadores
(
    id        SERIAL PRIMARY KEY,    -- gera o id do operador
    nome      VARCHAR(100) NOT NULL,
    ativo     BOOLEAN   DEFAULT TRUE,-- se um op sair da empresa apenas marca ele como false .
    criado_em TIMESTAMP DEFAULT NOW()
);

CREATE TABLE planos
(
    id          SERIAL PRIMARY KEY,
    nome_plano  VARCHAR(100) NOT NULL,
    tipo_oferta VARCHAR(10)  NOT NULL CHECK ( tipo_oferta IN ('Movel', 'Fibra')), --trava no banco pra impedir qualquer valor diferente desses dois — segurança extra, mesmo que a interface também valide isso depois.
    ativo       BOOLEAN DEFAULT TRUE
);

CREATE TABLE lotes_estração
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
    id_lote                 INTEGER REFERENCES lotes_estração (id_lote),
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

