import '../../features/students/models/student_model.dart';

enum CelebrationType {
  birthday,
  nameDay,
}

class CelebrationEvent {
  final StudentModel student;
  final CelebrationType type;
  final DateTime date;
  final String title;
  final int? age;
  final int daysUntil;
  final String? matchedToken;

  const CelebrationEvent({
    required this.student,
    required this.type,
    required this.date,
    required this.title,
    this.age,
    required this.daysUntil,
    this.matchedToken,
  });

  bool get isToday => daysUntil == 0;
  bool get isTomorrow => daysUntil == 1;

  String get relativeLabel {
    if (isToday) return 'Astăzi';
    if (isTomorrow) return 'Mâine';
    return 'în $daysUntil zile';
  }
}


class CelebrationService {
  /// Map of fixed Romanian Orthodox name days (MM-DD format).
  static const Map<String, Map<String, dynamic>> fixedHolidays = {
    '01-01': {
      'holiday': 'Sfântul Vasile',
      'names': ['Vasile', 'Vasilica', 'Sile', 'Vasilică'],
    },
    '01-07': {
      'holiday': 'Sfântul Ioan Botezătorul',
      'names': [
        'Ion',
        'Ioan',
        'Ioana',
        'Ionela',
        'Ionuț',
        'Nelu',
        'Ionel',
        'Nela',
        'Oana'
      ],
    },
    '04-23': {
      'holiday': 'Sfântul Gheorghe',
      'names': [
        'Gheorghe',
        'George',
        'Georgiana',
        'Georgeta',
        'Geta',
        'Gigi',
        'Gicu',
        'Ghiță'
      ],
    },
    '05-21': {
      'holiday': 'Sfinții Constantin și Elena',
      'names': [
        'Constantin',
        'Elena',
        'Costel',
        'Costică',
        'Ileana',
        'Lenuța',
        'Nuți',
        'Costin',
        'Codin',
        'Ilinca'
      ],
    },
    '06-29': {
      'holiday': 'Sfinții Petru și Pavel',
      'names': [
        'Petru',
        'Petre',
        'Pavel',
        'Paul',
        'Paula',
        'Petronela',
        'Păvălaș'
      ],
    },
    '07-20': {
      'holiday': 'Sfântul Ilie',
      'names': ['Ilie', 'Ilinca', 'Lică', 'Iliuță'],
    },
    '08-15': {
      'holiday': 'Sfânta Maria (Adormirea)',
      'names': [
        'Maria',
        'Marian',
        'Mariana',
        'Măriuca',
        'Maricica',
        'Mia',
        'Mărioara'
      ],
    },
    '09-08': {
      'holiday': 'Sfânta Maria (Nașterea)',
      'names': [
        'Maria',
        'Marian',
        'Mariana',
        'Măriuca',
        'Maricica',
        'Mia',
        'Mărioara'
      ],
    },
    '10-26': {
      'holiday': 'Sfântul Dumitru',
      'names': ['Dumitru', 'Dumitrița', 'Mitică', 'Dima', 'Dumitra'],
    },
    '11-08': {
      'holiday': 'Sfinții Mihail și Gavriil',
      'names': [
        'Mihai',
        'Mihail',
        'Mihaela',
        'Gabriel',
        'Gabriela',
        'Gabi',
        'Mihăiță',
        'Mișu'
      ],
    },
    '11-30': {
      'holiday': 'Sfântul Andrei',
      'names': ['Andrei', 'Andreea', 'Andra', 'Andrada', 'Andrieș'],
    },
    '12-06': {
      'holiday': 'Sfântul Nicolae',
      'names': [
        'Nicolae',
        'Nicoleta',
        'Nicu',
        'Nicușor',
        'Nae',
        'Lae',
        'Niculina'
      ],
    },
    '12-27': {
      'holiday': 'Sfântul Ștefan',
      'names': ['Ștefan', 'Ștefania', 'Fane', 'Ștefănel', 'Ștefănuț', 'Fănica'],
    },
  };

