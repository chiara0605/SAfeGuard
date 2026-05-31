import 'package:test/test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'ChiaraSMS.mocks.dart';

import 'package:backend/services/sms_service.dart';
import 'package:backend/services/email_service.dart';
import 'package:backend/repositories/user_repository.dart';

@GenerateNiceMocks([
  MockSpec<EmailService>(),
  MockSpec<UserRepository>(),
])
void main() {
  late SmsService smsService;
  late MockEmailService mockEmailService;
  late MockUserRepository mockUserRepository;

  setUp(() {
    mockEmailService = MockEmailService();
    mockUserRepository = MockUserRepository();

    smsService = SmsService(
      emailService: mockEmailService,
      userRepository: mockUserRepository,
      simulationEmail: 'test@simulation.com',
    );
  });

  // =========================
  // TC_RF1 - TEL2 + CODE1
  // =========================
  test('TC_RF1 - TEL2 invalid format should throw ArgumentError', () {
    /**
     * ===============================
     * Test Case ID: TC_RF1_1
     * Test Frame: TEL2[ERROR], CODE1
     * Purpose: Validate that invalid phone format is rejected before OTP processing
     *
     * Input parameters:
     * - telefono = "12345"
     * - otp = "123456"
     * ===============================
     */

    expect(
          () => smsService.sendOtp("12345", "123456"),
      throwsA(isA<ArgumentError>()),
    );
  });

  // =========================
  // TC_RF2 - TEL3 + CODE1
  // =========================
  test('TC_RF2 - Non existing phone should throw Exception', () async {
    /**
     * ===============================
     * Test Case ID: TC_RF2_1
     * Test Frame: TEL3[ERROR], CODE1
     * Purpose: Verify behavior when phone is not found in DB
     *
     * Input parameters:
     * - telefono = "+391234567890"
     * - otp = "123456"
     * ===============================
     */

    when(mockUserRepository.findUserByPhone("+391234567890"))
        .thenAnswer((_) async => null);

    expect(
          () => smsService.sendOtp("+391234567890", "123456"),
      throwsException,
    );
  });

  // =========================
  // TC_RF3 - TEL1 + CODE2
  // =========================
  test('TC_RF3 - Invalid OTP format should throw ArgumentError', () async {
    /**
     * ===============================
     * Test Case ID: TC_RF3_1
     * Test Frame: TEL1, CODE2[ERROR]
     * Purpose: Validate OTP format rules (must be 6 digits)
     *
     * Input parameters:
     * - telefono = "+391234567890"
     * - otp = "12A45"
     * ===============================
     */

    when(mockUserRepository.findUserByPhone("+391234567890"))
        .thenAnswer((_) async => {'id': 1});

    expect(
          () => smsService.sendOtp("+391234567890", "12A45"),
      throwsA(isA<ArgumentError>()),
    );
  });

  // =========================
  // TC_RF4 - TEL1 + CODE1
  // =========================
  test('TC_RF4 - Valid phone and OTP should complete successfully', () async {
    /**
     * ===============================
     * Test Case ID: TC_RF4_1
     * Test Frame: TEL1, CODE1
     * Purpose: Verify successful OTP flow and email invocation
     *
     * Input parameters:
     * - telefono = "+391234567890"
     * - otp = "123456"
     * ===============================
     */

    when(mockUserRepository.findUserByPhone("+391234567890"))
        .thenAnswer((_) async => {'id': 1});

    when(
      mockEmailService.send(
        to: anyNamed('to'),
        subject: anyNamed('subject'),
        htmlContent: anyNamed('htmlContent'),
      ),
    ).thenAnswer((_) async => {});

    await smsService.sendOtp("+391234567890", "123456");

    verify(
      mockEmailService.send(
        to: "test@simulation.com",
        subject: anyNamed('subject'),
        htmlContent: anyNamed('htmlContent'),
      ),
    ).called(1);
  });
}