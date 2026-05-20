#!/usr/bin/env python3
"""
Script d'installation du backend Xelkoom
"""
import os
import subprocess
import sys
import re
from pathlib import Path

# Définir le répertoire racine
ROOT_DIR = Path(__file__).parent.absolute()

def run_command(command, cwd=None):
    """Run a system command and print output"""
    print(f"Exécution: {command}")
    if cwd is None:
        cwd = ROOT_DIR
    process = subprocess.run(command, shell=True, cwd=str(cwd), check=False)
    return process.returncode == 0

def fix_script_paths():
    """Fix Python path in scripts to properly import app modules"""
    print("\n--- Correction des chemins Python dans les scripts ---")
    scripts_dir = ROOT_DIR / "scripts"
    fixed_count = 0
    
    for script_file in scripts_dir.glob("*.py"):
        with open(script_file, "r", encoding="utf-8") as f:
            content = f.read()
        
        # Skip files that already have the correct path setup
        if "sys.path.insert(0, str(Path(__file__).parent.parent))" in content:
            continue
            
        # Replace incorrect path setup with correct one
        if "sys.path.insert(0, str(Path(__file__).parent))" in content:
            new_content = content.replace(
                "sys.path.insert(0, str(Path(__file__).parent))",
                "sys.path.insert(0, str(Path(__file__).parent.parent))"
            )
            with open(script_file, "w", encoding="utf-8") as f:
                f.write(new_content)
            fixed_count += 1
    
    if fixed_count > 0:
        print(f"✅ Corrigé {fixed_count} script(s)")
    else:
        print("✅ Tous les scripts ont des chemins corrects")

def setup_environment():
    """Configure l'environnement"""
    print("\n--- Configuration de l'environnement ---")
    
    # Vérifier si .env existe, sinon copier .env.example
    env_file = ROOT_DIR / ".env"
    env_example_file = ROOT_DIR / ".env.example"
    
    if not env_file.exists() and env_example_file.exists():
        print("Création du fichier .env à partir de .env.example")
        with open(env_example_file, "r") as f_src:
            with open(env_file, "w") as f_dst:
                f_dst.write(f_src.read())
        print("Fichier .env créé. Veuillez modifier les valeurs selon votre configuration.")
    elif not env_file.exists() and not env_example_file.exists():
        print("ATTENTION: Ni .env ni .env.example n'ont été trouvés.")
    else:
        print("Fichier .env déjà présent.")

def setup_database():
    """Configure la base de données"""
    print("\n--- Configuration de la base de données ---")
    if run_command("python scripts/init_db.py"):
        print("Base de données initialisée avec succès")
    else:
        print("ERREUR lors de l'initialisation de la base de données")
        return False
    
    if run_command("alembic upgrade head"):
        print("Migrations appliquées avec succès")
    else:
        print("ERREUR lors de l'application des migrations")
        return False
    
    return True

def setup_initial_data():
    """Ajoute les données initiales"""
    print("\n--- Ajout des données initiales ---")
    if run_command("python scripts/create_admin_user.py"):
        print("Utilisateur administrateur créé avec succès")
    else:
        print("ERREUR lors de la création de l'utilisateur administrateur")
    
    if run_command("python scripts/add_sample_sentences.py"):
        print("Phrases d'exemple ajoutées avec succès")
    else:
        print("ERREUR lors de l'ajout des phrases d'exemple")

def main():
    """Point d'entrée principal"""
    print("=== Installation du backend Xelkoom ===")
    
    # Étape 1: Configuration de l'environnement
    setup_environment()
    
    # Étape 2: Correction des chemins dans les scripts
    fix_script_paths()
    
    # Demander à l'utilisateur s'il souhaite continuer
    choice = input("\nVoulez-vous initialiser la base de données? [o/N]: ")
    if choice.lower() != "o":
        print("Installation interrompue.")
        return
    
    # Étape 2: Configuration de la base de données
    if not setup_database():
        print("Installation interrompue en raison d'erreurs.")
        return
    
    # Étape 3: Ajout des données initiales
    choice = input("\nVoulez-vous ajouter les données initiales? [o/N]: ")
    if choice.lower() == "o":
        setup_initial_data()
    
    print("\n=== Installation terminée ===")
    print("Pour démarrer le serveur, exécutez:")
    print("python start_server.py")
    print("ou")
    print("python scripts/manage.py start --reload")

if __name__ == "__main__":
    main()