  static const List<String> floriiNames = [
    'Florin',
    'Florina',
    'Florentina',
    'Viorel',
    'Viorica',
    'Crina',
    'Margareta',
    'Lăcrămioara',
    'Camelia',
  ];

  /// Extracts the exact birth date from a 13-digit Romanian CNP.
  /// Returns null if the CNP is missing or invalid.
  static DateTime? parseCnpBirthDate(String? cnp) {
    if (cnp == null) return null;
    final clean = cnp.replaceAll(RegExp(r'\D'), '');
    if (clean.length != 13) return null;

    final s = int.tryParse(clean[0]);
    final aa = int.tryParse(clean.substring(1, 3));
    final ll = int.tryParse(clean.substring(3, 5));
    final zz = int.tryParse(clean.substring(5, 7));

    if (s == null || aa == null || ll == null || zz == null) return null;
    if (ll < 1 || ll > 12 || zz < 1 || zz > 31) return null;

    int century;
    switch (s) {
      case 1:
      case 2:
      case 7:
      case 8:
      case 9:
        century = 1900;
        break;
      case 3:
      case 4:
        century = 1800;
        break;
      case 5:
      case 6:
        century = 2000;
        break;
      default:
        return null;
    }

    final year = century + aa;
    try {
      final date = DateTime(year, ll, zz);
      // Validate that date didn't overflow (e.g. Feb 30 becoming March 2)
      if (date.year == year && date.month == ll && date.day == zz) {
        return date;
      }
    } catch (_) {}
    return null;
  }

