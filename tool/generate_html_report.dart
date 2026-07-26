import 'dart:io';

void main() {
  final lcovFile = File('coverage/lcov.info');
  if (!lcovFile.existsSync()) {
    print('❌ Error: coverage/lcov.info not found. Please run "flutter test --coverage" first.');
    return;
  }

  final lines = lcovFile.readAsLinesSync();
  final List<_FileCoverage> fileList = [];

  _FileCoverage? currentFile;

  for (final line in lines) {
    if (line.startsWith('SF:')) {
      final path = line.substring(3).replaceAll('\\', '/');
      currentFile = _FileCoverage(path);
      fileList.add(currentFile);
    } else if (line.startsWith('DA:') && currentFile != null) {
      final parts = line.substring(3).split(',');
      if (parts.length >= 2) {
        final lineNum = int.tryParse(parts[0]) ?? 0;
        final hitCount = int.tryParse(parts[1]) ?? 0;
        currentFile.lineHits[lineNum] = hitCount;
      }
    } else if (line.startsWith('LF:') && currentFile != null) {
      currentFile.linesFound = int.tryParse(line.substring(3)) ?? 0;
    } else if (line.startsWith('LH:') && currentFile != null) {
      currentFile.linesHit = int.tryParse(line.substring(3)) ?? 0;
    }
  }

  // Filter for lib/ directory files
  final libFiles = fileList.where((f) => f.path.contains('lib/') && !f.path.endsWith('.g.dart')).toList();
  libFiles.sort((a, b) => b.percentage.compareTo(a.percentage));

  int totalFound = 0;
  int totalHit = 0;
  for (final f in libFiles) {
    totalFound += f.linesFound;
    totalHit += f.linesHit;
  }

  final overallPct = totalFound > 0 ? (totalHit / totalFound) * 100 : 0.0;

  final htmlContent = '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Agreemint Code Coverage Report</title>
  <style>
    :root {
      --bg: #0f172a;
      --card-bg: #1e293b;
      --text: #f8fafc;
      --text-muted: #94a3b8;
      --border: #334155;
      --primary: #8b5cf6;
      --green: #22c55e;
      --yellow: #eab308;
      --red: #ef4444;
    }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      background-color: var(--bg);
      color: var(--text);
      margin: 0;
      padding: 32px 16px;
    }
    .container {
      max-width: 1000px;
      margin: 0 auto;
    }
    .header {
      background: var(--card-bg);
      padding: 24px;
      border-radius: 12px;
      border: 1px solid var(--border);
      margin-bottom: 24px;
      display: flex;
      justify-content: space-between;
      align-items: center;
    }
    h1 { margin: 0; font-size: 24px; color: var(--text); }
    .subtitle { color: var(--text-muted); font-size: 14px; margin-top: 4px; }
    .badge {
      padding: 8px 16px;
      border-radius: 20px;
      font-weight: bold;
      font-size: 18px;
    }
    .badge-green { background: rgba(34, 197, 94, 0.2); color: var(--green); border: 1px solid var(--green); }
    .badge-yellow { background: rgba(234, 179, 8, 0.2); color: var(--yellow); border: 1px solid var(--yellow); }
    .badge-red { background: rgba(239, 68, 68, 0.2); color: var(--red); border: 1px solid var(--red); }
    table {
      width: 100%;
      border-collapse: collapse;
      background: var(--card-bg);
      border-radius: 12px;
      overflow: hidden;
      border: 1px solid var(--border);
    }
    th, td {
      padding: 14px 16px;
      text-align: left;
      border-bottom: 1px solid var(--border);
    }
    th {
      background: #111827;
      color: var(--text-muted);
      font-size: 12px;
      text-transform: uppercase;
      letter-spacing: 0.05em;
    }
    tr:last-child td { border-bottom: none; }
    .file-path { font-family: monospace; font-size: 13px; color: #cbd5e1; }
    .progress-bar-bg {
      background: #334155;
      height: 8px;
      border-radius: 4px;
      overflow: hidden;
      width: 120px;
      display: inline-block;
      vertical-align: middle;
      margin-right: 10px;
    }
    .progress-bar-fill { height: 100%; border-radius: 4px; }
    .fill-green { background: var(--green); }
    .fill-yellow { background: var(--yellow); }
    .fill-red { background: var(--red); }
    .pct-label { font-weight: 600; font-size: 13px; display: inline-block; width: 48px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div>
        <h1>🎯 Agreemint Code Coverage Report</h1>
        <div class="subtitle">Generated dynamically from <code>coverage/lcov.info</code></div>
      </div>
      <div class="badge ${overallPct >= 80 ? 'badge-green' : (overallPct >= 50 ? 'badge-yellow' : 'badge-red')}">
        ${overallPct.toStringAsFixed(1)}% Line Coverage
      </div>
    </div>

    <table>
      <thead>
        <tr>
          <th>File Path</th>
          <th>Coverage %</th>
          <th>Lines Hit / Found</th>
        </tr>
      </thead>
      <tbody>
        ${libFiles.map((f) => '''
        <tr>
          <td class="file-path">${f.displayPath}</td>
          <td>
            <div class="progress-bar-bg">
              <div class="progress-bar-fill ${f.colorClass}" style="width: ${f.percentage}%;"></div>
            </div>
            <span class="pct-label">${f.percentage.toStringAsFixed(1)}%</span>
          </td>
          <td style="color: var(--text-muted); font-size: 13px;">${f.linesHit} / ${f.linesFound}</td>
        </tr>
        ''').join('\n')}
      </tbody>
    </table>
  </div>
</body>
</html>
''';

  final outputDir = Directory('coverage/html');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  final outputFile = File('coverage/html/index.html');
  outputFile.writeAsStringSync(htmlContent);

  print('✅ Coverage HTML Report generated successfully!');
  print('📄 Report Path: ${outputFile.absolute.path}');
}

class _FileCoverage {
  final String path;
  int linesFound = 0;
  int linesHit = 0;
  final Map<int, int> lineHits = {};

  _FileCoverage(this.path);

  String get displayPath {
    final idx = path.indexOf('lib/');
    return idx != -1 ? path.substring(idx) : path;
  }

  double get percentage => linesFound > 0 ? (linesHit / linesFound) * 100 : 0.0;

  String get colorClass {
    if (percentage >= 80) return 'fill-green';
    if (percentage >= 40) return 'fill-yellow';
    return 'fill-red';
  }
}
