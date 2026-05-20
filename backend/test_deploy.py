#!/usr/bin/env python3
"""
Script de test pour vérifier que l'application est prête pour le déploiement
"""

import os
import sys
import requests
import subprocess
import time
from pathlib import Path

def check_docker():
    """Vérifier que Docker est disponible"""
    try:
        result = subprocess.run(['docker', '--version'], capture_output=True, text=True)
        if result.returncode == 0:
            print("✅ Docker est disponible")
            return True
        else:
            print("❌ Docker n'est pas disponible")
            return False
    except FileNotFoundError:
        print("❌ Docker n'est pas installé")
        return False

def check_files():
    """Vérifier que tous les fichiers nécessaires sont présents"""
    required_files = [
        'Dockerfile',
        'requirements.txt',
        '.dockerignore',
        'app/main.py',
        'start_production.py'
    ]
    
    missing_files = []
    for file in required_files:
        if not Path(file).exists():
            missing_files.append(file)
    
    if missing_files:
        print(f"❌ Fichiers manquants: {', '.join(missing_files)}")
        return False
    else:
        print("✅ Tous les fichiers requis sont présents")
        return True

def build_docker_image():
    """Construire l'image Docker"""
    print("🔨 Construction de l'image Docker...")
    try:
        result = subprocess.run(
            ['docker', 'build', '-t', 'xelkoom-test', '.'],
            capture_output=True,
            text=True
        )
        
        if result.returncode == 0:
            print("✅ Image Docker construite avec succès")
            return True
        else:
            print(f"❌ Erreur lors de la construction: {result.stderr}")
            return False
    except Exception as e:
        print(f"❌ Erreur: {e}")
        return False

def test_container():
    """Tester le conteneur"""
    print("🧪 Test du conteneur...")
    
    # Arrêter tout conteneur de test existant
    subprocess.run(['docker', 'stop', 'xelkoom-test-run'], capture_output=True)
    subprocess.run(['docker', 'rm', 'xelkoom-test-run'], capture_output=True)
    
    try:
        # Démarrer le conteneur
        result = subprocess.run([
            'docker', 'run', '-d', '--name', 'xelkoom-test-run',
            '-p', '8002:8000',
            '-e', 'DATABASE_URL=sqlite:///./test.db',
            '-e', 'SECRET_KEY=test-secret-key-for-testing-only',
            '-e', 'DEBUG=false',
            'xelkoom-test'
        ], capture_output=True, text=True)
        
        if result.returncode != 0:
            print(f"❌ Erreur lors du démarrage du conteneur: {result.stderr}")
            return False
        
        # Attendre que le serveur démarre
        print("⏳ Attente du démarrage du serveur...")
        time.sleep(10)
        
        # Tester l'endpoint de santé
        try:
            response = requests.get('http://localhost:8002/health', timeout=5)
            if response.status_code == 200:
                print("✅ Test de santé réussi")
                print(f"   Réponse: {response.json()}")
                return True
            else:
                print(f"❌ Test de santé échoué: {response.status_code}")
                return False
        except requests.RequestException as e:
            print(f"❌ Impossible de se connecter au serveur: {e}")
            return False
        
    finally:
        # Nettoyer
        subprocess.run(['docker', 'stop', 'xelkoom-test-run'], capture_output=True)
        subprocess.run(['docker', 'rm', 'xelkoom-test-run'], capture_output=True)

def main():
    """Fonction principale"""
    print("🚀 Test de préparation pour le déploiement Render\n")
    
    # Vérifications
    checks = [
        ("Docker", check_docker),
        ("Fichiers requis", check_files),
        ("Construction Docker", build_docker_image),
        ("Test du conteneur", test_container)
    ]
    
    all_passed = True
    for name, check_func in checks:
        print(f"\n📋 Vérification: {name}")
        if not check_func():
            all_passed = False
            break
    
    print("\n" + "="*50)
    if all_passed:
        print("🎉 Tous les tests sont passés !")
        print("✅ Votre application est prête pour le déploiement sur Render")
        print("\n📋 Prochaines étapes :")
        print("1. Commitez et poussez votre code sur GitHub")
        print("2. Créez les services sur Render (DB, Redis, Web)")
        print("3. Configurez les variables d'environnement")
        print("4. Déployez !")
        print("\n📖 Voir README_DEPLOY_RENDER.md pour les détails")
    else:
        print("❌ Certains tests ont échoué")
        print("🔧 Corrigez les erreurs avant de déployer")
        sys.exit(1)

if __name__ == "__main__":
    main()
