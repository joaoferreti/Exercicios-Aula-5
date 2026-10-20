Future<String> reportUserRole() async {
  final role = await fetchRole();
  return 'User role: $role';
}

Future<String> reportLogins() async {
  final logins = await fetchLoginAmount();
  return 'Total number of logins: $logins';
}

Future<String> fetchRole() => Future.delayed(_halfSecond, () => _role);
Future<int> fetchLoginAmount() => Future.delayed(_halfSecond, () => _logins);

const _role = 'administrator';
const _logins = 42;
const _halfSecond = Duration(milliseconds: 500);

void main() async {
  print(await reportUserRole());
  print(await reportLogins());
}
