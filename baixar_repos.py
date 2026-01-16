import requests
import subprocess
import os

USUARIO = "markovivas"
PASTA_DESTINO = "repositorios"

os.makedirs(PASTA_DESTINO, exist_ok=True)

url = f"https://api.github.com/users/{USUARIO}/repos?per_page=100"

response = requests.get(url)
response.raise_for_status()

repos = response.json()

for repo in repos:
    nome = repo["name"]
    clone_url = repo["clone_url"]
    destino = os.path.join(PASTA_DESTINO, nome)

    if not os.path.exists(destino):
        print(f"Clonando {nome}...")
        subprocess.run(["git", "clone", clone_url, destino])
    else:
        print(f"{nome} já existe, pulando...")