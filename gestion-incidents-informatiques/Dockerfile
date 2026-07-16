FROM python:3.12-slim

WORKDIR /app

# Installer les dépendances d'abord (meilleure utilisation du cache Docker)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copier le reste du code de l'application
COPY . .

EXPOSE 5000

CMD ["python", "run.py"]
