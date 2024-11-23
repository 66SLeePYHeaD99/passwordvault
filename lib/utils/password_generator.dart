
import 'package:random_password_generator/random_password_generator.dart';

String generateSecurePassword() {
  final passwordGenerator = RandomPasswordGenerator();
  String newPassword = passwordGenerator.randomPassword(
    letters: true,
    numbers: true,
    specialChar: true,
    passwordLength: 16,
  );
  return newPassword;
}
