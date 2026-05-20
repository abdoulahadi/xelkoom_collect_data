"""
Utilitaires pour la validation et la conversion des modèles avec Pydantic
"""
import uuid
from typing import Any, Dict, List, Union, Optional
from pydantic import BaseModel

def convert_uuid_values(obj: Any) -> Any:
    """
    Convertit les objets UUID en chaînes pour faciliter la validation Pydantic
    Cette fonction est récursive et peut gérer des dictionnaires, des listes et des types primitifs
    """
    if isinstance(obj, uuid.UUID):
        return str(obj)
    elif isinstance(obj, dict):
        return {k: convert_uuid_values(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [convert_uuid_values(item) for item in obj]
    elif isinstance(obj, tuple):
        return tuple(convert_uuid_values(item) for item in obj)
    else:
        return obj

def model_to_dict(obj: Any) -> Dict[str, Any]:
    """
    Convertit un objet SQLAlchemy en dictionnaire compatible avec Pydantic
    Gère correctement les UUID et autres types complexes
    """
    if hasattr(obj, "__table__"):
        # Objet SQLAlchemy
        result = {}
        for column in obj.__table__.columns:
            value = getattr(obj, column.name)
            result[column.name] = convert_uuid_values(value)
        return result
    elif hasattr(obj, "__dict__"):
        # Objet Python standard avec dictionnaire d'attributs
        return {k: convert_uuid_values(v) for k, v in obj.__dict__.items() 
                if not k.startswith('_')}
    else:
        # Cas par défaut, essayer de convertir directement
        return convert_uuid_values(obj)
