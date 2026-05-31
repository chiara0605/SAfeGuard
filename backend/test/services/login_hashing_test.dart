import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:backend/services/login_service.dart';
import 'package:backend/repositories/user_repository.dart';
import 'package:backend/services/jwt_service.dart';
import 'package:data_models/utente.dart';



import 'email_service_test.mocks.dart';
import 'login_hashing_test.mocks.dart' hide MockUserRepository;

@GenerateNiceMocks([
  MockSpec<UserRepository>(),
  MockSpec<JWTService>(),
])
void main() {
  late MockUserRepository mockRepo;
  late MockJWTService mockJwt;
  late LoginService service;

  setUp(() {
    mockRepo = MockUserRepository();
    mockJwt = MockJWTService();

    service = LoginService(
      userRepository: mockRepo,
      jwtService: mockJwt,
    );
  });

  // ===========================
  // TF1 - LOGIN STANDARD OK
  // ===========================
  test('TC_LOGIN_1 - Standard login success', () async {
    /**
     * ===========================
     * Test Case ID: TC_LOGIN_1
     * Test Frame: TF1
     * Objective: Verificare login corretto con email e password valida
     *
     * Input parameters:
     * - email = test@mail.com
     * - password = password123
     * ===========================
     */

    final userJson = {
      'id': 1,
      'email': 'test@mail.com',
      'passwordHash': 'VALID_HASH',
      'isVerified': true,
      'attivo': true,
      'isSoccorritore': false,
    };

    when(mockRepo.findUserByEmail('test@mail.com'))
        .thenAnswer((_) async => userJson);

    when(mockJwt.generateToken(any, any))
        .thenReturn('fake_token');

    final result = await service.login(
      email: 'test@mail.com',
      password: 'password123',
    );

    expect(result, isNotNull);
    expect(result!['token'], equals('fake_token'));
    expect(result['user'], isA<Utente>());
  });

  // ===========================
  // TF2 - SOCIAL LOGIN (NO PASSWORD HASH)
  // ===========================
  test('TC_LOGIN_2 - Social login throws exception', () async {
    /**
     * ===========================
     * Test Case ID: TC_LOGIN_2
     * Test Frame: TF2
     * Objective: Verificare login social senza password hash
     *
     * Input parameters:
     * - email = social@mail.com
     * - password = ignored
     * ===========================
     */

    final userJson = {
      'id': 2,
      'email': 'social@mail.com',
      'passwordHash': '',
      'isVerified': true,
      'attivo': true,
      'isSoccorritore': false,
    };

    when(mockRepo.findUserByEmail('social@mail.com'))
        .thenAnswer((_) async => userJson);

    expect(
          () async => await service.login(
        email: 'social@mail.com',
        password: 'any',
      ),
      throwsException,
    );
  });

  // ===========================
  // TF3 - PASSWORD MISMATCH (ERROR)
  // ===========================
  test('TC_LOGIN_3 - Password mismatch returns null', () async {
    /**
     * ===========================
     * Test Case ID: TC_LOGIN_3
     * Test Frame: TF3
     * Objective: Verificare login fallito per password errata
     *
     * Input parameters:
     * - email = test@mail.com
     * - password = wrong_password
     * ===========================
     */

    final userJson = {
      'id': 3,
      'email': 'test@mail.com',
      'passwordHash': 'VALID_HASH',
      'isVerified': true,
      'attivo': true,
      'isSoccorritore': false,
    };

    when(mockRepo.findUserByEmail('test@mail.com'))
        .thenAnswer((_) async => userJson);

    final result = await service.login(
      email: 'test@mail.com',
      password: 'wrong_password',
    );

    expect(result, isNull);
  });
}