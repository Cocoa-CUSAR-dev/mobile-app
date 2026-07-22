class UtilService{
  UtilService();
  static String formatThaiDate(DateTime date) {
    final List<String> months = [
      'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
      'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year + 543}';
  }
}