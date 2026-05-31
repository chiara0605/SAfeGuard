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
import 'ChiaraLogin.mocks.dart';

@GenerateNiceMocks([
  MockSpec<UserRepository>(),
  MockSpec<JWTService>(),
])
void main() {
  late LoginService service;
  late MockUserRepository mockUserRepository;
  late MockJWTService mockJwtService;

  const testPassword = 'Password123';
  const secret = 'fallback_secret_dev';

  String hashPassword(String password) {
    final bytes = utf8.encode(password + secret);
    return sha256.convert(bytes).toString();
  }

  setUp(() {
    mockUserRepository = MockUserRepository();
    mockJwtService = MockJWTService();

    service = LoginService(
      userRepository: mockUserRepository,
      jwtService: mockJwtService,
    );
  });

  /**
   * ===============================
   * Test Case ID: TC_LoginHashing_1
   * Test Frame: TF1
   * Purpose: Verify login fails when standard login password hash mismatches
   *
   * Input parameters:
   * - email = user@test.com
   * - password = Password123
   * ===============================
   */
  test('TC_LoginHashing_1 - TYPE1,MATCH2 [ERROR]', () async {
    when(
      mockUserRepository.findUserByEmail('user@test.com'),
    ).thenAnswer((_) async => {
      'id': 1,
      'email': 'user@test.com',
      'passwordHash': 'WRONG_HASH',
      'isVerified': true,
    });

    final result = await service.login(
      email: 'user@test.com',
      password: testPassword,
    );

    expect(result, isNull);

    verify(mockUserRepository.findUserByEmail('user@test.com')).called(1);
    verifyNever(mockJwtService.generateToken(any, any));
  });

  /**
   * ===============================
   * Test Case ID: TC_LoginHashing_2
   * Test Frame: TF2
   * Purpose: Verify login succeeds when standard login password hash matches
   *
   * Input parameters:
   * - email = user@test.com
   * - password = Password123
   * ===============================
   */
  test('TC_LoginHashing_2 - TYPE1,MATCH1', () async {
    when(
      mockUserRepository.findUserByEmail('user@test.com'),
    ).thenAnswer((_) async => {
      'id': 1,
      'email': 'user@test.com',
      'passwordHash': hashPassword(testPassword),
      'isVerified': true,
    });

    when(
      mockJwtService.generateToken(1, 'Utente'),
    ).thenReturn('mocked_jwt_token');

    final result = await service.login(
      email: 'user@test.com',
      password: testPassword,
    );

    expect(result, isNotNull);
    expect(result!['token'], equals('mocked_jwt_token'));
    expect(result['user'], isNotNull);

    verify(mockUserRepository.findUserByEmail('user@test.com')).called(1);
    verify(mockJwtService.generateToken(1, 'Utente')).called(1);
  });

  /**
   * ===============================
   * Test Case ID: TC_LoginHashing_3
   * Test Frame: TF3
   * Purpose: Verify social login users cannot login with password
   *
   * Input parameters:
   * - email = social@test.com
   * - password = Password123
   * ===============================
   */
  test('TC_LoginHashing_3 - TYPE2', () async {
    when(
      mockUserRepository.findUserByEmail('social@test.com'),
    ).thenAnswer((_) async => {
      'id': 2,
      'email': 'social@test.com',
      'passwordHash': '',
      'isVerified': true,
    });

    expect(
          () => service.login(
        email: 'social@test.com',
        password: testPassword,
      ),
      throwsA(
        predicate(
              (e) =>
          e is Exception &&
              e.toString().contains('Google/Apple'),
        ),
      ),
    );

    verify(mockUserRepository.findUserByEmail('social@test.com')).called(1);
    verifyNever(mockJwtService.generateToken(any, any));
  });
}

