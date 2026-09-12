import 'package:flutter_test/flutter_test.dart';
import 'package:agreemint/core/services/celebration_service.dart';
import 'package:agreemint/features/students/models/student_model.dart';

void main() {
  group('CelebrationService Tests', () {
    test('parseCnpBirthDate extracts exact birth date correctly across centuries', () {
      // 1900s Male: 1900101123456 -> 1990-01-01
      final dt1 = CelebrationService.parseCnpBirthDate('1900101123456');
      expect(dt1, equals(DateTime(1990, 1, 1)));

      // 1900s Female: 2850315... -> 1985-03-15
      final dt2 = CelebrationService.parseCnpBirthDate('2850315123456');
      expect(dt2, equals(DateTime(1985, 3, 15)));

      // 2000s Male: 5040723... -> 2004-07-23
      final dt3 = CelebrationService.parseCnpBirthDate('5040723123456');
      expect(dt3, equals(DateTime(2004, 7, 23)));

      // 2000s Female: 6021130... -> 2002-11-30
      final dt4 = CelebrationService.parseCnpBirthDate('6021130123456');
      expect(dt4, equals(DateTime(2002, 11, 30)));

      // Invalid CNPs
      expect(CelebrationService.parseCnpBirthDate(null), isNull);
      expect(CelebrationService.parseCnpBirthDate(''), isNull);
      expect(CelebrationService.parseCnpBirthDate('123'), isNull);
      expect(CelebrationService.parseCnpBirthDate('1900230123456'), isNull); // Feb 30 does not exist
    });

    test('calculateAge calculates correct age relative to a reference date', () {
      final birth = DateTime(2000, 5, 20);

      // Before birthday
      expect(CelebrationService.calculateAge(birth, asOf: DateTime(2025, 5, 19)), equals(24));
      // On birthday
      expect(CelebrationService.calculateAge(birth, asOf: DateTime(2025, 5, 20)), equals(25));
      // After birthday
      expect(CelebrationService.calculateAge(birth, asOf: DateTime(2025, 5, 21)), equals(25));
    });

    test('Orthodox Easter and Floriile calculations match calendar for known years', () {
      // 2024: Easter = May 5, Floriile = April 28
      final easter2024 = CelebrationService.getOrthodoxEaster(2024);
      expect(easter2024.year, equals(2024));
      expect(easter2024.month, equals(5));
      expect(easter2024.day, equals(5));
      final florii2024 = CelebrationService.getFloriileDate(2024);
      expect(florii2024.year, equals(2024));
      expect(florii2024.month, equals(4));
      expect(florii2024.day, equals(28));

      // 2025: Easter = April 20, Floriile = April 13
      final easter2025 = CelebrationService.getOrthodoxEaster(2025);
      expect(easter2025.year, equals(2025));
      expect(easter2025.month, equals(4));
      expect(easter2025.day, equals(20));
      final florii2025 = CelebrationService.getFloriileDate(2025);
      expect(florii2025.year, equals(2025));
      expect(florii2025.month, equals(4));
      expect(florii2025.day, equals(13));

      // 2026: Easter = April 12, Floriile = April 5
      final easter2026 = CelebrationService.getOrthodoxEaster(2026);
      expect(easter2026.year, equals(2026));
      expect(easter2026.month, equals(4));
      expect(easter2026.day, equals(12));
      final florii2026 = CelebrationService.getFloriileDate(2026);
      expect(florii2026.year, equals(2026));
      expect(florii2026.month, equals(4));
      expect(florii2026.day, equals(5));
    });

    test('Name token extraction and diacritics normalization work properly', () {
      expect(CelebrationService.normalizeName('Ștefan'), equals('stefan'));
      expect(CelebrationService.normalizeName('Mărioara'), equals('marioara'));
      expect(CelebrationService.normalizeName('Lăcrămioara'), equals('lacramioara'));
      expect(CelebrationService.normalizeName('Păvălaș'), equals('pavalas'));
      expect(CelebrationService.normalizeName('Ionuț'), equals('ionut'));

      final tokens = CelebrationService.extractNameTokens('Popescu George-Andrei (Junior)');
      expect(tokens, containsAll(['popescu', 'george', 'andrei', 'junior']));
    });

    test('getUpcomingCelebrations correctly detects upcoming birthdays and name days', () {
      // Reference date: 2026-04-20
      final refDate = DateTime(2026, 4, 20);

      final students = [
        const StudentModel(
          id: 's1',
          name: 'George Popescu', // Sf. Gheorghe is 04-23 (3 days ahead)
          email: 'george@test.com',
          cui: '5020421123456', // Birthday is 04-21 (1 day ahead, turning 24)
        ),
        const StudentModel(
          id: 's2',
          name: 'Andrei Ionescu', // Sf. Andrei is 11-30 (far ahead)
          email: 'andrei@test.com',
          cui: '1950420123456', // Birthday is 04-20 (TODAY, turning 31)
        ),
        const StudentModel(
          id: 's3',
          name: 'Lăcrămioara Radu', // Floriile in 2026 was 04-05 (past)
          email: 'lacra@test.com',
          cui: '6000510123456', // Birthday 05-10 (outside 7 day window)
        ),
      ];

      final celebrations = CelebrationService.getUpcomingCelebrations(
        students,
        daysAhead: 7,
        asOf: refDate,
      );

      // We expect:
      // 1. Andrei Ionescu Birthday Today (daysUntil: 0)
      // 2. George Popescu Birthday Tomorrow (daysUntil: 1)
      // 3. George Popescu Name Day (Sfântul Gheorghe) in 3 days (daysUntil: 3)
      expect(celebrations.length, equals(3));

      expect(celebrations[0].student.name, equals('Andrei Ionescu'));
      expect(celebrations[0].type, equals(CelebrationType.birthday));
      expect(celebrations[0].daysUntil, equals(0));
      expect(celebrations[0].isToday, isTrue);
      expect(celebrations[0].age, equals(31));

      expect(celebrations[1].student.name, equals('George Popescu'));
      expect(celebrations[1].type, equals(CelebrationType.birthday));
      expect(celebrations[1].daysUntil, equals(1));
      expect(celebrations[1].isTomorrow, isTrue);
      expect(celebrations[1].age, equals(24));

      expect(celebrations[2].student.name, equals('George Popescu'));
      expect(celebrations[2].type, equals(CelebrationType.nameDay));
      expect(celebrations[2].title, equals('Sfântul Gheorghe'));
      expect(celebrations[2].daysUntil, equals(3));
    });

    test('getPreferredFirstName correctly identifies first name in both First-Last and Last-First Romanian formats', () {
      // Last-First with hyphenated name and matched holiday token
      expect(
        CelebrationService.getPreferredFirstName(
          'Bălan Lorena-Dumitrița',
          matchedToken: 'dumitrita',
        ),
        equals('Dumitrița'),
      );

      // Last-First birthday (no matched holiday token)
      expect(
        CelebrationService.getPreferredFirstName('Bălan Lorena-Dumitrița'),
        equals('Lorena'),
      );

      // Multi-name Last-First
      expect(
        CelebrationService.getPreferredFirstName(
          'Davidolu Cătălina Florentina',
          matchedToken: 'florentina',
        ),
        equals('Florentina'),
      );

      expect(
        CelebrationService.getPreferredFirstName('Davidolu Cătălina Florentina'),
        equals('Cătălina'),
      );

      // First-Last
      expect(
        CelebrationService.getPreferredFirstName('George Datcu'),
        equals('George'),
      );

      // Last-First hyphenated
      expect(
        CelebrationService.getPreferredFirstName(
          'Pleșa Sorin-Constantin',
          matchedToken: 'constantin',
        ),
        equals('Constantin'),
      );
    });

    test('generateGreetingMessage produces polite, natural personalized messages with first name', () {
      final student = const StudentModel(
        id: 's1',
        name: 'Bălan Lorena-Dumitrița',
        email: 'balan@test.com',
      );

      final bdayEvent = CelebrationEvent(
        student: student,
        type: CelebrationType.birthday,
        date: DateTime(2026, 8, 15),
        title: 'Zi de Naștere (25 ani)',
        daysUntil: 0,
      );
      final bdayMsg = CelebrationService.generateGreetingMessage(bdayEvent);
      expect(bdayMsg, contains('Lorena! 🎂🎉'));
      expect(bdayMsg, isNot(contains('Bălan')));

      final nameDayEvent = CelebrationEvent(
        student: student,
        type: CelebrationType.nameDay,
        date: DateTime(2026, 10, 26),
        title: 'Sfântul Dumitru',
        daysUntil: 0,
        matchedToken: 'dumitrita',
      );
      final nameDayMsg = CelebrationService.generateGreetingMessage(nameDayEvent);
      expect(nameDayMsg, equals('La mulți ani de Sfântul Dumitru, Dumitrița! 🎉 Să ai o zi deosebită, plină de bucurii și mult succes în tot ce faci! 🚀'));
      expect(nameDayMsg, isNot(contains('Bălan')));
    });
  });
}

