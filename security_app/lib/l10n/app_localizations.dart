import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_mr.dart';
import 'app_localizations_ta.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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
    Locale('bn'),
    Locale('en'),
    Locale('hi'),
    Locale('mr'),
    Locale('ta')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Security App'**
  String get appTitle;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @customizeExperience.
  ///
  /// In en, this message translates to:
  /// **'Customize your experience'**
  String get customizeExperience;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select your preferred language'**
  String get selectLanguage;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @selectTheme.
  ///
  /// In en, this message translates to:
  /// **'Select your preferred theme'**
  String get selectTheme;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @sound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get sound;

  /// No description provided for @fontSize.
  ///
  /// In en, this message translates to:
  /// **'Font Size'**
  String get fontSize;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Yogini'**
  String get name;

  /// No description provided for @welcomeSecurityApp.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Security App'**
  String get welcomeSecurityApp;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @profilePage.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profilePage;

  /// No description provided for @logoutBtn.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutBtn;

  /// No description provided for @securityUpdates.
  ///
  /// In en, this message translates to:
  /// **'Security Updates'**
  String get securityUpdates;

  /// No description provided for @cctvMonitoring.
  ///
  /// In en, this message translates to:
  /// **'CCTV Monitoring'**
  String get cctvMonitoring;

  /// No description provided for @incidents.
  ///
  /// In en, this message translates to:
  /// **'Incidents'**
  String get incidents;

  /// No description provided for @emergencyContacts.
  ///
  /// In en, this message translates to:
  /// **'Emergency Contacts'**
  String get emergencyContacts;

  /// No description provided for @announcements.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get announcements;

  /// No description provided for @gatePasses.
  ///
  /// In en, this message translates to:
  /// **'Gate Passes'**
  String get gatePasses;

  /// No description provided for @activeVisitors.
  ///
  /// In en, this message translates to:
  /// **'Active Visitors'**
  String get activeVisitors;

  /// No description provided for @noVisitors.
  ///
  /// In en, this message translates to:
  /// **'No visitors currently in the premises'**
  String get noVisitors;

  /// No description provided for @incidentsReported.
  ///
  /// In en, this message translates to:
  /// **'Incidents Reported'**
  String get incidentsReported;

  /// No description provided for @newAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'New Announcement'**
  String get newAnnouncement;

  /// No description provided for @todaysUpdates.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Updates'**
  String get todaysUpdates;

  /// No description provided for @latestSecurityNotices.
  ///
  /// In en, this message translates to:
  /// **'Latest Security Notices'**
  String get latestSecurityNotices;

  /// No description provided for @checkIn.
  ///
  /// In en, this message translates to:
  /// **'Check-In'**
  String get checkIn;

  /// No description provided for @checkOut.
  ///
  /// In en, this message translates to:
  /// **'Check-Out'**
  String get checkOut;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @settingsPage.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsPage;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @parkingDispute.
  ///
  /// In en, this message translates to:
  /// **'Parking dispute'**
  String get parkingDispute;

  /// No description provided for @parkingDisputeDesc.
  ///
  /// In en, this message translates to:
  /// **'Two residents arguing over parking slot.'**
  String get parkingDisputeDesc;

  /// No description provided for @today330pm.
  ///
  /// In en, this message translates to:
  /// **'Today, 3:30 PM'**
  String get today330pm;

  /// No description provided for @unauthorizedEntry.
  ///
  /// In en, this message translates to:
  /// **'Unauthorized Entry'**
  String get unauthorizedEntry;

  /// No description provided for @unauthorizedEntryDesc.
  ///
  /// In en, this message translates to:
  /// **'Visitor tried to enter without approval.'**
  String get unauthorizedEntryDesc;

  /// No description provided for @yesterday645pm.
  ///
  /// In en, this message translates to:
  /// **'Yesterday, 6:45 PM'**
  String get yesterday645pm;

  /// No description provided for @powerOutage.
  ///
  /// In en, this message translates to:
  /// **'Power Outage'**
  String get powerOutage;

  /// No description provided for @powerOutageDesc.
  ///
  /// In en, this message translates to:
  /// **'Reported blackout in Block B.'**
  String get powerOutageDesc;

  /// No description provided for @reportIncident.
  ///
  /// In en, this message translates to:
  /// **'Report Incident'**
  String get reportIncident;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @attachPhoto.
  ///
  /// In en, this message translates to:
  /// **'Attach Photo'**
  String get attachPhoto;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @verifyOTP.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get verifyOTP;

  /// No description provided for @codeSentTo.
  ///
  /// In en, this message translates to:
  /// **'Code sent to +91'**
  String get codeSentTo;

  /// No description provided for @enterVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Enter Verification Code'**
  String get enterVerificationCode;

  /// No description provided for @pleaseEnter6DigitCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter the 6-digit code we sent'**
  String get pleaseEnter6DigitCode;

  /// No description provided for @verifyLogin.
  ///
  /// In en, this message translates to:
  /// **'VERIFY & LOGIN'**
  String get verifyLogin;

  /// No description provided for @resendOTPIn.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP in'**
  String get resendOTPIn;

  /// No description provided for @seconds.
  ///
  /// In en, this message translates to:
  /// **'s'**
  String get seconds;

  /// No description provided for @resendOTP.
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get resendOTP;

  /// No description provided for @changeMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Change Mobile Number'**
  String get changeMobileNumber;

  /// No description provided for @pleaseEnterComplete6DigitOTP.
  ///
  /// In en, this message translates to:
  /// **'Please enter complete 6-digit OTP'**
  String get pleaseEnterComplete6DigitOTP;

  /// No description provided for @invalidOTPTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Invalid OTP. Please try again.'**
  String get invalidOTPTryAgain;

  /// No description provided for @otpSentSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'OTP sent successfully!'**
  String get otpSentSuccessfully;

  /// No description provided for @pendingTasks.
  ///
  /// In en, this message translates to:
  /// **'PENDING TASKS'**
  String get pendingTasks;

  /// No description provided for @tasksRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} tasks remaining'**
  String tasksRemaining(Object count);

  /// No description provided for @searchTasks.
  ///
  /// In en, this message translates to:
  /// **'Search tasks...'**
  String get searchTasks;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @safety.
  ///
  /// In en, this message translates to:
  /// **'Safety'**
  String get safety;

  /// No description provided for @patrol.
  ///
  /// In en, this message translates to:
  /// **'Patrol'**
  String get patrol;

  /// No description provided for @maintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get maintenance;

  /// No description provided for @documentation.
  ///
  /// In en, this message translates to:
  /// **'Documentation'**
  String get documentation;

  /// No description provided for @high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get high;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get low;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @complete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get complete;

  /// No description provided for @allCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'All caught up!'**
  String get allCaughtUp;

  /// No description provided for @noPendingTasksFound.
  ///
  /// In en, this message translates to:
  /// **'No pending tasks found'**
  String get noPendingTasksFound;

  /// No description provided for @addNewTaskFunctionalityComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Add new task functionality coming soon!'**
  String get addNewTaskFunctionalityComingSoon;

  /// No description provided for @tasksRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Tasks refreshed'**
  String get tasksRefreshed;

  /// No description provided for @taskMarkedCompleted.
  ///
  /// In en, this message translates to:
  /// **'marked as completed!'**
  String get taskMarkedCompleted;

  /// No description provided for @gateDutyBlockA.
  ///
  /// In en, this message translates to:
  /// **'Gate Duty - Block A'**
  String get gateDutyBlockA;

  /// No description provided for @gateDutyDescription.
  ///
  /// In en, this message translates to:
  /// **'Monitor visitor entries for Block A from 8 AM to 12 PM.'**
  String get gateDutyDescription;

  /// No description provided for @due12PM.
  ///
  /// In en, this message translates to:
  /// **'Due: 12:00 PM'**
  String get due12PM;

  /// No description provided for @highPriority.
  ///
  /// In en, this message translates to:
  /// **'High Priority'**
  String get highPriority;

  /// No description provided for @checkFireExtinguishers.
  ///
  /// In en, this message translates to:
  /// **'Check Fire Extinguishers'**
  String get checkFireExtinguishers;

  /// No description provided for @checkFireExtinguishersDesc.
  ///
  /// In en, this message translates to:
  /// **'Inspect all extinguishers in Basement and Tower C.'**
  String get checkFireExtinguishersDesc;

  /// No description provided for @due2PM.
  ///
  /// In en, this message translates to:
  /// **'Due: 2:00 PM'**
  String get due2PM;

  /// No description provided for @mediumPriority.
  ///
  /// In en, this message translates to:
  /// **'Medium Priority'**
  String get mediumPriority;

  /// No description provided for @eveningPatrol.
  ///
  /// In en, this message translates to:
  /// **'Evening Patrol'**
  String get eveningPatrol;

  /// No description provided for @eveningPatrolDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete a full round in Blocks A & B.'**
  String get eveningPatrolDesc;

  /// No description provided for @due6PM.
  ///
  /// In en, this message translates to:
  /// **'Due: 6:00 PM'**
  String get due6PM;

  /// No description provided for @lowPriority.
  ///
  /// In en, this message translates to:
  /// **'Low Priority'**
  String get lowPriority;

  /// No description provided for @cctvSystemCheck.
  ///
  /// In en, this message translates to:
  /// **'CCTV System Check'**
  String get cctvSystemCheck;

  /// No description provided for @cctvSystemCheckDesc.
  ///
  /// In en, this message translates to:
  /// **'Verify all cameras are working and clean lenses.'**
  String get cctvSystemCheckDesc;

  /// No description provided for @due4PM.
  ///
  /// In en, this message translates to:
  /// **'Due: 4:00 PM'**
  String get due4PM;

  /// No description provided for @visitorLogUpdate.
  ///
  /// In en, this message translates to:
  /// **'Visitor Log Update'**
  String get visitorLogUpdate;

  /// No description provided for @visitorLogUpdateDesc.
  ///
  /// In en, this message translates to:
  /// **'Update and organize visitor records from past week.'**
  String get visitorLogUpdateDesc;

  /// No description provided for @due5PM.
  ///
  /// In en, this message translates to:
  /// **'Due: 5:00 PM'**
  String get due5PM;

  /// No description provided for @managerJohn.
  ///
  /// In en, this message translates to:
  /// **'Manager John'**
  String get managerJohn;

  /// No description provided for @safetyOfficer.
  ///
  /// In en, this message translates to:
  /// **'Safety Officer'**
  String get safetyOfficer;

  /// No description provided for @securityHead.
  ///
  /// In en, this message translates to:
  /// **'Security Head'**
  String get securityHead;

  /// No description provided for @techSupport.
  ///
  /// In en, this message translates to:
  /// **'Tech Support'**
  String get techSupport;

  /// No description provided for @adminOffice.
  ///
  /// In en, this message translates to:
  /// **'Admin Office'**
  String get adminOffice;

  /// No description provided for @hours4.
  ///
  /// In en, this message translates to:
  /// **'4 hours'**
  String get hours4;

  /// No description provided for @hours2.
  ///
  /// In en, this message translates to:
  /// **'2 hours'**
  String get hours2;

  /// No description provided for @hours1_5.
  ///
  /// In en, this message translates to:
  /// **'1.5 hours'**
  String get hours1_5;

  /// No description provided for @hours3.
  ///
  /// In en, this message translates to:
  /// **'3 hours'**
  String get hours3;

  /// No description provided for @hour1.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get hour1;

  /// No description provided for @blockAGate.
  ///
  /// In en, this message translates to:
  /// **'Block A Gate'**
  String get blockAGate;

  /// No description provided for @basementTowerC.
  ///
  /// In en, this message translates to:
  /// **'Basement & Tower C'**
  String get basementTowerC;

  /// No description provided for @blocksAB.
  ///
  /// In en, this message translates to:
  /// **'Blocks A & B'**
  String get blocksAB;

  /// No description provided for @allBuildings.
  ///
  /// In en, this message translates to:
  /// **'All Buildings'**
  String get allBuildings;

  /// No description provided for @securityOffice.
  ///
  /// In en, this message translates to:
  /// **'Security Office'**
  String get securityOffice;

  /// No description provided for @securityGuard.
  ///
  /// In en, this message translates to:
  /// **'Security Guard'**
  String get securityGuard;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// No description provided for @guardName.
  ///
  /// In en, this message translates to:
  /// **'Guard Name'**
  String get guardName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @guardID.
  ///
  /// In en, this message translates to:
  /// **'Guard ID'**
  String get guardID;

  /// No description provided for @currentShift.
  ///
  /// In en, this message translates to:
  /// **'Current Shift'**
  String get currentShift;

  /// No description provided for @dayShift6AM6PM.
  ///
  /// In en, this message translates to:
  /// **'Day Shift (6 AM - 6 PM)'**
  String get dayShift6AM6PM;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @onDuty.
  ///
  /// In en, this message translates to:
  /// **'On Duty'**
  String get onDuty;

  /// No description provided for @endDutyLogout.
  ///
  /// In en, this message translates to:
  /// **'End Duty & Logout'**
  String get endDutyLogout;

  /// No description provided for @endDutyShift.
  ///
  /// In en, this message translates to:
  /// **'End Duty Shift?'**
  String get endDutyShift;

  /// No description provided for @areYouSureLogout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout and end your current duty shift?'**
  String get areYouSureLogout;

  /// No description provided for @stayOnDuty.
  ///
  /// In en, this message translates to:
  /// **'Stay On Duty'**
  String get stayOnDuty;

  /// No description provided for @errorLoadingProfile.
  ///
  /// In en, this message translates to:
  /// **'Error loading profile'**
  String get errorLoadingProfile;

  /// No description provided for @pleaseTryAgainLater.
  ///
  /// In en, this message translates to:
  /// **'Please try again later'**
  String get pleaseTryAgainLater;

  /// No description provided for @noProfileDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No profile data available'**
  String get noProfileDataAvailable;

  /// No description provided for @noUserDetailsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No user details available'**
  String get noUserDetailsAvailable;

  /// No description provided for @unknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown User'**
  String get unknownUser;

  /// No description provided for @scanQRCode.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get scanQRCode;

  /// No description provided for @startPatrol.
  ///
  /// In en, this message translates to:
  /// **'Start Patrol'**
  String get startPatrol;

  /// No description provided for @patrolStarted.
  ///
  /// In en, this message translates to:
  /// **'Patrol Started:'**
  String get patrolStarted;

  /// No description provided for @patrolNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Patrol not started'**
  String get patrolNotStarted;

  /// No description provided for @areasToPatrol.
  ///
  /// In en, this message translates to:
  /// **'Areas to Patrol:'**
  String get areasToPatrol;

  /// No description provided for @blockA.
  ///
  /// In en, this message translates to:
  /// **'Block A'**
  String get blockA;

  /// No description provided for @blockB.
  ///
  /// In en, this message translates to:
  /// **'Block B'**
  String get blockB;

  /// No description provided for @parkingLot.
  ///
  /// In en, this message translates to:
  /// **'Parking Lot'**
  String get parkingLot;

  /// No description provided for @garden.
  ///
  /// In en, this message translates to:
  /// **'Garden'**
  String get garden;

  /// No description provided for @gymCommunityHall.
  ///
  /// In en, this message translates to:
  /// **'Gym / Community Hall'**
  String get gymCommunityHall;

  /// No description provided for @notStarted.
  ///
  /// In en, this message translates to:
  /// **'Not Started'**
  String get notStarted;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @skipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get skipped;

  /// No description provided for @notesIncidents.
  ///
  /// In en, this message translates to:
  /// **'Notes / Incidents'**
  String get notesIncidents;

  /// No description provided for @startPatrolBtn.
  ///
  /// In en, this message translates to:
  /// **'Start Patrol'**
  String get startPatrolBtn;

  /// No description provided for @endPatrolBtn.
  ///
  /// In en, this message translates to:
  /// **'End Patrol'**
  String get endPatrolBtn;

  /// No description provided for @patrolCompleted.
  ///
  /// In en, this message translates to:
  /// **'Patrol Completed'**
  String get patrolCompleted;

  /// No description provided for @startTime.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get startTime;

  /// No description provided for @endTime.
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get endTime;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @todaysVisitors.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Visitors'**
  String get todaysVisitors;

  /// No description provided for @johnDoe.
  ///
  /// In en, this message translates to:
  /// **'John Doe'**
  String get johnDoe;

  /// No description provided for @priyaSharma.
  ///
  /// In en, this message translates to:
  /// **'Priya Sharma'**
  String get priyaSharma;

  /// No description provided for @rameshKumar.
  ///
  /// In en, this message translates to:
  /// **'Ramesh Kumar'**
  String get rameshKumar;

  /// No description provided for @sarahWilson.
  ///
  /// In en, this message translates to:
  /// **'Sarah Wilson'**
  String get sarahWilson;

  /// No description provided for @flat.
  ///
  /// In en, this message translates to:
  /// **'Flat'**
  String get flat;

  /// No description provided for @inTime.
  ///
  /// In en, this message translates to:
  /// **'In'**
  String get inTime;

  /// No description provided for @outTime.
  ///
  /// In en, this message translates to:
  /// **'Out'**
  String get outTime;

  /// No description provided for @inside.
  ///
  /// In en, this message translates to:
  /// **'Inside'**
  String get inside;

  /// No description provided for @exited.
  ///
  /// In en, this message translates to:
  /// **'Exited'**
  String get exited;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get hindi;

  /// No description provided for @marathi.
  ///
  /// In en, this message translates to:
  /// **'Marathi'**
  String get marathi;

  /// No description provided for @bengali.
  ///
  /// In en, this message translates to:
  /// **'Bengali'**
  String get bengali;

  /// No description provided for @tamil.
  ///
  /// In en, this message translates to:
  /// **'Tamil'**
  String get tamil;

  /// No description provided for @telugu.
  ///
  /// In en, this message translates to:
  /// **'Telugu'**
  String get telugu;

  /// No description provided for @urdu.
  ///
  /// In en, this message translates to:
  /// **'Urdu'**
  String get urdu;

  /// No description provided for @visitorEntry.
  ///
  /// In en, this message translates to:
  /// **'VISITOR ENTRY'**
  String get visitorEntry;

  /// No description provided for @registerNewVisitor.
  ///
  /// In en, this message translates to:
  /// **'Register New Visitor'**
  String get registerNewVisitor;

  /// No description provided for @qrOTP.
  ///
  /// In en, this message translates to:
  /// **'QR / OTP'**
  String get qrOTP;

  /// No description provided for @manual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get manual;

  /// No description provided for @quickEntry.
  ///
  /// In en, this message translates to:
  /// **'Quick Entry'**
  String get quickEntry;

  /// No description provided for @enterOTPCode.
  ///
  /// In en, this message translates to:
  /// **'Enter OTP Code'**
  String get enterOTPCode;

  /// No description provided for @enter6DigitOTPFromResident.
  ///
  /// In en, this message translates to:
  /// **'Enter 6-digit OTP from resident'**
  String get enter6DigitOTPFromResident;

  /// No description provided for @scanQRCodeBtn.
  ///
  /// In en, this message translates to:
  /// **'SCAN QR CODE'**
  String get scanQRCodeBtn;

  /// No description provided for @visitorInformation.
  ///
  /// In en, this message translates to:
  /// **'Visitor Information'**
  String get visitorInformation;

  /// No description provided for @visitorName.
  ///
  /// In en, this message translates to:
  /// **'Visitor Name'**
  String get visitorName;

  /// No description provided for @autoFilledFromQRScan.
  ///
  /// In en, this message translates to:
  /// **'Auto-filled from QR scan'**
  String get autoFilledFromQRScan;

  /// No description provided for @flatNumber.
  ///
  /// In en, this message translates to:
  /// **'Flat Number'**
  String get flatNumber;

  /// No description provided for @enterFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter full name'**
  String get enterFullName;

  /// No description provided for @phoneNumberHint.
  ///
  /// In en, this message translates to:
  /// **'10-digit number'**
  String get phoneNumberHint;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @flatNumberRequired.
  ///
  /// In en, this message translates to:
  /// **'Flat number required'**
  String get flatNumberRequired;

  /// No description provided for @phoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone required'**
  String get phoneRequired;

  /// No description provided for @invalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone'**
  String get invalidPhone;

  /// No description provided for @visitorPhoto.
  ///
  /// In en, this message translates to:
  /// **'Visitor Photo'**
  String get visitorPhoto;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @tapToCaptureVisitorPhoto.
  ///
  /// In en, this message translates to:
  /// **'Tap to capture visitor photo'**
  String get tapToCaptureVisitorPhoto;

  /// No description provided for @recommendedForSecurity.
  ///
  /// In en, this message translates to:
  /// **'Recommended for security'**
  String get recommendedForSecurity;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @visitorIn.
  ///
  /// In en, this message translates to:
  /// **'Visitor In'**
  String get visitorIn;

  /// No description provided for @pleaseEnterOTPOrScanQR.
  ///
  /// In en, this message translates to:
  /// **'Please enter OTP or scan QR code first'**
  String get pleaseEnterOTPOrScanQR;

  /// No description provided for @visitorEntryRecordedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Visitor entry recorded successfully!'**
  String get visitorEntryRecordedSuccessfully;

  /// No description provided for @visitorExit.
  ///
  /// In en, this message translates to:
  /// **'VISITOR EXIT'**
  String get visitorExit;

  /// No description provided for @processDepartures.
  ///
  /// In en, this message translates to:
  /// **'Process departures'**
  String get processDepartures;

  /// No description provided for @currentVisitors.
  ///
  /// In en, this message translates to:
  /// **'Current Visitors'**
  String get currentVisitors;

  /// No description provided for @pendingExits.
  ///
  /// In en, this message translates to:
  /// **'Pending Exits'**
  String get pendingExits;

  /// No description provided for @searchVisitorsByNameFlat.
  ///
  /// In en, this message translates to:
  /// **'Search visitors by name, flat, or phone...'**
  String get searchVisitorsByNameFlat;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'EXIT'**
  String get exit;

  /// No description provided for @entryTime.
  ///
  /// In en, this message translates to:
  /// **'Entry'**
  String get entryTime;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @familyVisit.
  ///
  /// In en, this message translates to:
  /// **'Family Visit'**
  String get familyVisit;

  /// No description provided for @delivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get delivery;

  /// No description provided for @serviceVisit.
  ///
  /// In en, this message translates to:
  /// **'Service Visit'**
  String get serviceVisit;

  /// No description provided for @friendVisit.
  ///
  /// In en, this message translates to:
  /// **'Friend Visit'**
  String get friendVisit;

  /// No description provided for @mrsSharma.
  ///
  /// In en, this message translates to:
  /// **'Mrs. Sharma'**
  String get mrsSharma;

  /// No description provided for @mrPatel.
  ///
  /// In en, this message translates to:
  /// **'Mr. Patel'**
  String get mrPatel;

  /// No description provided for @msGupta.
  ///
  /// In en, this message translates to:
  /// **'Ms. Gupta'**
  String get msGupta;

  /// No description provided for @johnSmith.
  ///
  /// In en, this message translates to:
  /// **'John Smith'**
  String get johnSmith;

  /// No description provided for @successfullyMarkedAsExited.
  ///
  /// In en, this message translates to:
  /// **'successfully marked as EXITED'**
  String get successfullyMarkedAsExited;

  /// No description provided for @bulkExit.
  ///
  /// In en, this message translates to:
  /// **'Bulk Exit'**
  String get bulkExit;

  /// No description provided for @markAllVisitorsAsExited.
  ///
  /// In en, this message translates to:
  /// **'Mark all current visitors as exited? This action cannot be undone.'**
  String get markAllVisitorsAsExited;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @exitAll.
  ///
  /// In en, this message translates to:
  /// **'Exit All'**
  String get exitAll;

  /// No description provided for @visitorsMarkedAsExited.
  ///
  /// In en, this message translates to:
  /// **'visitors marked as exited'**
  String get visitorsMarkedAsExited;

  /// No description provided for @noVisitorsCurrentlyInPremises.
  ///
  /// In en, this message translates to:
  /// **'No visitors currently in the premises'**
  String get noVisitorsCurrentlyInPremises;

  /// No description provided for @noVisitorsFoundMatchingSearch.
  ///
  /// In en, this message translates to:
  /// **'No visitors found matching your search'**
  String get noVisitorsFoundMatchingSearch;

  /// No description provided for @visitors.
  ///
  /// In en, this message translates to:
  /// **'Visitors'**
  String get visitors;

  /// No description provided for @visitorPage.
  ///
  /// In en, this message translates to:
  /// **'Visitor Page'**
  String get visitorPage;

  /// No description provided for @visitorEntriesWillBeManaged.
  ///
  /// In en, this message translates to:
  /// **'This is where visitor entries will be managed.'**
  String get visitorEntriesWillBeManaged;

  /// No description provided for @confirmLogoutMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get confirmLogoutMessage;

  /// No description provided for @dayShiftTime.
  ///
  /// In en, this message translates to:
  /// **'Day Shift (6 AM - 6 PM)'**
  String get dayShiftTime;

  /// No description provided for @guardId.
  ///
  /// In en, this message translates to:
  /// **'Guard ID'**
  String get guardId;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @securityCommandCenter.
  ///
  /// In en, this message translates to:
  /// **'Security Command Center'**
  String get securityCommandCenter;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @criticalAlerts.
  ///
  /// In en, this message translates to:
  /// **'Critical Alerts'**
  String get criticalAlerts;

  /// No description provided for @requiresImmediateAttention.
  ///
  /// In en, this message translates to:
  /// **'Requires Immediate Attention'**
  String get requiresImmediateAttention;

  /// No description provided for @incidentsToday.
  ///
  /// In en, this message translates to:
  /// **'Incidents Today'**
  String get incidentsToday;

  /// No description provided for @monitorAndResolve.
  ///
  /// In en, this message translates to:
  /// **'Monitor and Resolve'**
  String get monitorAndResolve;

  /// No description provided for @todaysOverview.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Overview'**
  String get todaysOverview;

  /// No description provided for @primaryActions.
  ///
  /// In en, this message translates to:
  /// **'Primary Actions'**
  String get primaryActions;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @residents.
  ///
  /// In en, this message translates to:
  /// **'Residents'**
  String get residents;

  /// No description provided for @recentActivities.
  ///
  /// In en, this message translates to:
  /// **'Recent Activities'**
  String get recentActivities;

  /// No description provided for @visitorEntryLogged.
  ///
  /// In en, this message translates to:
  /// **'Visitor entry logged'**
  String get visitorEntryLogged;

  /// No description provided for @flat301JohnDoe.
  ///
  /// In en, this message translates to:
  /// **'Flat 301 - John Doe'**
  String get flat301JohnDoe;

  /// No description provided for @blockAAllClear.
  ///
  /// In en, this message translates to:
  /// **'Block A - All Clear'**
  String get blockAAllClear;

  /// No description provided for @incidentReported.
  ///
  /// In en, this message translates to:
  /// **'Incident Reported'**
  String get incidentReported;

  /// No description provided for @parkingDisputeResolved.
  ///
  /// In en, this message translates to:
  /// **'Parking dispute resolved'**
  String get parkingDisputeResolved;

  /// No description provided for @selectEntryType.
  ///
  /// In en, this message translates to:
  /// **'Select Entry Type'**
  String get selectEntryType;

  /// No description provided for @emergencyAlert.
  ///
  /// In en, this message translates to:
  /// **'Emergency Alert'**
  String get emergencyAlert;

  /// No description provided for @emergencyAlertDescription.
  ///
  /// In en, this message translates to:
  /// **'Notify all residents immediately about an emergency'**
  String get emergencyAlertDescription;

  /// No description provided for @emergencyAlertSent.
  ///
  /// In en, this message translates to:
  /// **'Emergency alert sent successfully!'**
  String get emergencyAlertSent;

  /// No description provided for @sendAlert.
  ///
  /// In en, this message translates to:
  /// **'Send Alert'**
  String get sendAlert;

  /// No description provided for @visitorsLogged.
  ///
  /// In en, this message translates to:
  /// **'Visitors Logged'**
  String get visitorsLogged;

  /// No description provided for @visitorsLoggedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Total visitors logged today'**
  String get visitorsLoggedSubtitle;

  /// No description provided for @incidentsReportedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Total incidents reported today'**
  String get incidentsReportedSubtitle;

  /// No description provided for @patrolsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Patrols Completed'**
  String get patrolsCompleted;

  /// No description provided for @patrolsCompletedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Total patrols completed today'**
  String get patrolsCompletedSubtitle;

  /// No description provided for @parkingDisputeTitle.
  ///
  /// In en, this message translates to:
  /// **'Parking dispute'**
  String get parkingDisputeTitle;

  /// No description provided for @parkingDisputeDescription.
  ///
  /// In en, this message translates to:
  /// **'Two residents arguing over parking slot.'**
  String get parkingDisputeDescription;

  /// No description provided for @unauthorizedEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Unauthorized Entry'**
  String get unauthorizedEntryTitle;

  /// No description provided for @unauthorizedEntryDescription.
  ///
  /// In en, this message translates to:
  /// **'Visitor tried to enter without approval.'**
  String get unauthorizedEntryDescription;

  /// No description provided for @powerOutageTitle.
  ///
  /// In en, this message translates to:
  /// **'Power Outage'**
  String get powerOutageTitle;

  /// No description provided for @powerOutageDescription.
  ///
  /// In en, this message translates to:
  /// **'Reported blackout in Block B.'**
  String get powerOutageDescription;

  /// No description provided for @todayTime.
  ///
  /// In en, this message translates to:
  /// **'Today, {time}'**
  String todayTime(Object time);

  /// No description provided for @yesterdayTime.
  ///
  /// In en, this message translates to:
  /// **'Yesterday, {time}'**
  String yesterdayTime(Object time);

  /// No description provided for @isImageOkay.
  ///
  /// In en, this message translates to:
  /// **'Is this image okay?'**
  String get isImageOkay;

  /// No description provided for @retake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get retake;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @reportIncidentTitle.
  ///
  /// In en, this message translates to:
  /// **'🚨 Report Incident'**
  String get reportIncidentTitle;

  /// No description provided for @incidentTitle.
  ///
  /// In en, this message translates to:
  /// **'Incident Title'**
  String get incidentTitle;

  /// No description provided for @captureImage.
  ///
  /// In en, this message translates to:
  /// **'Capture Image'**
  String get captureImage;

  /// No description provided for @removeImage.
  ///
  /// In en, this message translates to:
  /// **'Remove Image'**
  String get removeImage;

  /// No description provided for @pleaseFillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all fields'**
  String get pleaseFillAllFields;

  /// No description provided for @incidentReportedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Incident reported successfully!'**
  String get incidentReportedSuccessfully;

  /// No description provided for @deleteIncident.
  ///
  /// In en, this message translates to:
  /// **'Delete Incident'**
  String get deleteIncident;

  /// No description provided for @deleteIncidentConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this incident?'**
  String get deleteIncidentConfirmation;

  /// No description provided for @incidentDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Incident deleted successfully!'**
  String get incidentDeletedSuccessfully;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @noIncidentsReported.
  ///
  /// In en, this message translates to:
  /// **'No incidents reported yet'**
  String get noIncidentsReported;

  /// No description provided for @incidentDeleted.
  ///
  /// In en, this message translates to:
  /// **'Incident deleted'**
  String get incidentDeleted;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get confirmDelete;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @securityTitle.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get securityTitle;

  /// No description provided for @guardTitle.
  ///
  /// In en, this message translates to:
  /// **'Guard'**
  String get guardTitle;

  /// No description provided for @societyManagementSystem.
  ///
  /// In en, this message translates to:
  /// **'Society Management System'**
  String get societyManagementSystem;

  /// No description provided for @enterMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter Mobile Number'**
  String get enterMobileNumber;

  /// No description provided for @verificationCodeMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter the verification code sent to your number'**
  String get verificationCodeMessage;

  /// No description provided for @mobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get mobileNumber;

  /// No description provided for @mobileNumberHint.
  ///
  /// In en, this message translates to:
  /// **'10-digit mobile number'**
  String get mobileNumberHint;

  /// No description provided for @mobileNumberRequired.
  ///
  /// In en, this message translates to:
  /// **'Mobile number is required'**
  String get mobileNumberRequired;

  /// No description provided for @validMobileNumberError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid mobile number'**
  String get validMobileNumberError;

  /// No description provided for @mobileNumberDigitsOnly.
  ///
  /// In en, this message translates to:
  /// **'Mobile number must contain digits only'**
  String get mobileNumberDigitsOnly;

  /// No description provided for @sendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOtp;

  /// No description provided for @smsVerificationAgreement.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to receive SMS for verification'**
  String get smsVerificationAgreement;

  /// No description provided for @countryCode.
  ///
  /// In en, this message translates to:
  /// **'Country Code'**
  String get countryCode;

  /// No description provided for @errorMessage.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorMessage;

  /// No description provided for @noUserFoundError.
  ///
  /// In en, this message translates to:
  /// **'No user found with this number'**
  String get noUserFoundError;

  /// No description provided for @validMobileNumberPlease.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid mobile number'**
  String get validMobileNumberPlease;

  /// No description provided for @pendingTasksTitle.
  ///
  /// In en, this message translates to:
  /// **'PENDING TASKS'**
  String get pendingTasksTitle;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @assignedBy.
  ///
  /// In en, this message translates to:
  /// **'Assigned by'**
  String get assignedBy;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @taskCompletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Task \"{title}\" marked as completed!'**
  String taskCompletedMessage(Object title);

  /// No description provided for @addNewTaskComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Add new task functionality coming soon!'**
  String get addNewTaskComingSoon;

  /// No description provided for @dueTime.
  ///
  /// In en, this message translates to:
  /// **'Due: {time}'**
  String dueTime(Object time);

  /// No description provided for @fourHours.
  ///
  /// In en, this message translates to:
  /// **'4 hours'**
  String get fourHours;

  /// No description provided for @checkFireExtinguishersDescription.
  ///
  /// In en, this message translates to:
  /// **'Inspect all extinguishers in Basement and Tower C.'**
  String get checkFireExtinguishersDescription;

  /// No description provided for @twoHours.
  ///
  /// In en, this message translates to:
  /// **'2 hours'**
  String get twoHours;

  /// No description provided for @eveningPatrolDescription.
  ///
  /// In en, this message translates to:
  /// **'Complete a full round in Blocks A & B.'**
  String get eveningPatrolDescription;

  /// No description provided for @oneAndHalfHours.
  ///
  /// In en, this message translates to:
  /// **'1.5 hours'**
  String get oneAndHalfHours;

  /// No description provided for @cctvSystemCheckDescription.
  ///
  /// In en, this message translates to:
  /// **'Verify all cameras are working and clean lenses.'**
  String get cctvSystemCheckDescription;

  /// No description provided for @threeHours.
  ///
  /// In en, this message translates to:
  /// **'3 hours'**
  String get threeHours;

  /// No description provided for @visitorLogUpdateDescription.
  ///
  /// In en, this message translates to:
  /// **'Update and organize visitor records from past week.'**
  String get visitorLogUpdateDescription;

  /// No description provided for @oneHour.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get oneHour;

  /// No description provided for @noVisitorsToday.
  ///
  /// In en, this message translates to:
  /// **'No visitors today'**
  String get noVisitorsToday;

  /// No description provided for @totalVisitors.
  ///
  /// In en, this message translates to:
  /// **'Total\nVisitors'**
  String get totalVisitors;

  /// No description provided for @currentlyInside.
  ///
  /// In en, this message translates to:
  /// **'Currently\nInside'**
  String get currentlyInside;

  /// No description provided for @totalExited.
  ///
  /// In en, this message translates to:
  /// **'Total\nExited'**
  String get totalExited;

  /// No description provided for @visitorEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Visitor Entry'**
  String get visitorEntryTitle;

  /// No description provided for @qrOtpTab.
  ///
  /// In en, this message translates to:
  /// **'QR / OTP'**
  String get qrOtpTab;

  /// No description provided for @manualTab.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get manualTab;

  /// No description provided for @otpLabel.
  ///
  /// In en, this message translates to:
  /// **'Enter OTP Code'**
  String get otpLabel;

  /// No description provided for @otpHint.
  ///
  /// In en, this message translates to:
  /// **'Enter 6-digit OTP from resident'**
  String get otpHint;

  /// No description provided for @visitorNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Visitor Name'**
  String get visitorNameLabel;

  /// No description provided for @visitorNameHint.
  ///
  /// In en, this message translates to:
  /// **'Auto-filled from QR scan'**
  String get visitorNameHint;

  /// No description provided for @visitorNameManualHint.
  ///
  /// In en, this message translates to:
  /// **'Enter full name'**
  String get visitorNameManualHint;

  /// No description provided for @flatNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Flat Number'**
  String get flatNumberLabel;

  /// No description provided for @flatNumberHint.
  ///
  /// In en, this message translates to:
  /// **'Auto-filled from QR scan'**
  String get flatNumberHint;

  /// No description provided for @flatNumberManualHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., A-101'**
  String get flatNumberManualHint;

  /// No description provided for @phoneNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumberLabel;

  /// No description provided for @capturePhoto.
  ///
  /// In en, this message translates to:
  /// **'Tap to capture visitor photo'**
  String get capturePhoto;

  /// No description provided for @photoRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended for security'**
  String get photoRecommended;

  /// No description provided for @otpRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please enter OTP or scan QR code first'**
  String get otpRequiredError;

  /// No description provided for @visitorEntrySuccess.
  ///
  /// In en, this message translates to:
  /// **'Visitor entry recorded successfully!'**
  String get visitorEntrySuccess;

  /// No description provided for @nameRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequiredError;

  /// No description provided for @flatRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Flat number required'**
  String get flatRequiredError;

  /// No description provided for @phoneRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Phone required'**
  String get phoneRequiredError;

  /// No description provided for @phoneInvalidError.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone'**
  String get phoneInvalidError;

  /// No description provided for @scanQrCode.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get scanQrCode;

  /// No description provided for @visitorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Visitors'**
  String get visitorsTitle;

  /// No description provided for @visitorPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Visitor Page'**
  String get visitorPageTitle;

  /// No description provided for @visitorPageDescription.
  ///
  /// In en, this message translates to:
  /// **'This is where visitor entries will be managed.'**
  String get visitorPageDescription;

  /// No description provided for @visitorExitTitle.
  ///
  /// In en, this message translates to:
  /// **'Visitor Exit'**
  String get visitorExitTitle;

  /// No description provided for @searchVisitorsHint.
  ///
  /// In en, this message translates to:
  /// **'Search visitors by name, flat, or phone...'**
  String get searchVisitorsHint;

  /// No description provided for @allClear.
  ///
  /// In en, this message translates to:
  /// **'All Clear!'**
  String get allClear;

  /// No description provided for @noVisitorsFound.
  ///
  /// In en, this message translates to:
  /// **'No visitors found matching your search'**
  String get noVisitorsFound;

  /// No description provided for @flatLabel.
  ///
  /// In en, this message translates to:
  /// **'Flat {flat}'**
  String flatLabel(Object flat);

  /// No description provided for @entryTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Entry: {time}'**
  String entryTimeLabel(Object time);

  /// No description provided for @durationLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration: {duration}'**
  String durationLabel(Object duration);

  /// No description provided for @exitButton.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exitButton;

  /// No description provided for @visitorExitSuccess.
  ///
  /// In en, this message translates to:
  /// **'{name} successfully marked as exited'**
  String visitorExitSuccess(Object name);

  /// No description provided for @bulkExitTitle.
  ///
  /// In en, this message translates to:
  /// **'Bulk Exit'**
  String get bulkExitTitle;

  /// No description provided for @bulkExitMessage.
  ///
  /// In en, this message translates to:
  /// **'Mark all current visitors as exited? This action cannot be undone.'**
  String get bulkExitMessage;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @exitAllButton.
  ///
  /// In en, this message translates to:
  /// **'Exit All'**
  String get exitAllButton;

  /// No description provided for @bulkExitSuccess.
  ///
  /// In en, this message translates to:
  /// **'{count} visitors marked as exited'**
  String bulkExitSuccess(Object count);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['bn', 'en', 'hi', 'mr', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn': return AppLocalizationsBn();
    case 'en': return AppLocalizationsEn();
    case 'hi': return AppLocalizationsHi();
    case 'mr': return AppLocalizationsMr();
    case 'ta': return AppLocalizationsTa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
