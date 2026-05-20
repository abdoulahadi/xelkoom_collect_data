#!/usr/bin/env python3
"""
Script de lancement du serveur FastAPI
"""

import sys
import os
import importlib.util
from pathlib import Path

# Ajouter le répertoire courant au PYTHONPATH pour pouvoir importer app
current_dir = Path(__file__).parent.absolute()
sys.path.insert(0, str(current_dir))

# Vérifier que les modules peuvent être importés correctement
def check_imports():
    """Vérifier que les modules nécessaires peuvent être importés correctement"""
    try:
        import app.main
        print("✅ Modules importés avec succès")
        return True
    except ImportError as e:
        print(f"❌ Erreur d'import: {e}")
        print("⚠️  Conseil: Assurez-vous que Python peut trouver le module 'app'")
        print("   Vous pouvez essayer: python -m pip install -e .")
        return False

# Maintenant importer et lancer l'application
if __name__ == "__main__":
    import uvicorn
    
    print("🚀 Démarrage du serveur Xelkoom API")
    print(f"📁 Répertoire de travail: {current_dir}")
    
    # Vérifier les imports avant de démarrer le serveur
    if not check_imports():
        sys.exit(1)
    
    print("🌐 Serveur accessible sur: http://localhost:8000")
    print("📚 Documentation API: http://localhost:8000/docs")
    
    uvicorn.run(
        "app.main:app",  # Utiliser la chaîne d'importation au lieu de l'objet direct
        host="0.0.0.0",
        port=8000,
        reload=True  # Activer le reload pour le développement
    )
