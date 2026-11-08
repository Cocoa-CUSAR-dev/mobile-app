// The roles a person can hold, and how the app names them in Thai. One place
// so the role page, the bottom tabs and the profile sheet agree.

/// Roles a person adds themselves in the app, in the order they are shown
/// and saved. Researcher and admin are not added here (researcher signs up
/// on the web with a code; admin is given by an admin).
const List<String> selfServiceRoles = ['farmer', 'hub_collector', 'processor'];

const Map<String, String> roleLabels = {
  'farmer': 'เกษตรกร',
  'hub_collector': 'ผู้รวบรวม',
  'processor': 'ผู้แปรรูป',
  'researcher': 'นักวิจัย',
  'admin': 'ผู้ดูแลระบบ',
};

/// The Thai name of [role], or the role itself for one the app doesn't know.
String roleLabel(String role) => roleLabels[role] ?? role;
