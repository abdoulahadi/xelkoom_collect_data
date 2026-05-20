#!/usr/bin/env python3
"""
Script pour tester les routes principales de l'API
"""

import requests
import json

API_BASE = "http://localhost:8000"

def test_health():
    """Test de santé de l'API"""
    try:
        response = requests.get(f"{API_BASE}/health")
        print(f"✅ Health check: {response.status_code}")
        print(f"   Response: {response.json()}")
        return True
    except Exception as e:
        print(f"❌ Health check failed: {e}")
        return False

def test_login():
    """Test de connexion admin"""
    try:
        response = requests.post(f"{API_BASE}/auth/login", 
                               params={"username": "admin"})
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Admin login: {response.status_code}")
            print(f"   Token: {data['access_token'][:50]}...")
            return data['access_token']
        else:
            print(f"❌ Admin login failed: {response.status_code}")
            print(f"   Response: {response.text}")
            return None
    except Exception as e:
        print(f"❌ Admin login error: {e}")
        return None

def test_admin_stats(token):
    """Test des statistiques admin"""
    try:
        headers = {"Authorization": f"Bearer {token}"}
        response = requests.get(f"{API_BASE}/admin/stats", headers=headers)
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Admin stats: {response.status_code}")
            print(f"   Users: {data['total_users']}")
            print(f"   Recordings: {data['total_recordings']}")
            print(f"   Sentences: {data['total_sentences']}")
            return True
        else:
            print(f"❌ Admin stats failed: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Admin stats error: {e}")
        return False

def test_admin_users(token):
    """Test de la liste des utilisateurs"""
    try:
        headers = {"Authorization": f"Bearer {token}"}
        response = requests.get(f"{API_BASE}/admin/users", headers=headers)
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Admin users: {response.status_code}")
            print(f"   Total: {data['total']}")
            print(f"   Users: {len(data['items'])}")
            return True
        else:
            print(f"❌ Admin users failed: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Admin users error: {e}")
        return False

def test_register():
    """Test d'inscription d'un nouvel utilisateur"""
    try:
        import random
        test_user = {
            "username": f"test_mobile_user_{random.randint(1000, 9999)}",
            "gender": "male",
            "age_range": "25-34",
            "consent_given": True
        }
        print(f"   Registering user: {test_user}")
        response = requests.post(f"{API_BASE}/auth/register", json=test_user)
        print(f"   Response status: {response.status_code}")
        print(f"   Response headers: {dict(response.headers)}")
        if response.status_code == 200:
            data = response.json()
            print(f"✅ User registration: {response.status_code}")
            print(f"   Token: {data['access_token'][:50]}...")
            return True
        else:
            print(f"❌ User registration failed: {response.status_code}")
            try:
                error_detail = response.json()
                print(f"   Response JSON: {error_detail}")
            except:
                print(f"   Response Text: {response.text}")
            return False
    except Exception as e:
        print(f"❌ User registration error: {e}")
        import traceback
        traceback.print_exc()
        return False

def test_user_stats(token):
    """Test des statistiques utilisateur"""
    try:
        headers = {"Authorization": f"Bearer {token}"}
        response = requests.get(f"{API_BASE}/users/me/stats", headers=headers)
        if response.status_code == 200:
            data = response.json()
            print(f"✅ User stats: {response.status_code}")
            print(f"   Total recordings: {data['total_recordings']}")
            print(f"   Validated: {data['validated_recordings']}")
            print(f"   Pending: {data['pending_recordings']}")
            return True
        else:
            print(f"❌ User stats failed: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
    except Exception as e:
        print(f"❌ User stats error: {e}")
        return False

def main():
    """Test des routes principales"""
    print("🚀 Test des routes API Xelkoom")
    print("=" * 40)
    
    # Test de santé
    if not test_health():
        print("❌ Serveur non accessible")
        return
    
    # Test de connexion
    token = test_login()
    if not token:
        print("❌ Impossible de se connecter")
        return
    
    # Test des statistiques
    test_admin_stats(token)
    
    # Test de la liste des utilisateurs
    test_admin_users(token)
    
    # Test d'inscription
    test_register()
    
    # Test des statistiques utilisateur avec l'admin
    test_user_stats(token)
    
    print("\n" + "=" * 40)
    print("✅ Tests terminés")

if __name__ == "__main__":
    main()
