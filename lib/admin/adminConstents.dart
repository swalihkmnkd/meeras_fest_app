/// Shared dropdown / chip options used across the admin add & edit forms.

/// Ordered class list used for a Category's class range (from -> to).
const List<String> kClassOptions = [
  'LKG',
  'UKG',
  '1',
  '2',
  '3',
  '4',
  '5',
  '6',
  '7',
  '8',
  '9',
  '10',
  '11',
  '12',
];

/// Gender / section options reused by Category, Program, and Team forms.
const List<String> kGenderOptions = ['Boys', 'Girls', 'Mixed'];

/// Returns true if [from] comes at or before [to] in kClassOptions order.
bool isClassRangeInOrder(String from, String to) {
  final fromIndex = kClassOptions.indexOf(from);
  final toIndex = kClassOptions.indexOf(to);
  if (fromIndex == -1 || toIndex == -1) return false;
  return fromIndex <= toIndex;
}