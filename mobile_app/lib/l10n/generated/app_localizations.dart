import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_fr.dart';
import 'app_localizations_wo.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('fr'),
    Locale('wo')
  ];

  /// No description provided for @appTitle.
  ///
  /// In fr, this message translates to:
  /// **'Xelkoom'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get navHome;

  /// No description provided for @navRecord.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get navRecord;

  /// No description provided for @navLeaderboard.
  ///
  /// In fr, this message translates to:
  /// **'Classement'**
  String get navLeaderboard;

  /// No description provided for @navProfile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get navProfile;

  /// No description provided for @loginTitle.
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get loginTitle;

  /// No description provided for @loginWelcome.
  ///
  /// In fr, this message translates to:
  /// **'Bon retour !'**
  String get loginWelcome;

  /// No description provided for @loginSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous avec vos identifiants'**
  String get loginSubtitle;

  /// No description provided for @loginUsernameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom d\'utilisateur'**
  String get loginUsernameLabel;

  /// No description provided for @loginUsernameHint.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre nom d\'utilisateur'**
  String get loginUsernameHint;

  /// No description provided for @loginPasswordLabel.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get loginPasswordLabel;

  /// No description provided for @loginPasswordHint.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre mot de passe'**
  String get loginPasswordHint;

  /// No description provided for @loginButton.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get loginButton;

  /// No description provided for @loginNoAccount.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore inscrit ? Créer un compte'**
  String get loginNoAccount;

  /// No description provided for @registerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Inscription'**
  String get registerTitle;

  /// No description provided for @registerHeading.
  ///
  /// In fr, this message translates to:
  /// **'Créer votre compte'**
  String get registerHeading;

  /// No description provided for @registerSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Rejoignez la communauté Xelkoom'**
  String get registerSubtitle;

  /// No description provided for @registerButton.
  ///
  /// In fr, this message translates to:
  /// **'S\'inscrire'**
  String get registerButton;

  /// No description provided for @registerConfirmPassword.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le mot de passe'**
  String get registerConfirmPassword;

  /// No description provided for @registerGender.
  ///
  /// In fr, this message translates to:
  /// **'Genre'**
  String get registerGender;

  /// No description provided for @registerAgeRange.
  ///
  /// In fr, this message translates to:
  /// **'Tranche d\'âge'**
  String get registerAgeRange;

  /// No description provided for @registerConsent.
  ///
  /// In fr, this message translates to:
  /// **'J\'accepte que mes enregistrements vocaux soient utilisés pour améliorer la technologie de reconnaissance vocale en Wolof.'**
  String get registerConsent;

  /// No description provided for @registerPrivacyPolicy.
  ///
  /// In fr, this message translates to:
  /// **'Politique de confidentialité'**
  String get registerPrivacyPolicy;

  /// No description provided for @registerAlreadyRegistered.
  ///
  /// In fr, this message translates to:
  /// **'Déjà inscrit ? Se connecter'**
  String get registerAlreadyRegistered;

  /// No description provided for @registerSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Inscription réussie !'**
  String get registerSuccess;

  /// No description provided for @onboardingSkip.
  ///
  /// In fr, this message translates to:
  /// **'Passer'**
  String get onboardingSkip;

  /// No description provided for @onboardingPrevious.
  ///
  /// In fr, this message translates to:
  /// **'Précédent'**
  String get onboardingPrevious;

  /// No description provided for @onboardingNext.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get onboardingNext;

  /// No description provided for @onboardingStart.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get onboardingStart;

  /// No description provided for @onboardingReady.
  ///
  /// In fr, this message translates to:
  /// **'Prêt à commencer ?'**
  String get onboardingReady;

  /// No description provided for @onboardingJoin.
  ///
  /// In fr, this message translates to:
  /// **'Rejoignez la communauté Xelkoom'**
  String get onboardingJoin;

  /// No description provided for @onboardingCreateAccount.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get onboardingCreateAccount;

  /// No description provided for @onboardingHaveAccount.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai déjà un compte'**
  String get onboardingHaveAccount;

  /// No description provided for @recordingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement'**
  String get recordingTitle;

  /// No description provided for @recordingNewSentence.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle phrase'**
  String get recordingNewSentence;

  /// No description provided for @recordingSend.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get recordingSend;

  /// No description provided for @recordingIdle.
  ///
  /// In fr, this message translates to:
  /// **'Appuyez sur le bouton pour commencer'**
  String get recordingIdle;

  /// No description provided for @recordingPreparing.
  ///
  /// In fr, this message translates to:
  /// **'Préparation...'**
  String get recordingPreparing;

  /// No description provided for @recordingInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement en cours...'**
  String get recordingInProgress;

  /// No description provided for @recordingFinished.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement terminé'**
  String get recordingFinished;

  /// No description provided for @recordingPlaying.
  ///
  /// In fr, this message translates to:
  /// **'Lecture en cours...'**
  String get recordingPlaying;

  /// No description provided for @recordingUploading.
  ///
  /// In fr, this message translates to:
  /// **'Envoi en cours...'**
  String get recordingUploading;

  /// No description provided for @recordingUploadSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement envoyé avec succès !'**
  String get recordingUploadSuccess;

  /// No description provided for @recordingError.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue'**
  String get recordingError;

  /// No description provided for @recordingStop.
  ///
  /// In fr, this message translates to:
  /// **'Arrêter'**
  String get recordingStop;

  /// No description provided for @recordingRecord.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get recordingRecord;

  /// No description provided for @recordingRetry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get recordingRetry;

  /// No description provided for @recordingSentenceError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du chargement de la phrase'**
  String get recordingSentenceError;

  /// No description provided for @historyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes enregistrements'**
  String get historyTitle;

  /// No description provided for @historyEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun enregistrement'**
  String get historyEmpty;

  /// No description provided for @historyEmptySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Vous n\'avez pas encore d\'enregistrements.\nCommencez à enregistrer pour les voir ici.'**
  String get historyEmptySubtitle;

  /// No description provided for @historyLoadingError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de chargement'**
  String get historyLoadingError;

  /// No description provided for @historyRetry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get historyRetry;

  /// No description provided for @historyDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get historyDelete;

  /// No description provided for @historyClose.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get historyClose;

  /// No description provided for @statusPending.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get statusPending;

  /// No description provided for @statusValidated.
  ///
  /// In fr, this message translates to:
  /// **'Validé'**
  String get statusValidated;

  /// No description provided for @statusRejected.
  ///
  /// In fr, this message translates to:
  /// **'Rejeté'**
  String get statusRejected;

  /// No description provided for @statusPendingDetail.
  ///
  /// In fr, this message translates to:
  /// **'En attente de validation'**
  String get statusPendingDetail;

  /// No description provided for @statusValidatedDetail.
  ///
  /// In fr, this message translates to:
  /// **'Validé par un modérateur'**
  String get statusValidatedDetail;

  /// No description provided for @statusRejectedDetail.
  ///
  /// In fr, this message translates to:
  /// **'Rejeté par un modérateur'**
  String get statusRejectedDetail;

  /// No description provided for @dashboardHello.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour {username} !'**
  String dashboardHello(String username);

  /// No description provided for @dashboardSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Prêt à contribuer à l\'avenir de la technologie vocale en Wolof ?'**
  String get dashboardSubtitle;

  /// No description provided for @dashboardStats.
  ///
  /// In fr, this message translates to:
  /// **'Vos statistiques'**
  String get dashboardStats;

  /// No description provided for @dashboardRecordings.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrements'**
  String get dashboardRecordings;

  /// No description provided for @dashboardPoints.
  ///
  /// In fr, this message translates to:
  /// **'Points'**
  String get dashboardPoints;

  /// No description provided for @dashboardTotalTime.
  ///
  /// In fr, this message translates to:
  /// **'Temps total'**
  String get dashboardTotalTime;

  /// No description provided for @dashboardRank.
  ///
  /// In fr, this message translates to:
  /// **'Rang'**
  String get dashboardRank;

  /// No description provided for @dashboardQuickActions.
  ///
  /// In fr, this message translates to:
  /// **'Actions rapides'**
  String get dashboardQuickActions;

  /// No description provided for @dashboardStartRecording.
  ///
  /// In fr, this message translates to:
  /// **'Commencer un enregistrement'**
  String get dashboardStartRecording;

  /// No description provided for @dashboardRecordNew.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrez une nouvelle phrase'**
  String get dashboardRecordNew;

  /// No description provided for @dashboardMyRecordings.
  ///
  /// In fr, this message translates to:
  /// **'Mes enregistrements'**
  String get dashboardMyRecordings;

  /// No description provided for @dashboardSeeContributions.
  ///
  /// In fr, this message translates to:
  /// **'Voir vos contributions'**
  String get dashboardSeeContributions;

  /// No description provided for @dashboardRecentActivity.
  ///
  /// In fr, this message translates to:
  /// **'Activité récente'**
  String get dashboardRecentActivity;

  /// No description provided for @dashboardNoActivity.
  ///
  /// In fr, this message translates to:
  /// **'Aucune activité récente'**
  String get dashboardNoActivity;

  /// No description provided for @dashboardNoActivityHint.
  ///
  /// In fr, this message translates to:
  /// **'Commencez à enregistrer pour voir votre activité ici.'**
  String get dashboardNoActivityHint;

  /// No description provided for @dashboardSeeAll.
  ///
  /// In fr, this message translates to:
  /// **'Voir tous les enregistrements'**
  String get dashboardSeeAll;

  /// No description provided for @profileTitle.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get profileTitle;

  /// No description provided for @profilePersonalInfo.
  ///
  /// In fr, this message translates to:
  /// **'Informations personnelles'**
  String get profilePersonalInfo;

  /// No description provided for @profileStats.
  ///
  /// In fr, this message translates to:
  /// **'Mes statistiques'**
  String get profileStats;

  /// No description provided for @profileAccountActions.
  ///
  /// In fr, this message translates to:
  /// **'Actions du compte'**
  String get profileAccountActions;

  /// No description provided for @profileAbout.
  ///
  /// In fr, this message translates to:
  /// **'À propos'**
  String get profileAbout;

  /// No description provided for @profileSync.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser les données'**
  String get profileSync;

  /// No description provided for @profileSyncSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Synchroniser avec le serveur'**
  String get profileSyncSubtitle;

  /// No description provided for @profileDeleteAccount.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le compte'**
  String get profileDeleteAccount;

  /// No description provided for @profileDeleteSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Suppression définitive (RGPD)'**
  String get profileDeleteSubtitle;

  /// No description provided for @profileUsernameUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Nom d\'utilisateur mis à jour avec succès'**
  String get profileUsernameUpdated;

  /// No description provided for @profileDataRefreshed.
  ///
  /// In fr, this message translates to:
  /// **'Données actualisées'**
  String get profileDataRefreshed;

  /// No description provided for @leaderboardTitle.
  ///
  /// In fr, this message translates to:
  /// **'Classement'**
  String get leaderboardTitle;

  /// No description provided for @leaderboardYourRank.
  ///
  /// In fr, this message translates to:
  /// **'Votre rang'**
  String get leaderboardYourRank;

  /// No description provided for @leaderboardEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun classement disponible'**
  String get leaderboardEmpty;

  /// No description provided for @leaderboardEmptyHint.
  ///
  /// In fr, this message translates to:
  /// **'Commencez à enregistrer pour apparaître dans le classement !'**
  String get leaderboardEmptyHint;

  /// No description provided for @leaderboardYou.
  ///
  /// In fr, this message translates to:
  /// **'Vous'**
  String get leaderboardYou;

  /// No description provided for @settingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settingsTitle;

  /// No description provided for @settingsAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get settingsAccount;

  /// No description provided for @settingsRecording.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement'**
  String get settingsRecording;

  /// No description provided for @settingsApp.
  ///
  /// In fr, this message translates to:
  /// **'Application'**
  String get settingsApp;

  /// No description provided for @settingsPrivacyLegal.
  ///
  /// In fr, this message translates to:
  /// **'Confidentialité et Légal'**
  String get settingsPrivacyLegal;

  /// No description provided for @settingsSupport.
  ///
  /// In fr, this message translates to:
  /// **'Support'**
  String get settingsSupport;

  /// No description provided for @settingsAbout.
  ///
  /// In fr, this message translates to:
  /// **'À propos'**
  String get settingsAbout;

  /// No description provided for @settingsAutoUpload.
  ///
  /// In fr, this message translates to:
  /// **'Upload automatique'**
  String get settingsAutoUpload;

  /// No description provided for @settingsAutoUploadSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer automatiquement les enregistrements'**
  String get settingsAutoUploadSubtitle;

  /// No description provided for @settingsAudioQuality.
  ///
  /// In fr, this message translates to:
  /// **'Qualité audio'**
  String get settingsAudioQuality;

  /// No description provided for @settingsLocalStorage.
  ///
  /// In fr, this message translates to:
  /// **'Stockage local'**
  String get settingsLocalStorage;

  /// No description provided for @settingsLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get settingsLanguage;

  /// No description provided for @settingsTheme.
  ///
  /// In fr, this message translates to:
  /// **'Thème'**
  String get settingsTheme;

  /// No description provided for @settingsReset.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser les paramètres'**
  String get settingsReset;

  /// No description provided for @settingsReviewTutorial.
  ///
  /// In fr, this message translates to:
  /// **'Revoir le tutoriel'**
  String get settingsReviewTutorial;

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In fr, this message translates to:
  /// **'Politique de confidentialité'**
  String get settingsPrivacyPolicy;

  /// No description provided for @settingsTerms.
  ///
  /// In fr, this message translates to:
  /// **'Conditions d\'utilisation'**
  String get settingsTerms;

  /// No description provided for @settingsPermissions.
  ///
  /// In fr, this message translates to:
  /// **'Permissions'**
  String get settingsPermissions;

  /// No description provided for @settingsHelp.
  ///
  /// In fr, this message translates to:
  /// **'Centre d\'aide'**
  String get settingsHelp;

  /// No description provided for @settingsFeedback.
  ///
  /// In fr, this message translates to:
  /// **'Feedback'**
  String get settingsFeedback;

  /// No description provided for @settingsBugReport.
  ///
  /// In fr, this message translates to:
  /// **'Signaler un problème'**
  String get settingsBugReport;

  /// No description provided for @settingsCheckUpdates.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier les mises à jour'**
  String get settingsCheckUpdates;

  /// No description provided for @settingsResetConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir restaurer tous les paramètres par défaut ?'**
  String get settingsResetConfirm;

  /// No description provided for @settingsResetDone.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres réinitialisés'**
  String get settingsResetDone;

  /// No description provided for @settingsCacheCleared.
  ///
  /// In fr, this message translates to:
  /// **'Cache nettoyé'**
  String get settingsCacheCleared;

  /// No description provided for @dialogCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get dialogCancel;

  /// No description provided for @dialogOk.
  ///
  /// In fr, this message translates to:
  /// **'OK'**
  String get dialogOk;

  /// No description provided for @dialogDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get dialogDelete;

  /// No description provided for @dialogLogout.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion'**
  String get dialogLogout;

  /// No description provided for @dialogLogoutConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir vous déconnecter ?'**
  String get dialogLogoutConfirm;

  /// No description provided for @dialogDeleteAccountConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Cette action est irréversible. Toutes vos données seront définitivement supprimées. Êtes-vous sûr de vouloir continuer ?'**
  String get dialogDeleteAccountConfirm;

  /// No description provided for @dialogDeleteRecordingConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir supprimer cet enregistrement ?'**
  String get dialogDeleteRecordingConfirm;

  /// No description provided for @permissionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Configuration des permissions'**
  String get permissionTitle;

  /// No description provided for @permissionSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Xelkoom a besoin de certaines permissions pour fonctionner correctement.'**
  String get permissionSubtitle;

  /// No description provided for @permissionChecking.
  ///
  /// In fr, this message translates to:
  /// **'Vérification des permissions...'**
  String get permissionChecking;

  /// No description provided for @permissionRequired.
  ///
  /// In fr, this message translates to:
  /// **'Permissions nécessaires :'**
  String get permissionRequired;

  /// No description provided for @permissionMicrophone.
  ///
  /// In fr, this message translates to:
  /// **'Microphone'**
  String get permissionMicrophone;

  /// No description provided for @permissionStorage.
  ///
  /// In fr, this message translates to:
  /// **'Stockage'**
  String get permissionStorage;

  /// No description provided for @permissionConfigure.
  ///
  /// In fr, this message translates to:
  /// **'Configurer les permissions'**
  String get permissionConfigure;

  /// No description provided for @permissionSkip.
  ///
  /// In fr, this message translates to:
  /// **'Continuer sans configurer maintenant'**
  String get permissionSkip;

  /// No description provided for @permissionGranted.
  ///
  /// In fr, this message translates to:
  /// **'Accordée'**
  String get permissionGranted;

  /// No description provided for @permissionDenied.
  ///
  /// In fr, this message translates to:
  /// **'Refusée'**
  String get permissionDenied;

  /// No description provided for @validationUsernameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer un nom d\'utilisateur'**
  String get validationUsernameRequired;

  /// No description provided for @validationUsernameMin.
  ///
  /// In fr, this message translates to:
  /// **'Le nom doit contenir au moins 3 caractères'**
  String get validationUsernameMin;

  /// No description provided for @validationPasswordRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer un mot de passe'**
  String get validationPasswordRequired;

  /// No description provided for @validationPasswordMin.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe doit contenir au moins 6 caractères'**
  String get validationPasswordMin;

  /// No description provided for @validationPasswordConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez confirmer votre mot de passe'**
  String get validationPasswordConfirm;

  /// No description provided for @validationPasswordMismatch.
  ///
  /// In fr, this message translates to:
  /// **'Les mots de passe ne correspondent pas'**
  String get validationPasswordMismatch;

  /// No description provided for @validationConsentRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez accepter les conditions d\'utilisation'**
  String get validationConsentRequired;

  /// No description provided for @errorGeneric.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue'**
  String get errorGeneric;

  /// No description provided for @errorNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de connexion au serveur'**
  String get errorNetwork;

  /// No description provided for @errorUnauthorized.
  ///
  /// In fr, this message translates to:
  /// **'Session expirée, veuillez vous reconnecter'**
  String get errorUnauthorized;

  /// No description provided for @errorNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Ressource introuvable'**
  String get errorNotFound;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['fr', 'wo'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'fr': return AppLocalizationsFr();
    case 'wo': return AppLocalizationsWo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
