// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Security App';

  @override
  String get settings => 'Settings';

  @override
  String get customizeExperience => 'Customize your experience';

  @override
  String get preferences => 'Preferences';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select your preferred language';

  @override
  String get theme => 'Theme';

  @override
  String get selectTheme => 'Select your preferred theme';

  @override
  String get notifications => 'Notifications';

  @override
  String get sound => 'Sound';

  @override
  String get fontSize => 'Font Size';

  @override
  String get about => 'About';

  @override
  String get support => 'Support';

  @override
  String get logout => 'Logout';

  @override
  String get login => 'Login';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get welcome => 'Welcome';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get profile => 'Profile';

  @override
  String get name => 'Yogini';

  @override
  String get welcomeSecurityApp => 'Welcome to Security App';

  @override
  String get home => 'Home';

  @override
  String get profilePage => 'Profile';

  @override
  String get logoutBtn => 'Logout';

  @override
  String get securityUpdates => 'Security Updates';

  @override
  String get cctvMonitoring => 'CCTV Monitoring';

  @override
  String get incidents => 'Incidents';

  @override
  String get emergencyContacts => 'Emergency Contacts';

  @override
  String get announcements => 'Announcements';

  @override
  String get gatePasses => 'Gate Passes';

  @override
  String get activeVisitors => 'Active Visitors';

  @override
  String get noVisitors => 'No visitors currently in the premises';

  @override
  String get incidentsReported => 'Incidents Reported';

  @override
  String get newAnnouncement => 'New Announcement';

  @override
  String get todaysUpdates => 'Today\'s Updates';

  @override
  String get latestSecurityNotices => 'Latest Security Notices';

  @override
  String get checkIn => 'Check-In';

  @override
  String get checkOut => 'Check-Out';

  @override
  String get search => 'Search';

  @override
  String get settingsPage => 'Settings';

  @override
  String get viewAll => 'View All';

  @override
  String get parkingDispute => 'Parking dispute';

  @override
  String get parkingDisputeDesc => 'Two residents arguing over parking slot.';

  @override
  String get today330pm => 'Today, 3:30 PM';

  @override
  String get unauthorizedEntry => 'Unauthorized Entry';

  @override
  String get unauthorizedEntryDesc => 'Visitor tried to enter without approval.';

  @override
  String get yesterday645pm => 'Yesterday, 6:45 PM';

  @override
  String get powerOutage => 'Power Outage';

  @override
  String get powerOutageDesc => 'Reported blackout in Block B.';

  @override
  String get reportIncident => 'Report Incident';

  @override
  String get title => 'Title';

  @override
  String get description => 'Description';

  @override
  String get attachPhoto => 'Attach Photo';

  @override
  String get submit => 'Submit';

  @override
  String get verifyOTP => 'Verify OTP';

  @override
  String get codeSentTo => 'Code sent to +91';

  @override
  String get enterVerificationCode => 'Enter Verification Code';

  @override
  String get pleaseEnter6DigitCode => 'Please enter the 6-digit code we sent';

  @override
  String get verifyLogin => 'VERIFY & LOGIN';

  @override
  String get resendOTPIn => 'Resend OTP in';

  @override
  String get seconds => 's';

  @override
  String get resendOTP => 'Resend OTP';

  @override
  String get changeMobileNumber => 'Change Mobile Number';

  @override
  String get pleaseEnterComplete6DigitOTP => 'Please enter complete 6-digit OTP';

  @override
  String get invalidOTPTryAgain => 'Invalid OTP. Please try again.';

  @override
  String get otpSentSuccessfully => 'OTP sent successfully!';

  @override
  String get pendingTasks => 'PENDING TASKS';

  @override
  String tasksRemaining(Object count) {
    return '$count tasks remaining';
  }

  @override
  String get searchTasks => 'Search tasks...';

  @override
  String get all => 'All';

  @override
  String get security => 'Security';

  @override
  String get safety => 'Safety';

  @override
  String get patrol => 'Patrol';

  @override
  String get maintenance => 'Maintenance';

  @override
  String get documentation => 'Documentation';

  @override
  String get high => 'High';

  @override
  String get medium => 'Medium';

  @override
  String get low => 'Low';

  @override
  String get done => 'Done';

  @override
  String get progress => 'Progress';

  @override
  String get details => 'Details';

  @override
  String get complete => 'Complete';

  @override
  String get allCaughtUp => 'All caught up!';

  @override
  String get noPendingTasksFound => 'No pending tasks found';

  @override
  String get addNewTaskFunctionalityComingSoon => 'Add new task functionality coming soon!';

  @override
  String get tasksRefreshed => 'Tasks refreshed';

  @override
  String get taskMarkedCompleted => 'marked as completed!';

  @override
  String get gateDutyBlockA => 'Gate Duty - Block A';

  @override
  String get gateDutyDescription => 'Monitor visitor entries for Block A from 8 AM to 12 PM.';

  @override
  String get due12PM => 'Due: 12:00 PM';

  @override
  String get highPriority => 'High Priority';

  @override
  String get checkFireExtinguishers => 'Check Fire Extinguishers';

  @override
  String get checkFireExtinguishersDesc => 'Inspect all extinguishers in Basement and Tower C.';

  @override
  String get due2PM => 'Due: 2:00 PM';

  @override
  String get mediumPriority => 'Medium Priority';

  @override
  String get eveningPatrol => 'Evening Patrol';

  @override
  String get eveningPatrolDesc => 'Complete a full round in Blocks A & B.';

  @override
  String get due6PM => 'Due: 6:00 PM';

  @override
  String get lowPriority => 'Low Priority';

  @override
  String get cctvSystemCheck => 'CCTV System Check';

  @override
  String get cctvSystemCheckDesc => 'Verify all cameras are working and clean lenses.';

  @override
  String get due4PM => 'Due: 4:00 PM';

  @override
  String get visitorLogUpdate => 'Visitor Log Update';

  @override
  String get visitorLogUpdateDesc => 'Update and organize visitor records from past week.';

  @override
  String get due5PM => 'Due: 5:00 PM';

  @override
  String get managerJohn => 'Manager John';

  @override
  String get safetyOfficer => 'Safety Officer';

  @override
  String get securityHead => 'Security Head';

  @override
  String get techSupport => 'Tech Support';

  @override
  String get adminOffice => 'Admin Office';

  @override
  String get hours4 => '4 hours';

  @override
  String get hours2 => '2 hours';

  @override
  String get hours1_5 => '1.5 hours';

  @override
  String get hours3 => '3 hours';

  @override
  String get hour1 => '1 hour';

  @override
  String get blockAGate => 'Block A Gate';

  @override
  String get basementTowerC => 'Basement & Tower C';

  @override
  String get blocksAB => 'Blocks A & B';

  @override
  String get allBuildings => 'All Buildings';

  @override
  String get securityOffice => 'Security Office';

  @override
  String get securityGuard => 'Security Guard';

  @override
  String get personalInformation => 'Personal Information';

  @override
  String get guardName => 'Guard Name';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get guardID => 'Guard ID';

  @override
  String get currentShift => 'Current Shift';

  @override
  String get dayShift6AM6PM => 'Day Shift (6 AM - 6 PM)';

  @override
  String get status => 'Status';

  @override
  String get onDuty => 'On Duty';

  @override
  String get endDutyLogout => 'End Duty & Logout';

  @override
  String get endDutyShift => 'End Duty Shift?';

  @override
  String get areYouSureLogout => 'Are you sure you want to logout and end your current duty shift?';

  @override
  String get stayOnDuty => 'Stay On Duty';

  @override
  String get errorLoadingProfile => 'Error loading profile';

  @override
  String get pleaseTryAgainLater => 'Please try again later';

  @override
  String get noProfileDataAvailable => 'No profile data available';

  @override
  String get noUserDetailsAvailable => 'No user details available';

  @override
  String get unknownUser => 'Unknown User';

  @override
  String get scanQRCode => 'Scan QR Code';

  @override
  String get startPatrol => 'Start Patrol';

  @override
  String get patrolStarted => 'Patrol Started:';

  @override
  String get patrolNotStarted => 'Patrol not started';

  @override
  String get areasToPatrol => 'Areas to Patrol:';

  @override
  String get blockA => 'Block A';

  @override
  String get blockB => 'Block B';

  @override
  String get parkingLot => 'Parking Lot';

  @override
  String get garden => 'Garden';

  @override
  String get gymCommunityHall => 'Gym / Community Hall';

  @override
  String get notStarted => 'Not Started';

  @override
  String get inProgress => 'In Progress';

  @override
  String get completed => 'Completed';

  @override
  String get skipped => 'Skipped';

  @override
  String get notesIncidents => 'Notes / Incidents';

  @override
  String get startPatrolBtn => 'Start Patrol';

  @override
  String get endPatrolBtn => 'End Patrol';

  @override
  String get patrolCompleted => 'Patrol Completed';

  @override
  String get startTime => 'Start Time';

  @override
  String get endTime => 'End Time';

  @override
  String get notes => 'Notes';

  @override
  String get none => 'None';

  @override
  String get ok => 'OK';

  @override
  String get todaysVisitors => 'Today\'s Visitors';

  @override
  String get johnDoe => 'John Doe';

  @override
  String get priyaSharma => 'Priya Sharma';

  @override
  String get rameshKumar => 'Ramesh Kumar';

  @override
  String get sarahWilson => 'Sarah Wilson';

  @override
  String get flat => 'Flat';

  @override
  String get inTime => 'In';

  @override
  String get outTime => 'Out';

  @override
  String get inside => 'Inside';

  @override
  String get exited => 'Exited';

  @override
  String get english => 'English';

  @override
  String get hindi => 'Hindi';

  @override
  String get marathi => 'Marathi';

  @override
  String get bengali => 'Bengali';

  @override
  String get tamil => 'Tamil';

  @override
  String get telugu => 'Telugu';

  @override
  String get urdu => 'Urdu';

  @override
  String get visitorEntry => 'VISITOR ENTRY';

  @override
  String get registerNewVisitor => 'Register New Visitor';

  @override
  String get qrOTP => 'QR / OTP';

  @override
  String get manual => 'Manual';

  @override
  String get quickEntry => 'Quick Entry';

  @override
  String get enterOTPCode => 'Enter OTP Code';

  @override
  String get enter6DigitOTPFromResident => 'Enter 6-digit OTP from resident';

  @override
  String get scanQRCodeBtn => 'SCAN QR CODE';

  @override
  String get visitorInformation => 'Visitor Information';

  @override
  String get visitorName => 'Visitor Name';

  @override
  String get autoFilledFromQRScan => 'Auto-filled from QR scan';

  @override
  String get flatNumber => 'Flat Number';

  @override
  String get enterFullName => 'Enter full name';

  @override
  String get phoneNumberHint => '10-digit number';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get flatNumberRequired => 'Flat number required';

  @override
  String get phoneRequired => 'Phone required';

  @override
  String get invalidPhone => 'Invalid phone';

  @override
  String get visitorPhoto => 'Visitor Photo';

  @override
  String get optional => 'Optional';

  @override
  String get tapToCaptureVisitorPhoto => 'Tap to capture visitor photo';

  @override
  String get recommendedForSecurity => 'Recommended for security';

  @override
  String get processing => 'Processing...';

  @override
  String get visitorIn => 'Visitor In';

  @override
  String get pleaseEnterOTPOrScanQR => 'Please enter OTP or scan QR code first';

  @override
  String get visitorEntryRecordedSuccessfully => 'Visitor entry recorded successfully!';

  @override
  String get visitorExit => 'VISITOR EXIT';

  @override
  String get processDepartures => 'Process departures';

  @override
  String get currentVisitors => 'Current Visitors';

  @override
  String get pendingExits => 'Pending Exits';

  @override
  String get searchVisitorsByNameFlat => 'Search visitors by name, flat, or phone...';

  @override
  String get exit => 'EXIT';

  @override
  String get entryTime => 'Entry';

  @override
  String get duration => 'Duration';

  @override
  String get familyVisit => 'Family Visit';

  @override
  String get delivery => 'Delivery';

  @override
  String get serviceVisit => 'Service Visit';

  @override
  String get friendVisit => 'Friend Visit';

  @override
  String get mrsSharma => 'Mrs. Sharma';

  @override
  String get mrPatel => 'Mr. Patel';

  @override
  String get msGupta => 'Ms. Gupta';

  @override
  String get johnSmith => 'John Smith';

  @override
  String get successfullyMarkedAsExited => 'successfully marked as EXITED';

  @override
  String get bulkExit => 'Bulk Exit';

  @override
  String get markAllVisitorsAsExited => 'Mark all current visitors as exited? This action cannot be undone.';

  @override
  String get cancel => 'Cancel';

  @override
  String get exitAll => 'Exit All';

  @override
  String get visitorsMarkedAsExited => 'visitors marked as exited';

  @override
  String get noVisitorsCurrentlyInPremises => 'No visitors currently in the premises';

  @override
  String get noVisitorsFoundMatchingSearch => 'No visitors found matching your search';

  @override
  String get visitors => 'Visitors';

  @override
  String get visitorPage => 'Visitor Page';

  @override
  String get visitorEntriesWillBeManaged => 'This is where visitor entries will be managed.';

  @override
  String get confirmLogoutMessage => 'Are you sure you want to logout?';

  @override
  String get dayShiftTime => 'Day Shift (6 AM - 6 PM)';

  @override
  String get guardId => 'Guard ID';

  @override
  String get error => 'Error';

  @override
  String get securityCommandCenter => 'Security Command Center';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get criticalAlerts => 'Critical Alerts';

  @override
  String get requiresImmediateAttention => 'Requires Immediate Attention';

  @override
  String get incidentsToday => 'Incidents Today';

  @override
  String get monitorAndResolve => 'Monitor and Resolve';

  @override
  String get todaysOverview => 'Today\'s Overview';

  @override
  String get primaryActions => 'Primary Actions';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get residents => 'Residents';

  @override
  String get recentActivities => 'Recent Activities';

  @override
  String get visitorEntryLogged => 'Visitor entry logged';

  @override
  String get flat301JohnDoe => 'Flat 301 - John Doe';

  @override
  String get blockAAllClear => 'Block A - All Clear';

  @override
  String get incidentReported => 'Incident Reported';

  @override
  String get parkingDisputeResolved => 'Parking dispute resolved';

  @override
  String get selectEntryType => 'Select Entry Type';

  @override
  String get emergencyAlert => 'Emergency Alert';

  @override
  String get emergencyAlertDescription => 'Notify all residents immediately about an emergency';

  @override
  String get emergencyAlertSent => 'Emergency alert sent successfully!';

  @override
  String get sendAlert => 'Send Alert';

  @override
  String get visitorsLogged => 'Visitors Logged';

  @override
  String get visitorsLoggedSubtitle => 'Total visitors logged today';

  @override
  String get incidentsReportedSubtitle => 'Total incidents reported today';

  @override
  String get patrolsCompleted => 'Patrols Completed';

  @override
  String get patrolsCompletedSubtitle => 'Total patrols completed today';

  @override
  String get parkingDisputeTitle => 'Parking dispute';

  @override
  String get parkingDisputeDescription => 'Two residents arguing over parking slot.';

  @override
  String get unauthorizedEntryTitle => 'Unauthorized Entry';

  @override
  String get unauthorizedEntryDescription => 'Visitor tried to enter without approval.';

  @override
  String get powerOutageTitle => 'Power Outage';

  @override
  String get powerOutageDescription => 'Reported blackout in Block B.';

  @override
  String todayTime(Object time) {
    return 'Today, $time';
  }

  @override
  String yesterdayTime(Object time) {
    return 'Yesterday, $time';
  }

  @override
  String get isImageOkay => 'Is this image okay?';

  @override
  String get retake => 'Retake';

  @override
  String get confirm => 'Confirm';

  @override
  String get reportIncidentTitle => '🚨 Report Incident';

  @override
  String get incidentTitle => 'Incident Title';

  @override
  String get captureImage => 'Capture Image';

  @override
  String get removeImage => 'Remove Image';

  @override
  String get pleaseFillAllFields => 'Please fill all fields';

  @override
  String get incidentReportedSuccessfully => 'Incident reported successfully!';

  @override
  String get deleteIncident => 'Delete Incident';

  @override
  String get deleteIncidentConfirmation => 'Are you sure you want to delete this incident?';

  @override
  String get incidentDeletedSuccessfully => 'Incident deleted successfully!';

  @override
  String get delete => 'Delete';

  @override
  String get noIncidentsReported => 'No incidents reported yet';

  @override
  String get incidentDeleted => 'Incident deleted';

  @override
  String get undo => 'Undo';

  @override
  String get confirmDelete => 'Confirm Delete';

  @override
  String get report => 'Report';

  @override
  String get justNow => 'Just now';

  @override
  String get securityTitle => 'Security';

  @override
  String get guardTitle => 'Guard';

  @override
  String get societyManagementSystem => 'Society Management System';

  @override
  String get enterMobileNumber => 'Enter Mobile Number';

  @override
  String get verificationCodeMessage => 'Enter the verification code sent to your number';

  @override
  String get mobileNumber => 'Mobile Number';

  @override
  String get mobileNumberHint => '10-digit mobile number';

  @override
  String get mobileNumberRequired => 'Mobile number is required';

  @override
  String get validMobileNumberError => 'Please enter a valid mobile number';

  @override
  String get mobileNumberDigitsOnly => 'Mobile number must contain digits only';

  @override
  String get sendOtp => 'Send OTP';

  @override
  String get smsVerificationAgreement => 'By continuing, you agree to receive SMS for verification';

  @override
  String get countryCode => 'Country Code';

  @override
  String get errorMessage => 'Something went wrong. Please try again.';

  @override
  String get noUserFoundError => 'No user found with this number';

  @override
  String get validMobileNumberPlease => 'Please enter a valid mobile number';

  @override
  String get pendingTasksTitle => 'PENDING TASKS';

  @override
  String get time => 'Time';

  @override
  String get location => 'Location';

  @override
  String get assignedBy => 'Assigned by';

  @override
  String get category => 'Category';

  @override
  String get priority => 'Priority';

  @override
  String taskCompletedMessage(Object title) {
    return 'Task \"$title\" marked as completed!';
  }

  @override
  String get addNewTaskComingSoon => 'Add new task functionality coming soon!';

  @override
  String dueTime(Object time) {
    return 'Due: $time';
  }

  @override
  String get fourHours => '4 hours';

  @override
  String get checkFireExtinguishersDescription => 'Inspect all extinguishers in Basement and Tower C.';

  @override
  String get twoHours => '2 hours';

  @override
  String get eveningPatrolDescription => 'Complete a full round in Blocks A & B.';

  @override
  String get oneAndHalfHours => '1.5 hours';

  @override
  String get cctvSystemCheckDescription => 'Verify all cameras are working and clean lenses.';

  @override
  String get threeHours => '3 hours';

  @override
  String get visitorLogUpdateDescription => 'Update and organize visitor records from past week.';

  @override
  String get oneHour => '1 hour';

  @override
  String get noVisitorsToday => 'No visitors today';

  @override
  String get totalVisitors => 'Total\nVisitors';

  @override
  String get currentlyInside => 'Currently\nInside';

  @override
  String get totalExited => 'Total\nExited';

  @override
  String get visitorEntryTitle => 'Visitor Entry';

  @override
  String get qrOtpTab => 'QR / OTP';

  @override
  String get manualTab => 'Manual';

  @override
  String get otpLabel => 'Enter OTP Code';

  @override
  String get otpHint => 'Enter 6-digit OTP from resident';

  @override
  String get visitorNameLabel => 'Visitor Name';

  @override
  String get visitorNameHint => 'Auto-filled from QR scan';

  @override
  String get visitorNameManualHint => 'Enter full name';

  @override
  String get flatNumberLabel => 'Flat Number';

  @override
  String get flatNumberHint => 'Auto-filled from QR scan';

  @override
  String get flatNumberManualHint => 'e.g., A-101';

  @override
  String get phoneNumberLabel => 'Phone Number';

  @override
  String get capturePhoto => 'Tap to capture visitor photo';

  @override
  String get photoRecommended => 'Recommended for security';

  @override
  String get otpRequiredError => 'Please enter OTP or scan QR code first';

  @override
  String get visitorEntrySuccess => 'Visitor entry recorded successfully!';

  @override
  String get nameRequiredError => 'Name is required';

  @override
  String get flatRequiredError => 'Flat number required';

  @override
  String get phoneRequiredError => 'Phone required';

  @override
  String get phoneInvalidError => 'Invalid phone';

  @override
  String get scanQrCode => 'Scan QR Code';

  @override
  String get visitorsTitle => 'Visitors';

  @override
  String get visitorPageTitle => 'Visitor Page';

  @override
  String get visitorPageDescription => 'This is where visitor entries will be managed.';

  @override
  String get visitorExitTitle => 'Visitor Exit';

  @override
  String get searchVisitorsHint => 'Search visitors by name, flat, or phone...';

  @override
  String get allClear => 'All Clear!';

  @override
  String get noVisitorsFound => 'No visitors found matching your search';

  @override
  String flatLabel(Object flat) {
    return 'Flat $flat';
  }

  @override
  String entryTimeLabel(Object time) {
    return 'Entry: $time';
  }

  @override
  String durationLabel(Object duration) {
    return 'Duration: $duration';
  }

  @override
  String get exitButton => 'Exit';

  @override
  String visitorExitSuccess(Object name) {
    return '$name successfully marked as exited';
  }

  @override
  String get bulkExitTitle => 'Bulk Exit';

  @override
  String get bulkExitMessage => 'Mark all current visitors as exited? This action cannot be undone.';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get exitAllButton => 'Exit All';

  @override
  String bulkExitSuccess(Object count) {
    return '$count visitors marked as exited';
  }
}
