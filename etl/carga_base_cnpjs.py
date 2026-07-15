import re
import glob
import pandas as pd
from sqlalchemy import text
from conexao import get_engine


import os

import os

# Caminho absoluto da pasta onde ESTE script está (C:\Users\T.I\Projetos\gestao-leads\etl)
DIRETORIO_DO_SCRIPT = os.path.dirname(os.path.abspath(__file__))

# Subir um nível para ir para a raiz do projeto (C:\Users\T.I\Projetos\gestao-leads)
RAIZ_DO_PROJETO = os.path.dirname(DIRETORIO_DO_SCRIPT)

# Agora sim, aponta para a pasta 'dados' que está fora do etl
PASTA_DADOS = os.path.join(RAIZ_DO_PROJETO, 'dados')

def listar_csvs(pasta):
    # pega todos os arquivos .csv dentro da pasta, em ordem alfabética
    caminhos = sorted(glob.glob(f"{pasta}/*.csv"))
    if not caminhos:
        raise FileNotFoundError(f"Nenhum .csv encontrado em '{pasta}/'")
    return caminhos


def ler_csv(caminho):
    df = pd.read_csv(caminho, sep=";", encoding="utf-8-sig", dtype=str)
    return df


def ler_todos_csvs(pasta):
    caminhos = listar_csvs(pasta)
    dataframes = []
    for caminho in caminhos:
        df = ler_csv(caminho)
        print(f"Lido: {caminho} ({len(df)} linhas)")
        dataframes.append(df)
    return pd.concat(dataframes, ignore_index=True)


def limpar_cnpj(cnpj):
    return re.sub(r"\D", "", str(cnpj))


def limpar_telefone(tel1, tel2):
    def valido(tel):
        if pd.isna(tel):
            return None
        tel = str(tel).strip()
        if tel == "" or tel == "000000000000":
            return None
        return tel

    tel1_valido = valido(tel1)
    if tel1_valido:
        return tel1_valido
    return valido(tel2)


def transformar(df):
    saida = pd.DataFrame()
    saida["cnpj"] = df["CNPJ"].apply(limpar_cnpj)
    saida["razao_social"] = df["Razão"].str.strip()
    saida["telefone"] = df.apply(lambda linha: limpar_telefone(linha["Telefone 1"], linha["Telefone 2"]), axis=1)
    saida["uf"] = df["UF"].str.strip()
    saida["cidade"] = df["Cidade"].str.strip()
    saida["tipo_oferta_disp"] = "Movel"
    saida["ativo"] = True

    # 1. REMOVE LINHAS ONDE O CNPJ FICOU VAZIO
    saida = saida[saida["cnpj"].str.strip() != ""]

    # 2. REMOVE DUPLICADOS (Mantendo o que você já tinha feito)
    antes = len(saida)
    saida = saida.drop_duplicates(subset="cnpj", keep="last")
    if antes != len(saida):
        print(f"Aviso: {antes - len(saida)} CNPJs duplicados entre os arquivos, mantida a última ocorrência.")

    # 3. CONVERTE 'nan' DO PANDAS PARA 'None' DO PYTHON (Evita o erro do character(2))
    saida = saida.where(pd.notna(saida), None)

    return saida


SQL_UPSERT = text("""
                  INSERT INTO base_cnpjs (cnpj, razao_social, telefone, uf, cidade, tipo_oferta_disp, ativo, atualizado_em)
                  VALUES (:cnpj, :razao_social, :telefone, :uf, :cidade, :tipo_oferta_disp, :ativo, NOW())
                      ON CONFLICT (cnpj) DO UPDATE SET
                      razao_social      = EXCLUDED.razao_social,
                                                telefone          = EXCLUDED.telefone,
                                                uf                = EXCLUDED.uf,
                                                cidade            = EXCLUDED.cidade,
                                                tipo_oferta_disp  = EXCLUDED.tipo_oferta_disp,
                                                ativo             = EXCLUDED.ativo,
                                                atualizado_em     = NOW()
                  """)


def carregar(engine, df):
    registros = df.to_dict(orient="records")
    with engine.begin() as conexao:
        for linha in registros:
            conexao.execute(SQL_UPSERT, linha)
    print(f"{len(registros)} CNPJs processados (inseridos ou atualizados).")


if __name__ == "__main__":
    engine = get_engine()
    df_bruto = ler_todos_csvs(PASTA_DADOS)
    df_pronto = transformar(df_bruto)
    carregar(engine, df_pronto)