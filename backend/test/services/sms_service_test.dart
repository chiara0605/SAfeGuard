import 'package:test/test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:backend/services/sms_service.dart';
import 'package:backend/services/email_service.dart';
import 'package:backend/repositories/user_repository.dart';

// Generazione automatica dei mock
@GenerateNiceMocks([MockSpec<EmailService>(), MockSpec<UserRepository>()])
import 'sms_service_test.mocks.dart';

void main() {
  late MockEmailService mockEmailService;
  late MockUserRepository mockUserRepository;
  late SmsService smsService;

  // Utente di esempio per il mock
  final Map<String, dynamic> existingUser = {'telefono': '+391234567890'};

  setUp(() {
    mockEmailService = MockEmailService();
    mockUserRepository = MockUserRepository();
    smsService = SmsService(
      emailService: mockEmailService,
      userRepository: mockUserRepository,
      simulationEmail: 'admin@test.com',
    );
  });

  // ===========================
  // Test Case ID: TC_SMS_1
  // Test Frame: TEL2[ERROR], CODE1
  // Obiettivo: Verifica che venga lanciata eccezione se il numero di telefono ha formato non valido
  //
  // Parametri di input:
  // - telefono = "+12ABC" (formato non valido)
  // - otp = "123456"
  // ===========================
  test('TC_SMS_1 - Numero telefono formato non valido', () async {
    final otp = '123456';
    final telefono = '+12ABC';

    expect(
          () async => await smsService.sendOtp(telefono, otp),
      throwsA(isA<ArgumentError>().having((e) => e.message, 'message', contains('Formato telefono'))),
    );
  });

  // ===========================
  // Test Case ID: TC_SMS_2
  // Test Frame: TEL3[ERROR], CODE1
  // Obiettivo: Verifica che venga lanciata eccezione se il numero non esiste nel DB
  //
  // Parametri di input:
  // - telefono = "+399876543210" (inesistente)
  // - otp = "123456"
  // ===========================
  test('TC_SMS_2 - Numero telefono inesistente', () async {
    final otp = '123456';
    final telefono = '+399876543210';

    // Mock del repository: nessun utente trovato
    when(mockUserRepository.findUserByPhone(telefono)).thenAnswer((_) async => null);

    expect(
          () async => await smsService.sendOtp(telefono, otp),
      throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Numero di telefono non trovato'))),
    );
  });

  // ===========================
  // Test Case ID: TC_SMS_3
  // Test Frame: TEL1, CODE2[ERROR]
  // Obiettivo: Verifica che venga lanciata eccezione se l'OTP ha formato errato
  //
  // Parametri di input:
  // - telefono = "+391234567890" (valido)
  // - otp = "123" (formato errato)
  // ===========================
  test('TC_SMS_3 - OTP formato errato', () async {
    final otp = '123';
    final telefono = '+391234567890';

    // Mock del repository: utente presente
    when(mockUserRepository.findUserByPhone(telefono)).thenAnswer((_) async => existingUser);

    expect(
          () async => await smsService.sendOtp(telefono, otp),
      throwsA(isA<ArgumentError>().having((e) => e.message, 'message', contains('Formato OTP'))),
    );
  });

  // ===========================
  // Test Case ID: TC_SMS_4
  // Test Frame: TEL1, CODE1
  // Obiettivo: Verifica invio OTP correttamente simulato via email
  //
  // Parametri di input:
  // - telefono = "+391234567890" (valido)
  // - otp = "123456" (valido)
  // ===========================
  test('TC_SMS_4 - Invio OTP simulato corretto', () async {
    final otp = '123456';
    final telefono = '+391234567890';

    // Mock del repository: utente presente
    when(mockUserRepository.findUserByPhone(telefono)).thenAnswer((_) async => existingUser);

    // Mock del servizio email
    when(mockEmailService.send(
      to: anyNamed('to'),
      subject: anyNamed('subject'),
      htmlContent: anyNamed('htmlContent'),
    )).thenAnswer((_) async => Future.value());

    await smsService.sendOtp(telefono, otp);

    // Verifica chiamata al servizio email
    verify(mockEmailService.send(
      to: 'admin@test.com',
      subject: 'SIMULAZIONE SMS per $telefono',
      htmlContent: anyNamed('htmlContent'),
    )).called(1);
  });
}
