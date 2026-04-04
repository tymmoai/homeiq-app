const scanner = require('sonarqube-scanner').default;

const scannerConfig = {
  serverUrl: 'http://localhost:9000',
  token: 'sqp_01b80b600e90474b1d9cd92423f02031763ff686',
  options: {
    'sonar.projectKey': 'homeiq-flutter-app',
    'sonar.projectName': 'HomeIQ Flutter App',
    'sonar.projectVersion': '1.0',
    'sonar.sources': 'lib',
    'sonar.tests': 'test,integration_test',
    'sonar.test.inclusions': '**/*_test.dart,**/*_spec.dart',
    'sonar.exclusions': '**/*.g.dart,**/*.freezed.dart,**/*.config.dart,build/**,coverage/**,.dart_tool/**',
    'sonar.sourceEncoding': 'UTF-8',
    'sonar.dart.coverage.reportPath': 'coverage/lcov.info'
  }
};

scanner(scannerConfig, () => {
  console.log('\nFlutter app SonarQube scan completed!');
  console.log('View results at: http://localhost:9000/dashboard?id=homeiq-flutter-app');
  process.exit(0);
});
