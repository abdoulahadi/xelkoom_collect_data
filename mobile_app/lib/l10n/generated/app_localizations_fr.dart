// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Xelkoom';

  @override
  String get navHome => 'Accueil';

  @override
  String get navRecord => 'Enregistrer';

  @override
  String get navLeaderboard => 'Classement';

  @override
  String get navProfile => 'Profil';

  @override
  String get loginTitle => 'Connexion';

  @override
  String get loginWelcome => 'Bon retour !';

  @override
  String get loginSubtitle => 'Connectez-vous avec vos identifiants';

  @override
  String get loginUsernameLabel => 'Nom d\'utilisateur';

  @override
  String get loginUsernameHint => 'Entrez votre nom d\'utilisateur';

  @override
  String get loginPasswordLabel => 'Mot de passe';

  @override
  String get loginPasswordHint => 'Entrez votre mot de passe';

  @override
  String get loginButton => 'Se connecter';

  @override
  String get loginNoAccount => 'Pas encore inscrit ? Créer un compte';

  @override
  String get registerTitle => 'Inscription';

  @override
  String get registerHeading => 'Créer votre compte';

  @override
  String get registerSubtitle => 'Rejoignez la communauté Xelkoom';

  @override
  String get registerButton => 'S\'inscrire';

  @override
  String get registerConfirmPassword => 'Confirmer le mot de passe';

  @override
  String get registerGender => 'Genre';

  @override
  String get registerAgeRange => 'Tranche d\'âge';

  @override
  String get registerConsent => 'J\'accepte que mes enregistrements vocaux soient utilisés pour améliorer la technologie de reconnaissance vocale en Wolof.';

  @override
  String get registerPrivacyPolicy => 'Politique de confidentialité';

  @override
  String get registerAlreadyRegistered => 'Déjà inscrit ? Se connecter';

  @override
  String get registerSuccess => 'Inscription réussie !';

  @override
  String get onboardingSkip => 'Passer';

  @override
  String get onboardingPrevious => 'Précédent';

  @override
  String get onboardingNext => 'Suivant';

  @override
  String get onboardingStart => 'Commencer';

  @override
  String get onboardingReady => 'Prêt à commencer ?';

  @override
  String get onboardingJoin => 'Rejoignez la communauté Xelkoom';

  @override
  String get onboardingCreateAccount => 'Créer un compte';

  @override
  String get onboardingHaveAccount => 'J\'ai déjà un compte';

  @override
  String get recordingTitle => 'Enregistrement';

  @override
  String get recordingNewSentence => 'Nouvelle phrase';

  @override
  String get recordingSend => 'Envoyer';

  @override
  String get recordingIdle => 'Appuyez sur le bouton pour commencer';

  @override
  String get recordingPreparing => 'Préparation...';

  @override
  String get recordingInProgress => 'Enregistrement en cours...';

  @override
  String get recordingFinished => 'Enregistrement terminé';

  @override
  String get recordingPlaying => 'Lecture en cours...';

  @override
  String get recordingUploading => 'Envoi en cours...';

  @override
  String get recordingUploadSuccess => 'Enregistrement envoyé avec succès !';

  @override
  String get recordingError => 'Une erreur est survenue';

  @override
  String get recordingStop => 'Arrêter';

  @override
  String get recordingRecord => 'Enregistrer';

  @override
  String get recordingRetry => 'Réessayer';

  @override
  String get recordingSentenceError => 'Erreur lors du chargement de la phrase';

  @override
  String get historyTitle => 'Mes enregistrements';

  @override
  String get historyEmpty => 'Aucun enregistrement';

  @override
  String get historyEmptySubtitle => 'Vous n\'avez pas encore d\'enregistrements.\nCommencez à enregistrer pour les voir ici.';

  @override
  String get historyLoadingError => 'Erreur de chargement';

  @override
  String get historyRetry => 'Réessayer';

  @override
  String get historyDelete => 'Supprimer';

  @override
  String get historyClose => 'Fermer';

  @override
  String get statusPending => 'En attente';

  @override
  String get statusValidated => 'Validé';

  @override
  String get statusRejected => 'Rejeté';

  @override
  String get statusPendingDetail => 'En attente de validation';

  @override
  String get statusValidatedDetail => 'Validé par un modérateur';

  @override
  String get statusRejectedDetail => 'Rejeté par un modérateur';

  @override
  String dashboardHello(String username) {
    return 'Bonjour $username !';
  }

  @override
  String get dashboardSubtitle => 'Prêt à contribuer à l\'avenir de la technologie vocale en Wolof ?';

  @override
  String get dashboardStats => 'Vos statistiques';

  @override
  String get dashboardRecordings => 'Enregistrements';

  @override
  String get dashboardPoints => 'Points';

  @override
  String get dashboardTotalTime => 'Temps total';

  @override
  String get dashboardRank => 'Rang';

  @override
  String get dashboardQuickActions => 'Actions rapides';

  @override
  String get dashboardStartRecording => 'Commencer un enregistrement';

  @override
  String get dashboardRecordNew => 'Enregistrez une nouvelle phrase';

  @override
  String get dashboardMyRecordings => 'Mes enregistrements';

  @override
  String get dashboardSeeContributions => 'Voir vos contributions';

  @override
  String get dashboardRecentActivity => 'Activité récente';

  @override
  String get dashboardNoActivity => 'Aucune activité récente';

  @override
  String get dashboardNoActivityHint => 'Commencez à enregistrer pour voir votre activité ici.';

  @override
  String get dashboardSeeAll => 'Voir tous les enregistrements';

  @override
  String get profileTitle => 'Profil';

  @override
  String get profilePersonalInfo => 'Informations personnelles';

  @override
  String get profileStats => 'Mes statistiques';

  @override
  String get profileAccountActions => 'Actions du compte';

  @override
  String get profileAbout => 'À propos';

  @override
  String get profileSync => 'Actualiser les données';

  @override
  String get profileSyncSubtitle => 'Synchroniser avec le serveur';

  @override
  String get profileDeleteAccount => 'Supprimer le compte';

  @override
  String get profileDeleteSubtitle => 'Suppression définitive (RGPD)';

  @override
  String get profileUsernameUpdated => 'Nom d\'utilisateur mis à jour avec succès';

  @override
  String get profileDataRefreshed => 'Données actualisées';

  @override
  String get leaderboardTitle => 'Classement';

  @override
  String get leaderboardYourRank => 'Votre rang';

  @override
  String get leaderboardEmpty => 'Aucun classement disponible';

  @override
  String get leaderboardEmptyHint => 'Commencez à enregistrer pour apparaître dans le classement !';

  @override
  String get leaderboardYou => 'Vous';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsAccount => 'Compte';

  @override
  String get settingsRecording => 'Enregistrement';

  @override
  String get settingsApp => 'Application';

  @override
  String get settingsPrivacyLegal => 'Confidentialité et Légal';

  @override
  String get settingsSupport => 'Support';

  @override
  String get settingsAbout => 'À propos';

  @override
  String get settingsAutoUpload => 'Upload automatique';

  @override
  String get settingsAutoUploadSubtitle => 'Envoyer automatiquement les enregistrements';

  @override
  String get settingsAudioQuality => 'Qualité audio';

  @override
  String get settingsLocalStorage => 'Stockage local';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsTheme => 'Thème';

  @override
  String get settingsReset => 'Réinitialiser les paramètres';

  @override
  String get settingsReviewTutorial => 'Revoir le tutoriel';

  @override
  String get settingsPrivacyPolicy => 'Politique de confidentialité';

  @override
  String get settingsTerms => 'Conditions d\'utilisation';

  @override
  String get settingsPermissions => 'Permissions';

  @override
  String get settingsHelp => 'Centre d\'aide';

  @override
  String get settingsFeedback => 'Feedback';

  @override
  String get settingsBugReport => 'Signaler un problème';

  @override
  String get settingsCheckUpdates => 'Vérifier les mises à jour';

  @override
  String get settingsResetConfirm => 'Êtes-vous sûr de vouloir restaurer tous les paramètres par défaut ?';

  @override
  String get settingsResetDone => 'Paramètres réinitialisés';

  @override
  String get settingsCacheCleared => 'Cache nettoyé';

  @override
  String get dialogCancel => 'Annuler';

  @override
  String get dialogOk => 'OK';

  @override
  String get dialogDelete => 'Supprimer';

  @override
  String get dialogLogout => 'Déconnexion';

  @override
  String get dialogLogoutConfirm => 'Êtes-vous sûr de vouloir vous déconnecter ?';

  @override
  String get dialogDeleteAccountConfirm => 'Cette action est irréversible. Toutes vos données seront définitivement supprimées. Êtes-vous sûr de vouloir continuer ?';

  @override
  String get dialogDeleteRecordingConfirm => 'Êtes-vous sûr de vouloir supprimer cet enregistrement ?';

  @override
  String get permissionTitle => 'Configuration des permissions';

  @override
  String get permissionSubtitle => 'Xelkoom a besoin de certaines permissions pour fonctionner correctement.';

  @override
  String get permissionChecking => 'Vérification des permissions...';

  @override
  String get permissionRequired => 'Permissions nécessaires :';

  @override
  String get permissionMicrophone => 'Microphone';

  @override
  String get permissionStorage => 'Stockage';

  @override
  String get permissionConfigure => 'Configurer les permissions';

  @override
  String get permissionSkip => 'Continuer sans configurer maintenant';

  @override
  String get permissionGranted => 'Accordée';

  @override
  String get permissionDenied => 'Refusée';

  @override
  String get validationUsernameRequired => 'Veuillez entrer un nom d\'utilisateur';

  @override
  String get validationUsernameMin => 'Le nom doit contenir au moins 3 caractères';

  @override
  String get validationPasswordRequired => 'Veuillez entrer un mot de passe';

  @override
  String get validationPasswordMin => 'Le mot de passe doit contenir au moins 6 caractères';

  @override
  String get validationPasswordConfirm => 'Veuillez confirmer votre mot de passe';

  @override
  String get validationPasswordMismatch => 'Les mots de passe ne correspondent pas';

  @override
  String get validationConsentRequired => 'Veuillez accepter les conditions d\'utilisation';

  @override
  String get errorGeneric => 'Une erreur est survenue';

  @override
  String get errorNetwork => 'Erreur de connexion au serveur';

  @override
  String get errorUnauthorized => 'Session expirée, veuillez vous reconnecter';

  @override
  String get errorNotFound => 'Ressource introuvable';
}
