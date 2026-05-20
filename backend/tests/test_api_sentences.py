#!/usr/bin/env python3
"""
Script pour démarrer le serveur et tester l'API
"""

import subprocess
import time
import requests
import json
import sys
import threading
from pathlib import Path

# Ajouter le répertoire backend au path Python
backend_path = Path(__file__).parent
sys.path.insert(0, str(backend_path))

def start_server():
    """Démarrer le serveur FastAPI en arrière-plan"""
    try:
        process = subprocess.Popen(
            ["python", "start_server.py"],
            cwd=backend_path,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )
        return process
    except Exception as e:
        print(f"Erreur lors du démarrage du serveur: {e}")
        return None

def test_sentences_api():
    """Tester l'API des phrases"""
    base_url = "http://localhost:8000"
    
    # Attendre que le serveur démarre
    print("Attente du démarrage du serveur...")
    for i in range(30):  # Attendre max 30 secondes
        try:
            response = requests.get(f"{base_url}/health")
            if response.status_code == 200:
                print("✅ Serveur démarré avec succès")
                break
        except requests.exceptions.ConnectionError:
            time.sleep(1)
    else:
        print("❌ Impossible de se connecter au serveur")
        return False
    
    print("\n=== Test de l'API des phrases ===")
    
    # Test 1: Distribution stats publique
    try:
        print("\n1. Test de /api/sentences/distribution-stats")
        response = requests.get(f"{base_url}/api/sentences/distribution-stats")
        print(f"   Status: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"   ✅ Données reçues:")
            print(f"     - Total phrases: {data.get('total_sentences', 'N/A')}")
            print(f"     - Target par phrase: {data.get('target_recordings_per_sentence', 'N/A')}")
            print(f"     - Sous l'objectif: {data.get('distribution', {}).get('under_target', 'N/A')}")
            print(f"     - À l'objectif: {data.get('distribution', {}).get('at_target', 'N/A')}")
            print(f"     - Sur l'objectif: {data.get('distribution', {}).get('over_target', 'N/A')}")
        else:
            print(f"   ❌ Erreur: {response.text}")
            
    except Exception as e:
        print(f"   ❌ Exception: {e}")
    
    # Test 2: Essayer de créer un token admin pour tester les routes admin
    print("\n2. Tentative de connexion admin")
    try:
        # Essayer de se connecter en tant qu'admin (assurez-vous qu'un admin existe)
        login_data = {"username": "admin"}  # Assuming passwordless login for admin
        response = requests.post(f"{base_url}/api/auth/login", json=login_data)
        print(f"   Status login: {response.status_code}")
        
        if response.status_code == 200:
            token_data = response.json()
            token = token_data.get("access_token")
            headers = {"Authorization": f"Bearer {token}"}
            
            # Test route admin des phrases
            print("\n3. Test de /api/admin/sentences (avec auth)")
            response = requests.get(
                f"{base_url}/api/admin/sentences?skip=0&limit=5",
                headers=headers
            )
            print(f"   Status: {response.status_code}")
            
            if response.status_code == 200:
                data = response.json()
                print(f"   ✅ Réponse admin reçue:")
                print(f"     - Total: {data.get('total', 'N/A')}")
                print(f"     - Page: {data.get('page', 'N/A')}")
                print(f"     - Items: {len(data.get('items', []))}")
                
                # Vérifier les champs recording_count
                items = data.get('items', [])
                if items:
                    first_item = items[0]
                    print(f"     - Premier item:")
                    print(f"       * ID: {first_item.get('id', 'N/A')}")
                    print(f"       * Text: {first_item.get('text', '')[:50]}...")
                    print(f"       * Recording count: {first_item.get('recording_count', 'N/A')}")
                    print(f"       * Validated recordings: {first_item.get('validated_recordings', 'N/A')}")
                    print(f"       * Pending recordings: {first_item.get('pending_recordings', 'N/A')}")
                    print(f"       * Rejected recordings: {first_item.get('rejected_recordings', 'N/A')}")
                    
                    # Vérifier si le comptage n'est pas toujours zéro
                    has_recordings = any(
                        item.get('recording_count', 0) > 0 
                        for item in items
                    )
                    if has_recordings:
                        print(f"   ✅ Au moins une phrase a des enregistrements")
                    else:
                        print(f"   ⚠️ Toutes les phrases ont 0 enregistrement")
            else:
                print(f"   ❌ Erreur admin: {response.text}")
                
        else:
            print(f"   ❌ Échec de connexion: {response.text}")
            print("   Note: Assurez-vous qu'un utilisateur admin existe")
            
    except Exception as e:
        print(f"   ❌ Exception admin: {e}")
    
    print("\n=== Fin des tests ===")
    return True

if __name__ == "__main__":
    print("Démarrage des tests de l'API des phrases")
    
    # Démarrer le serveur
    server_process = start_server()
    
    try:
        # Attendre un peu que le serveur démarre
        time.sleep(3)
        
        # Tester l'API
        success = test_sentences_api()
        
        if success:
            print("\n✅ Tests terminés")
        else:
            print("\n❌ Tests échoués")
            
    finally:
        # Arrêter le serveur
        if server_process:
            print("\nArrêt du serveur...")
            server_process.terminate()
            server_process.wait()
            print("Serveur arrêté")