  /// Calculates the person's age on a given reference date (defaults to today).
  static int calculateAge(DateTime birthDate, {DateTime? asOf}) {
    final ref = asOf ?? DateTime.now();
    int age = ref.year - birthDate.year;
    if (ref.month < birthDate.month ||
        (ref.month == birthDate.month && ref.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  /// Calculates Orthodox Easter (Pascha) in the Gregorian calendar for a given year.
  /// Uses Meeus's Julian computus converted to Gregorian (+13 days for 1900-2099).
  static DateTime getOrthodoxEaster(int year) {
    final a = year % 4;
    final b = year % 7;
    final c = year % 19;
    final d = (19 * c + 15) % 30;
    final e = (2 * a + 4 * b - d + 34) % 7;

    final julianMonth = ((d + e + 114) ~/ 31);
    final julianDay = ((d + e + 114) % 31) + 1;

    // Convert Julian date to Gregorian (+13 days for 20th and 21st centuries)
    final julianEaster = DateTime(year, julianMonth, julianDay);
    return julianEaster.add(const Duration(days: 13));
  }

  /// Calculates Floriile (Palm Sunday) date for a given year (Orthodox Easter minus 7 days).
  static DateTime getFloriileDate(int year) {
    final easter = getOrthodoxEaster(year);
    return easter.subtract(const Duration(days: 7));
  }

  /// Normalizes a name string by converting to lowercase and stripping Romanian diacritics.
  static String normalizeName(String name) {
    return name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[ăâ]'), 'a')
        .replaceAll(RegExp(r'[î]'), 'i')
        .replaceAll(RegExp(r'[șş]'), 's')
        .replaceAll(RegExp(r'[țţ]'), 't');
  }

  /// Extracts individual normalized name tokens from a student's full name.
  static List<String> extractNameTokens(String fullName) {
    return fullName
        .split(RegExp(r'[\s\-/,.:;()\[\]{}"\x27]+'))
        .where((token) => token.trim().isNotEmpty)
        .map((token) => normalizeName(token))
        .toList();
  }


  /// Returns all holidays for a given year, including fixed dates and dynamic Floriile.
  static List<Map<String, dynamic>> getAllHolidaysForYear(int year) {
    final list = <Map<String, dynamic>>[];

    // Fixed holidays
    fixedHolidays.forEach((key, val) {
      final parts = key.split('-');
      final month = int.parse(parts[0]);
      final day = int.parse(parts[1]);
      list.add({
        'date': DateTime(year, month, day),
        'holiday': val['holiday'] as String,
        'names': (val['names'] as List<String>),
      });
    });

    // Dynamic Floriile
    final floriiDate = getFloriileDate(year);
    list.add({
      'date': DateTime(year, floriiDate.month, floriiDate.day),
      'holiday': 'Floriile',
      'names': floriiNames,
    });

    return list;
  }

  /// Evaluates all students and returns all celebrations occurring within [daysAhead] days from [asOf].
  /// Default window is 7 days.
  static List<CelebrationEvent> getUpcomingCelebrations(
    List<StudentModel> students, {
    int daysAhead = 7,
    DateTime? asOf,
  }) {
    final now = asOf ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final celebrations = <CelebrationEvent>[];

    // Check holidays for this year and next year (in case the window spans across Dec -> Jan)
    final holidaysThisYear = getAllHolidaysForYear(today.year);
    final holidaysNextYear = getAllHolidaysForYear(today.year + 1);
    final allHolidays = [...holidaysThisYear, ...holidaysNextYear];

    for (final student in students) {
      if (student.clientType != 'PF') continue;
      final tokens = extractNameTokens(student.name);


      // 1. Check Birthdays (from CNP in cui / contract)
      if (student.cui != null && student.cui!.isNotEmpty) {
        final birthDate = parseCnpBirthDate(student.cui);
        if (birthDate != null) {
          // Check this year's birthday
          var nextBirthday = DateTime(today.year, birthDate.month, birthDate.day);
          if (nextBirthday.isBefore(today)) {
            nextBirthday = DateTime(today.year + 1, birthDate.month, birthDate.day);
          }

          final diffDays = nextBirthday.difference(today).inDays;
          if (diffDays >= 0 && diffDays <= daysAhead) {
            final ageTurning = nextBirthday.year - birthDate.year;
            celebrations.add(CelebrationEvent(
              student: student,
              type: CelebrationType.birthday,
              date: nextBirthday,
              title: 'Zi de Naștere ($ageTurning ani)',
              age: ageTurning,
              daysUntil: diffDays,
            ));
          }
        }
      }

      // 2. Check Name Days (Onomastică)
      for (final h in allHolidays) {
        final holidayDate = h['date'] as DateTime;
        final diffDays = holidayDate.difference(today).inDays;
        if (diffDays < 0 || diffDays > daysAhead) continue;

        final holidayNames = (h['names'] as List<String>)
            .map((n) => normalizeName(n))
            .toSet();

        String? matched;
        for (final t in tokens) {
          if (holidayNames.contains(t)) {
            matched = t;
            break;
          }
        }

        if (matched != null) {
          celebrations.add(CelebrationEvent(
            student: student,
            type: CelebrationType.nameDay,
            date: holidayDate,
            title: h['holiday'] as String,
            daysUntil: diffDays,
            matchedToken: matched,
          ));
        }
      }
    }

    // Sort by days until celebration ascending, then by student name
    celebrations.sort((a, b) {
      final comp = a.daysUntil.compareTo(b.daysUntil);
      if (comp != 0) return comp;
      return a.student.name.compareTo(b.student.name);
    });

    return celebrations;
  }

  /// Extracts the most appropriate first name from a Romanian full name.
  /// If [matchedToken] is provided (e.g. for Name Days), finds the corresponding casing in the name.
  static String getPreferredFirstName(String fullName, {String? matchedToken}) {
    final clean = fullName.trim();
    if (clean.isEmpty) return 'Cursant';

    final rawTokens = clean
        .split(RegExp(r'[\s/,.:;()\[\]{}"]+'))
        .where((t) => t.isNotEmpty)
        .toList();
    if (rawTokens.isEmpty) return clean;
    if (rawTokens.length == 1) return rawTokens.first;

    // 1. If a specific holiday name token was matched (e.g. "dumitrita" in "Bălan Lorena-Dumitrița")
    if (matchedToken != null && matchedToken.isNotEmpty) {
      final normTarget = normalizeName(matchedToken);
      for (final raw in rawTokens) {
        if (normalizeName(raw) == normTarget) {
          return raw;
        }
        final subparts = raw.split('-');
        for (final sub in subparts) {
          if (normalizeName(sub) == normTarget) {
            return sub;
          }
        }
      }
    }

    // 2. Common Romanian first names database
    const commonFirstNames = {
      'andrei', 'andreea', 'alexandru', 'alexandra', 'alex', 'alina', 'alin', 'ana', 'anca', 'antonia',
      'bogdan', 'bianca', 'catalin', 'catalina', 'cristian', 'cristina', 'cosmin', 'constantin', 'corina', 'claudiu', 'claudia',
      'dan', 'dana', 'daniel', 'daniela', 'dorin', 'dorina', 'dumitru', 'dumitrita', 'diana', 'denisa',
      'elena', 'emanuel', 'emilia', 'eugen', 'eugenia',
      'florin', 'florina', 'florentina', 'florinela',
      'george', 'gheorghe', 'georgiana', 'georgeta', 'gabriel', 'gabriela', 'gabi',
      'ioan', 'ion', 'ioana', 'ionut', 'ionela', 'ilie', 'ilinca', 'irina', 'iulia', 'iulian',
      'laura', 'laurentiu', 'liviu', 'lorena', 'larisa', 'lucian', 'luciana',
      'marian', 'mariana', 'maria', 'marius', 'mihai', 'mihail', 'mihaela', 'mircea', 'monica', 'madalina',
      'nicolae', 'nicoleta', 'nicu', 'nicusor',
      'oana', 'octavian', 'ovidiu',
      'paul', 'paula', 'petru', 'petre', 'pavel',
      'radu', 'raluca', 'razvan', 'robert', 'roberta', 'roxana', 'ruxandra',
      'sorin', 'sorina', 'stefan', 'stefania', 'simona', 'silviu',
      'tudor', 'teodor', 'teodora', 'tiberiu',
      'valentin', 'valentina', 'vasile', 'vasilica', 'victor', 'victoria', 'vlad', 'viorel', 'viorica'
    };

    // Check if the 1st word is a known first name (e.g. "George Datcu" -> "George")
    final firstWord = rawTokens.first;
    final firstWordNorm = normalizeName(firstWord.split('-').first);
    if (commonFirstNames.contains(firstWordNorm)) {
      return firstWord.split('-').first;
    }

    // Check subsequent words for first names (e.g. "Bălan Lorena-Dumitrița" -> "Lorena")
    for (int i = 1; i < rawTokens.length; i++) {
      final token = rawTokens[i];
      final tokenNorm = normalizeName(token.split('-').first);
      if (commonFirstNames.contains(tokenNorm)) {
        return token.split('-').first;
      }
    }

    // If hyphenated token found after index 0 (e.g. "Pleșa Sorin-Constantin" -> "Sorin")
    for (int i = 1; i < rawTokens.length; i++) {
      if (rawTokens[i].contains('-')) {
        return rawTokens[i].split('-').first;
      }
    }

    // Fallback: If 2 words in Romanian official order [Lastname Firstname], return 2nd word
    if (rawTokens.length >= 2) {
      return rawTokens[1].split('-').first;
    }

    return rawTokens.first.split('-').first;
  }


  /// Generates a friendly, natural WhatsApp congratulations message for the student.
  static String generateGreetingMessage(CelebrationEvent event) {
    final firstName = getPreferredFirstName(
      event.student.name,
      matchedToken: event.matchedToken,
    );

    if (event.type == CelebrationType.birthday) {
      return 'La mulți ani cu sănătate și bucurii, $firstName! 🎂🎉 Îți dorim o zi minunată și mult succes în continuare! 🚀';
    } else {
      String holidayPhrase = event.title;
      final lower = holidayPhrase.toLowerCase();
      if (lower.startsWith('sfântul ') ||
          lower.startsWith('sfânta ') ||
          lower.startsWith('sfinții ')) {
        holidayPhrase = 'de $holidayPhrase';
      } else if (lower.contains('floriile')) {
        holidayPhrase = 'de Florii';
      } else {
        holidayPhrase = 'de $holidayPhrase';
      }

      return 'La mulți ani $holidayPhrase, $firstName! 🎉 Să ai o zi deosebită, plină de bucurii și mult succes în tot ce faci! 🚀';
    }
  }
}

