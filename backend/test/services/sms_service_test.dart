import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:backend/services/sms_service.dart';
import 'package:backend/services/email_service.dart';
import 'package:backend/repositories/user_repository.dart';

import 'ChiaraSMS.mocks.dart';
import 'login_hashing_test.mocks.dart';

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
      simulationEmail: 'test@sms.it',
    );
  });

  group('SmsService - sendOtp', () {

    test(
      'TC_SMS_1 - TEL1 + CODE1 (valid phone + valid OTP)',
          () async {
        /**
         * ===========================
         * Test Case ID: TC_SMS_1
         * Test Frame: TF1
         * Objective: Verificare invio OTP con telefono valido e OTP corretto
         *
         * Input parameters:
         * - telefono = +391234567890
         * - otp = 123456
         * ===========================
         */

        // Arrange
        when(mockUserRepository.findUserByPhone('+391234567890'))
            .thenAnswer((_) async => {'id': 1, 'telefono': '+391234567890'});

        when(mockEmailService.send(
          to: anyNamed('to'),
          subject: anyNamed('subject'),
          htmlContent: anyNamed('htmlContent'),
        )).thenAnswer((_) async {});

        // Act
        await smsService.sendOtp('+391234567890', '123456');

        // Assert
        verify(mockUserRepository.findUserByPhone('+391234567890')).called(1);
        verify(mockEmailService.send(
          to: 'test@sms.it',
          subject: anyNamed('subject'),
          htmlContent: anyNamed('htmlContent'),
        )).called(1);
      },
    );

    test(
      'TC_SMS_2 - TEL1 + CODE2 (invalid OTP format)',
          () {
        /**
         * ===========================
         * Test Case ID: TC_SMS_2
         * Test Frame: TF2
         * Objective: Verificare errore formato OTP non valido
         *
         * Input parameters:
         * - telefono = +391234567890
         * - otp = 12AB (invalid)
         * ===========================
         */

        expect(
              () => smsService.sendOtp('+391234567890', '12AB'),
          throwsA(isA<ArgumentError>()),
        );
      },
    );

    test(
      'TC_SMS_3 - TEL2 (invalid format) + CODE1',
          () {
        /**
         * ===========================
         * Test Case ID: TC_SMS_3
         * Test Frame: TF3
         * Objective: Verificare errore formato telefono non valido
         *
         * Input parameters:
         * - telefono = 12345
         * - otp = 123456
         * ===========================
         */

        expect(
              () => smsService.sendOtp('12345', '123456'),
          throwsA(isA<ArgumentError>()),
        );
      },
    );

    test(
      'TC_SMS_4 - TEL3 (non esistente) + CODE1',
          () {
        /**
         * ===========================
         * Test Case ID: TC_SMS_4
         * Test Frame: TF4
         * Objective: Verificare errore utente non trovato nel DB
         *
         * Input parameters:
         * - telefono = +399999999999
         * - otp = 123456
         * ===========================
         */

        when(mockUserRepository.findUserByPhone('+399999999999'))
            .thenAnswer((_) async => null);

        expect(
              () => smsService.sendOtp('+399999999999', '123456'),
          throwsException,
        );
      },
    );
  });
}