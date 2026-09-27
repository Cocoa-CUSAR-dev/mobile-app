import 'package:cocoa_supply/models/profile_model.dart';
import 'package:cocoa_supply/route.dart';
import 'package:cocoa_supply/services/profile_service.dart';
import 'package:flutter/material.dart';
import 'package:cocoa_supply/theme/app_colors.dart';
import 'package:cocoa_supply/theme/app_text_theme.dart';
import 'package:cocoa_supply/widgets/components/empty_state_view.dart';
import 'package:cocoa_supply/widgets/components/tree_dot_loading.dart';

class RootScaffold extends StatefulWidget {
  final String title;
  final List<Widget> children;
  final int currentIndex;
  final ValueChanged<int> onItemSelected;
  final Color? backgroundColor;

  final AuthService? authService;

  const RootScaffold({
    super.key,
    required this.title,
    required this.children,
    required this.currentIndex,
    required this.onItemSelected,
    this.backgroundColor,
    this.authService,
  });

  @override
  State<RootScaffold> createState() => _RootScaffoldState();
}

class _RootScaffoldState extends State<RootScaffold> {
  late PageController _pageController;
  Profile? _userProfile;
  late final AuthService _authService = widget.authService ?? AuthService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Real page count depends on the profile's roles, which aren't known
    // yet here -- page 0 is always safe. _fetchProfile() below replaces
    // this with a correctly-bounded controller once roles are known,
    // before the PageView/BottomNavigationBar ever get built with them.
    _pageController = PageController();
    _fetchProfile();
  }

  // Mirrors the role -> nav-item filtering in build() below (home + one
  // item per matched role) -- kept in sync deliberately so this and build()
  // never disagree about how many tabs there really are.
  int _navItemCount(List<String> roles) {
    var count = 1;
    if (roles.contains('farmer')) count++;
    if (roles.contains('processor')) count++;
    if (roles.contains('hub_collector')) count++;
    return count;
  }

  // int.clamp(int, int) returns num, not int (it's inherited from num) --
  // a plain helper avoids needing a .toInt() at every call site.
  int _clampIndex(int index, int itemCount) {
    if (index < 0) return 0;
    if (index >= itemCount) return itemCount - 1;
    return index;
  }

  Future<void> _fetchProfile() async {
    try {
      final profile = await _authService.getProfile();
      if (mounted) {
        // widget.currentIndex was chosen against a stale/different tab
        // count (e.g. a previous session's role set, or simply the
        // fixed 4-tab index HomeBloc tracks) -- clamp it against the
        // *actual* number of tabs this profile's roles produce before
        // ever handing it to PageController/BottomNavigationBar, both of
        // which assert currentIndex/initialPage < item count.
        final itemCount = _navItemCount(profile?.roles ?? []);
        final effectiveIndex = _clampIndex(widget.currentIndex, itemCount);
        _pageController.dispose();
        setState(() {
          _userProfile = profile;
          _isLoading = false;
          _pageController = PageController(initialPage: effectiveIndex);
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    // ปิด Bottom Sheet ก่อนถ้าเปิดอยู่
    Navigator.pop(context); 
    await _authService.logout();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoute.login,
        (route) => false,
      );
    }
  }

  // ฟังก์ชันสำหรับแสดง Pop-up โปรไฟล์
  void _showProfileBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // เพื่อให้กำหนดความสูงได้ตามเนื้อหา
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // ขนาดตามเนื้อหา
          children: [
            // แถบขีดด้านบนเพื่อให้รู้ว่ารูดลงได้
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            _buildProfileContent(),
          ],
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(RootScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex && !_isLoading) {
      final itemCount = _navItemCount(_userProfile?.roles ?? []);
      _pageController.jumpToPage(_clampIndex(widget.currentIndex, itemCount));
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: ThreeDotsLoading()),
      );
    }

    final roles = _userProfile?.roles ?? [];
    final List<Widget> filteredPages = [widget.children[0]];
    final List<BottomNavigationBarItem> navItems = [
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'หน้าหลัก'),
    ];

    if (roles.contains('farmer')) {
      navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.park), label: 'ฟาร์ม'));
      if (widget.children.length > 1) filteredPages.add(widget.children[1]);
    }
    if (roles.contains('processor')) {
      navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.factory), label: 'แปรรูป'));
      if (widget.children.length > 2) filteredPages.add(widget.children[2]);
    }
    if (roles.contains('hub_collector')) {
      navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.person_pin_circle), label: 'รวบรวม'));
      if (widget.children.length > 3) filteredPages.add(widget.children[3]);
    }

    // Belt-and-suspenders: _fetchProfile() already reconstructs
    // _pageController with a bounded initialPage, but BottomNavigationBar
    // reads widget.currentIndex directly every build, so it needs its own
    // clamp against whatever navItems this build actually produced.
    final effectiveIndex = _clampIndex(widget.currentIndex, navItems.length);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title, 
          style: const TextStyle(color: Colors.white)
        ),
        toolbarHeight: 64,
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.white, size: 42.0),
            onPressed: _showProfileBottomSheet, // เปลี่ยนเป็นเปิด Pop-up
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: filteredPages,
      ),
      backgroundColor: widget.backgroundColor ?? AppColors.surface,
      bottomNavigationBar: navItems.length < 2
          ? null
          : BottomNavigationBar(
              currentIndex: effectiveIndex,
              onTap: (index) {
                widget.onItemSelected(index);
                _pageController.jumpToPage(index);
              },
              selectedItemColor: AppColors.primary,
              unselectedItemColor: Colors.grey,
              type: BottomNavigationBarType.fixed,
              items: navItems,
            ),
    );
  }

  // เนื้อหาภายใน Profile (ปรับให้เข้ากับ Pop-up)
  Widget _buildProfileContent() {
    if (_userProfile == null) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: EmptyStateView(icon: Icons.person_off_outlined, message: "ไม่พบข้อมูล"),
      );
    }

    return Flexible(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 24),

            _buildInfoCard(
              icon: Icons.contact_phone_outlined,
              title: "ข้อมูลติดต่อ",
              rows: [
                _infoRow(Icons.phone_outlined, "เบอร์โทร", _userProfile!.phoneNumber),
                _infoRow(Icons.chat_bubble_outline, "Line", _userProfile!.line),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.location_on_outlined,
              title: "ที่อยู่",
              rows: [
                _infoRow(null, "ตำบล", _userProfile!.subdistrictName),
                _infoRow(null, "อำเภอ", _userProfile!.districtName),
                _infoRow(null, "จังหวัด", "${_userProfile!.provinceName} ${_userProfile!.zipCode}"),
              ],
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout, color: Colors.red, size: 20),
                label: Text("ออกจากระบบ", style: AppTextTheme.scale.titleSmall?.copyWith(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final roleLabel = _userProfile!.roles?.join(', ') ?? 'ทั่วไป';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.primaryFaint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const CircleAvatar(
              radius: 42,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 48, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _userProfile!.firstName ?? "ไม่ระบุชื่อ",
            style: AppTextTheme.scale.titleLarge,
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "บทบาท: $roleLabel",
              style: AppTextTheme.scale.labelMedium?.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String title, required List<Widget> rows}) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shadowColor: Colors.black26,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(title, style: AppTextTheme.scale.titleSmall),
              ],
            ),
            const Divider(height: 24),
            for (int i = 0; i < rows.length; i++) ...[
              if (i > 0) const Divider(height: 20, color: Color(0xFFF0F0F0)),
              rows[i],
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData? icon, String label, String? value) {
    return Row(
      children: [
        if (icon != null) Icon(icon, size: 18, color: AppColors.primary),
        if (icon != null) const SizedBox(width: 10),
        Text(label, style: AppTextTheme.scale.bodyMedium?.copyWith(color: Colors.grey.shade600)),
        const Spacer(),
        Text(value ?? "-", style: AppTextTheme.scale.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}