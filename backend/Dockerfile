# Multi-stage build pour optimiser la taille de l'image
FROM python:3.12-slim as builder

# Installer les dépendances système nécessaires pour la compilation
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    make \
    pkg-config \
    ffmpeg \
    libsndfile1 \
    libsox-dev \
    portaudio19-dev \
    && rm -rf /var/lib/apt/lists/*

# Créer un environnement virtuel
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copier et installer les dépendances Python
COPY requirements.txt .
RUN pip install --upgrade pip setuptools wheel
RUN pip install --no-cache-dir -r requirements.txt

# Stage de production
FROM python:3.12-slim

# Installer les dépendances système runtime uniquement
RUN apt-get update && apt-get install -y \
    ffmpeg \
    libsndfile1 \
    libsox3 \
    portaudio19-dev \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Copier l'environnement virtuel depuis le builder
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Créer un utilisateur non-root pour la sécurité
RUN useradd --create-home --shell /bin/bash app
USER app
WORKDIR /home/app

# Copier le code de l'application
COPY --chown=app:app . .

# Créer les répertoires nécessaires
RUN mkdir -p audio uploads/audio

# Variables d'environnement pour la production
ENV PYTHONPATH=/home/app
ENV PYTHONUNBUFFERED=1
ENV ENVIRONMENT=production
ENV DEBUG=false

# Port sur lequel l'application va tourner
EXPOSE 8000

# Health check pour Render
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Admin credentials must be passed at runtime via docker run -e or Docker Secrets

# Commande de démarrage (la création d'admin est gérée dans start_production.py)
CMD ["python", "start_production.py"]
