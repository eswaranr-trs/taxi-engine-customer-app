import 'package:flutter/animation.dart';
import 'package:get/get.dart';
import 'package:orange_taxi_customer_app/features/main/home/views/active_trips.dart';
import 'package:orange_taxi_customer_app/features/main/home/views/finding_driver_screen.dart';
import 'package:orange_taxi_customer_app/features/main/home/bindings/home_binding.dart';
import 'package:orange_taxi_customer_app/features/main/home/views/home_screen.dart';
import 'package:orange_taxi_customer_app/features/auth/otp/binding/otp_binding.dart';
import 'package:orange_taxi_customer_app/features/auth/otp/view/otp_verification_screen.dart';
import 'package:orange_taxi_customer_app/features/auth/signup/view/signup_screen.dart';
import 'package:orange_taxi_customer_app/features/main/home/views/sos_screen.dart';
import 'package:orange_taxi_customer_app/features/main/payment/binding/payment_binding.dart';
import 'package:orange_taxi_customer_app/features/main/payment/views/payment_screen.dart';
import 'package:orange_taxi_customer_app/features/main/saved_addresses/binding/saved_address_binding.dart';
import 'package:orange_taxi_customer_app/features/main/saved_addresses/view/saved_address.dart';
import 'package:orange_taxi_customer_app/features/main/trip_details/bindings/trip_in_progress_binding.dart';
import 'package:orange_taxi_customer_app/features/main/trip_details/screens/trip_details.dart';
import 'package:orange_taxi_customer_app/features/main/trip_details/screens/trip_summary.dart';
import 'package:orange_taxi_customer_app/features/main/trip_details/bindings/trip_details_binding.dart';
import 'package:orange_taxi_customer_app/features/main/trip_details/screens/trip_finished_screen.dart';
import 'package:orange_taxi_customer_app/features/main/trip_details/screens/trip_verification.dart';
import 'package:orange_taxi_customer_app/features/main/trip_details/screens/trip_in_progress_screen.dart';
import 'package:orange_taxi_customer_app/features/main/home/bindings/vehicle_selection_binding.dart';
import 'package:orange_taxi_customer_app/features/main/my_trips/views/my_trips_screen.dart';
import 'package:orange_taxi_customer_app/features/main/my_trips/bindings/my_trips_binding.dart';
import 'package:orange_taxi_customer_app/features/main/payment/views/payment_success_screen.dart';
import 'package:orange_taxi_customer_app/features/main/trip_details/screens/rate_trip_screen.dart';
import 'package:orange_taxi_customer_app/features/main/profile/views/profile_screen.dart';
import 'package:orange_taxi_customer_app/features/main/profile/bindings/profile_binding.dart';
import 'package:orange_taxi_customer_app/features/main/wallet/bindings/wallet_binding.dart';
import 'package:orange_taxi_customer_app/features/main/wallet/views/wallet_screen.dart';
import 'package:orange_taxi_customer_app/features/main/wallet/views/add_money.dart';
import 'package:orange_taxi_customer_app/features/main/wallet/views/add_money_success.dart';
import 'package:orange_taxi_customer_app/features/main/wallet/views/withdraw_screen.dart';
import 'package:orange_taxi_customer_app/features/auth/language/views/language_screen.dart';
import 'package:orange_taxi_customer_app/features/auth/language/bindings/language_binding.dart';
import 'package:orange_taxi_customer_app/features/main/home/views/location_search_screen.dart';
import 'package:orange_taxi_customer_app/features/main/home/bindings/location_search_binding.dart';
import 'package:orange_taxi_customer_app/features/main/home/views/route_summary_screen.dart';
import 'package:orange_taxi_customer_app/features/main/settings/views/settings_screen.dart';
import 'package:orange_taxi_customer_app/features/main/settings/views/privacy_screen.dart';
import 'package:orange_taxi_customer_app/features/main/settings/views/active_devices_screen.dart';
import 'package:orange_taxi_customer_app/features/main/settings/views/notification_settings_screen.dart';
import 'package:orange_taxi_customer_app/features/main/chat/views/chat_screen.dart';
import 'package:orange_taxi_customer_app/features/main/chat/bindings/chat_binding.dart';
import 'package:orange_taxi_customer_app/features/main/offers/views/offers_screen.dart';
import 'package:orange_taxi_customer_app/features/main/offers/bindings/offers_binding.dart';
import 'package:orange_taxi_customer_app/features/main/notifications/views/notifications_screen.dart';
import 'package:orange_taxi_customer_app/features/main/settings/views/ratings_screen.dart';

import '../../features/auth/splash/binding/splash_binding.dart';
import '../../features/auth/splash/views/splash_screen.dart';
import '../../features/auth/login/view/login_screen.dart';
import '../../features/auth/login/binding/login_binding.dart';
import '../../features/auth/signup/binding/signup_binding.dart';
import '../../features/main/home/bindings/finding_driver_binding.dart';
import '../../features/auth/welcome/view/welcome_screen.dart';
import '../../features/auth/welcome/binding/welcome_binding.dart';
import '../../features/auth/terms/view/terms_screen.dart';
import '../../features/auth/terms/binding/terms_binding.dart';
import '../../features/legal/view/legal_screen.dart';
import '../../features/legal/binding/legal_binding.dart';

