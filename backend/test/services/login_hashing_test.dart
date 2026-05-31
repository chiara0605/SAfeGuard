import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:crypto/crypto.dart';

// Project Imports
import 'package:data_models/utente.dart';
import 'package:data_models/utente_generico.dart';
import 'package:backend/repositories/user_repository.dart';
import 'package:backend/services/jwt_service.dart';
import 'package:backend/services/login_service.dart';

// Generated Mocks
import 'login_hashing_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<UserRepository>(),
  MockSpec<JWTService>(),
])
void main() {
  late LoginService loginService;
  late MockUserRepository mockUserRepository;
  late MockJWTService mockJWTService;

  // Il segreto deve corrispondere esattamente a quello nel LoginService
  const String fallbackSecret = 'fallback_secret_dev';

  // Helper identico alla funzione privata del Service per generare l'hash corretto
  String computeHash(String password) {
    final bytes = utf8.encode(password + fallbackSecret);
    return sha256.convert(bytes).toString();
  }

  setUp(() {
    mockUserRepository = MockUserRepository();
    mockJWTService = MockJWTService();
    loginService = LoginService(
      userRepository: mockUserRepository,
      jwtService: mockJWTService,
    );
  });

  group('Login Hashing - Black Box Tests', () {

    /**
     * ===============================
     * Test Case ID: TC_RF1_1
     * Test Frame: TF1
     * Purpose: Standard Login con password corretta (MATCH1)
     * =============================
     */
    test('TC_RF1_1 - Standard Login con password corretta deve avere successo', () async {
      // Arrange
      const String email = "utente@test.it";
      const String password = "password123";
      final String hashedPw = computeHash(password);

      final userData = {
        'id': 1,
        'email': email,
        'passwordHash': hashedPw,
        'isVerified': true,
        'nome': 'Chiara',
        'cognome': 'Test',
        'isSoccorritore': false,
      };

      // Mocking del repository per trovare l'utente
      when(mockUserRepository.findUserByEmail(email))
          .thenAnswer((_) async => userData);

      // Mocking della generazione del token
      when(mockJWTService.generateToken(any, any))
          .thenReturn("fake_jwt_token");

      // Act
      final result = await loginService.login(email: email, password: password);

      // Assert
      expect(result, isNotNull, reason: "Il login dovrebbe restituire una mappa, non null");
      expect(result!['token'], equals("fake_jwt_token"));
      expect(result['user'], isA<Utente>());
      verify(mockUserRepository.findUserByEmail(email)).called(1);
    });

    /**
     * ===============================
     * Test Case ID: TC_RF1_2
     * Test Frame: TF2
     * Purpose: Standard Login con password errata (MATCH2)
     * =============================
     */
    test('TC_RF1_2 - Standard Login con password errata deve restituire null', () async {
      // Arrange
      const String email = "utente@test.it";
      const String correctPassword = "password_giusta";
      const String wrongPassword = "password_sbagliata";
      final String hashedPwInDb = computeHash(correctPassword);

      final userData = {
        'id': 1,
        'email': email,
        'passwordHash': hashedPwInDb,
        'isVerified': true,
      };

      when(mockUserRepository.findUserByEmail(email))
          .thenAnswer((_) async => userData);

      // Act
      final result = await loginService.login(email: email, password: wrongPassword);

      // Assert
      expect(result, isNull, reason: "Il login con password errata deve fallire restituendo null");
    });

    /**
     * ===============================
     * Test Case ID: TC_RF1_3
     * Test Frame: TF3
     * Purpose: Social Login (TYPE2) - Utente senza hash nel DB
     * =============================
     */
    test('TC_RF1_3 - Utente Social (senza hash) deve lanciare eccezione se usa login standard', () async {
      // Arrange
      const String email = "google_user@gmail.com";

      final userData = {
        'id': 2,
        'email': email,
        'passwordHash': '', // Campo vuoto come nel tuo codice
        'isVerified': true,
      };

      when(mockUserRepository.findUserByEmail(email))
          .thenAnswer((_) async => userData);

      // Act & Assert
      expect(
              () => loginService.login(email: email, password: "qualsiasi_password"),
          throwsA(predicate((e) =>
          e is Exception && e.toString().contains('Questo utente deve accedere tramite Google/Apple')))
      );
    });
  });
}