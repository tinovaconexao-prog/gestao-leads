import os
from dotenv import load_dotenv

from sqlalchemy import create_engine

# Carrega as variaveis do arquivo .env para o ambiente
load_dotenv()


def get_engine():
    '''Cria e retorna uma engine de conexão com o PostgreSQL.'''

    usuario = os.getenv("DB_USER")
    senha = os.getenv("DB_PASSWORD")
    host = os.getenv("DB_HOST")
    porta = os.getenv("DB_PORT")
    banco = os.getenv("DB_NAME")

    url_conexao = f"postgresql+psycopg2://{usuario}:{senha}@{host}:{porta}/{banco}"
    engine = create_engine(url_conexao)
    return engine

if __name__ == "__main__":

    engine = get_engine()
    try:
        with engine.connect() as conexao:
            print("Conexao com banco de dados bem sucedida")
    except Exception as erro:
        print(f"Erro ao conectar: {erro}")
        print(f"Tipo do erro: {type(erro)}")
        if hasattr(erro, 'orig'):
            print(f"Erro original (psycopg2): {erro.orig}")
            print(f"Args do erro original: {erro.orig.args}")