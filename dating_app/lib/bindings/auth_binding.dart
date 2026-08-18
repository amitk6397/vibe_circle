import 'package:get/get.dart';
import '../features/auth/controllers/auth_controller.dart';
import '../features/auth/controllers/login_controller.dart';
import '../features/auth/controllers/register_controller.dart';
import '../features/auth/controllers/forgot_password_controller.dart';
import '../features/auth/controllers/verify_email_controller.dart';
import '../features/auth/controllers/basic_profile_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthController>(() => AuthController(), fenix: true);
    Get.lazyPut<LoginController>(() => LoginController(), fenix: true);
    Get.lazyPut<RegisterController>(() => RegisterController(), fenix: true);
    Get.lazyPut<ForgotPasswordController>(() => ForgotPasswordController(), fenix: true);
    Get.lazyPut<VerifyEmailController>(() => VerifyEmailController(), fenix: true);
    Get.lazyPut<BasicProfileController>(() => BasicProfileController(), fenix: true);
  }
}