class AppRoutes {
  static const String language = '/language';
  static const String signup = '/signup';
  static const String login = '/login';
  static const String splash = '/splash';
  static const String welcome = '/welcome';
  static const String terms = '/terms';
  static const String legal = '/legal';
  static const String otpVerification = '/otpVerification';
  static const String home = '/home';
  static const String locationSearch = '/locationSearch';
  static const String routeSummary = '/routeSummary';
  static const String myTrips = '/myTrips';
  static const String findingDriver = '/findingDriver';
  static const String tripVerification = '/tripVerification';
  static const String tripInProgress = '/tripInProgress';
  static const String tripDetails = '/tripDetails';
  static const String tripSummary = '/tripSummary';
  static const String tripFinished = '/tripFinished';
  static const String paymentSuccess = '/paymentSuccess';
  static const String paymentScreen = '/paymentScreen';
  static const String rateTrip = '/rateTrip';
  static const String profile = '/profile';
  static const String wallet = '/wallet';
  static const String addMoney = '/addMoney';
  static const String addMoneySuccess = '/addMoneySuccess';
  static const String withdraw = '/withdraw';
  static const String settings = '/settings';
  static const String privacySettings = '/privacySettings';
  static const String activeDevices = '/activeDevices';
  static const String notificationSettings = '/notificationSettings';
  static const String ratings = '/ratings';
  static const String savedAddresses = '/savedAddresses';
  static const String sos = '/sos';
  static const String activeTrips = '/activeTrips';
  static const String chat = '/chat';
  static const String offers = '/offers';
  static const String notifications = '/notifications';

  static const Set<String> tripFlowRoutes = {
    tripSummary,
    findingDriver,
    tripVerification,
    tripInProgress,
    tripDetails,
    tripFinished,
    paymentScreen,
    paymentSuccess,
    rateTrip,
    chat,
    sos,
  };

  static final routes = [
    GetPage(name: language, page: () => const LanguageScreen(), binding: LanguageBinding()),
    GetPage(name: signup, page: () => const SignUpScreen(), binding: SignUpBinding()),
    GetPage(name: login, page: () => const LoginScreen(), binding: LoginBinding()),
    GetPage(name: tripVerification, page: () => TripVerificationScreen(), binding: TripInProgressBinding()),
    GetPage(name: tripInProgress, page: () => TripInProgressScreen(), binding: TripInProgressBinding()),
    GetPage(name: tripDetails, page: () => const TripDetailsScreen(), binding: TripDetailsBinding()),
    GetPage(name: tripSummary, page: () => TripSummaryScreen(), binding: TripDetailsBinding()),
    GetPage(name: splash, page: () => const SplashScreen(), binding: SplashBinding()),
    GetPage(name: welcome, page: () => WelcomeScreen(), binding: WelcomeBinding()),
    GetPage(name: terms, page: () => const TermsScreen(), binding: TermsBinding()),
    GetPage(name: legal, page: () => const LegalScreen(), binding: LegalBinding()),
    GetPage(name: otpVerification, page: () => const OtpVerificationScreen(), binding: OtpBinding()),
    GetPage(name: home, page: () => HomeScreen(), binding: HomeBinding()),
    GetPage(name: locationSearch, page: () => LocationSearchScreen(), binding: LocationSearchBinding()),
    GetPage(
      name: routeSummary,
      page: () => RouteSummaryScreen(),
      binding: VehicleSelectionBinding(),
      transition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    ),
    GetPage(name: myTrips, page: () => const MyTripsScreen(), binding: MyTripsBinding()),
    GetPage(name: findingDriver, page: () => const FindingDriverScreen(), binding: FindingDriverBinding()),
    GetPage(name: tripFinished, page: () => const TripFinishedScreen(), binding: FindingDriverBinding()),
    GetPage(name: paymentScreen, page: () => PaymentScreen(), binding: PaymentBinding()),
    GetPage(name: paymentSuccess, page: () => const PaymentSuccessScreen()),
    GetPage(name: rateTrip, page: () => const RateTripScreen()),
    GetPage(name: profile, page: () => const ProfileScreen(), binding: ProfileBinding()),
    GetPage(name: wallet, page: () => WalletScreen(), binding: WalletBinding()),
    GetPage(name: addMoney, page: () => const AddMoneyScreen(), binding: WalletBinding()),
    GetPage(name: addMoneySuccess, page: () => const AddMoneySuccessScreen()),
    GetPage(name: withdraw, page: () => const WithdrawScreen(), binding: WalletBinding()),
    GetPage(name: settings, page: () => const SettingsScreen()),
    GetPage(name: privacySettings, page: () => const PrivacyScreen()),
    GetPage(name: activeDevices, page: () => const ActiveDevicesScreen()),
    GetPage(name: notificationSettings, page: () => const NotificationSettingsScreen()),
    GetPage(name: ratings, page: () => const RatingsScreen()),
    GetPage(name: savedAddresses, page: () => SavedAddressesScreen(), binding: SavedAddressBinding()),
    GetPage(name: sos, page: () => const SosScreen(), binding: HomeBinding()),
    GetPage(name: activeTrips, page: () => ActiveTripsScreen(), bindings: [HomeBinding()]),
    GetPage(name: chat, page: () => const ChatScreen(), binding: ChatBinding()),
    GetPage(name: offers, page: () => const OffersScreen(showPromoCodes: false), binding: OffersBinding()),
    GetPage(name: notifications, page: () => const NotificationsScreen()),
  ];
}
