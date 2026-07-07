INSERT INTO operadores (nome, perfil)
VALUES ('João Silva', 'Operador'),
       ('Maria Souza', 'Operador'),
       ('Carlos Lima', 'Supervisor');

INSERT INTO planos(nome_plano, tipo_oferta)
VALUES ('Vivo Empresas Controle 20GB', 'Movel'),
       ('Vivo Empresas Controle 50GB', 'Movel'),
       ('Vivo Fibra 300MB', 'Fibra'),
       ('Vivo Fibra 500MB', 'Fibra');

INSERT INTO base_cnpjs (cnpj, razao_social, telefone, uf, cidade, tipo_oferta_disp)
VALUES ('11222333000181', 'Comercial Silva Ltda', '11987654321', 'SP', 'São Paulo', 'Movel'),
       ('22333444000192', 'Distribuidora Souza EIRELI', '11976543210', 'SP', 'Campinas', 'Fibra'),
       ('33444555000103', 'Indústria Lima S.A.', '41965432109', 'PR', 'Curitiba', 'Ambos'),
       ('44555666000114', 'Comércio Pereira ME', '21954321098', 'RJ', 'Rio de Janeiro', 'Movel');