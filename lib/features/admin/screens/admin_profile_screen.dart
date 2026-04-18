import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Breakpoints
//   • mobile  : w < 600
//   • tablet  : 600 ≤ w < 1000
//   • desktop : w ≥ 1000   → left panel (320) + right content (flex)
// ─────────────────────────────────────────────────────────────────────────────

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen>
    with TickerProviderStateMixin {
  // ── Design tokens ──────────────────────────────────────────────────────
  static const _bg = Color(0xFF080C14);
  static const _surface = Color(0xFF0F1623);
  static const _card = Color(0xFF131B2E);
  //  static const _cardHover = Color(0xFF18233A);
  static const _panel = Color(0xFF0D1424); // sidebar bg
  static const _border = Color(0xFF1E2D47);
  static const _divider = Color(0xFF152036);
  static const _accent = Color(0xFF4F8EF7);
  static const _accentSoft = Color(0x264F8EF7);
  static const _green = Color(0xFF22C55E);
  static const _greenSoft = Color(0x2222C55E);
  static const _red = Color(0xFFEF4444);
  static const _redSoft = Color(0x22EF4444);
  static const _amber = Color(0xFFF59E0B);
  static const _amberSoft = Color(0x22F59E0B);
  static const _purple = Color(0xFF8B5CF6);
  static const _purpleSoft = Color(0x228B5CF6);
  static const _white = Colors.white;
  static const _muted = Color(0xFF6B7A99);
  //static const _faint = Color(0xFF3A4A6B);
  static const _subtle = Color(0xFF1A2540);

  // ── State ──────────────────────────────────────────────────────────────
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  bool _loading = false;
  bool _showPassword = false;
  int _selectedTab = 0; // 0 Profile  1 Security  2 Activity

  List<Map<String, dynamic>> _activityLog = [];

  // notification toggles (real state this time)
  bool _notifOrders = true;
  bool _notifStock = true;
  bool _notifSignups = false;
  bool _notifDigest = true;
  bool _twoFA = false;
  bool _loginNotif = true;

  // ── Live Firestore stats ────────────────────────────────────────────────
  int _totalUsers = 0;
  int _activeToday = 0;
  int _pendingOrders = 0;
  double _systemHealth = 99.8;
  bool _statsLoading = true;

  // ── Sidebar nav items ──────────────────────────────────────────────────
  static const _navItems = [
    {"label": "Profile", "icon": Icons.person_outline_rounded},
    {"label": "Security", "icon": Icons.lock_outline_rounded},
    {"label": "Activity", "icon": Icons.history_rounded},
  ];

  static const _quickActions = [
    {
      "label": "Manage Users",
      "icon": Icons.manage_accounts_rounded,
      "color": _accent,
    },
    {"label": "View Reports", "icon": Icons.bar_chart_rounded, "color": _green},
    {"label": "System Logs", "icon": Icons.terminal_rounded, "color": _amber},
    {
      "label": "Notifications",
      "icon": Icons.notifications_active_rounded,
      "color": _purple,
    },
    {
      "label": "Backup & Export",
      "icon": Icons.cloud_upload_rounded,
      "color": _red,
    },
    {
      "label": "Settings",
      "icon": Icons.settings_suggest_rounded,
      "color": _muted,
    },
  ];

  // ── Lifecycle ──────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _nameCtrl.text = user?.displayName ?? "Admin";
    _emailCtrl.text = user?.email ?? "";
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    _loadStats();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Firestore ──────────────────────────────────────────────────────────
  Future<void> _loadStats() async {
    try {
      final db = FirebaseFirestore.instance;
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final results = await Future.wait([
        db.collection('users').count().get(),
        db
            .collection('users')
            .where(
              'lastSeen',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
            )
            .count()
            .get(),
        db
            .collection('orders')
            .where('status', isEqualTo: 'pending')
            .count()
            .get(),
      ]);
      if (!mounted) return;
      setState(() {
        _totalUsers = results[0].count ?? 0;
        _activeToday = results[1].count ?? 0;
        _pendingOrders = results[2].count ?? 0;
        _statsLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _statsLoading = false);
    }
  }

  List<Map<String, dynamic>> get _stats => [
    {
      "label": "Total Users",
      "value": _statsLoading ? "…" : _fmt(_totalUsers),
      "delta": "+12%",
      "up": true,
      "icon": Icons.people_alt_rounded,
      "color": _accent,
      "soft": _accentSoft,
    },
    {
      "label": "Active Today",
      "value": _statsLoading ? "…" : _fmt(_activeToday),
      "delta": "+5%",
      "up": true,
      "icon": Icons.online_prediction_rounded,
      "color": _green,
      "soft": _greenSoft,
    },
    {
      "label": "Pending Orders",
      "value": _statsLoading ? "…" : _pendingOrders.toString(),
      "delta": _pendingOrders > 10 ? "High" : "Normal",
      "up": _pendingOrders <= 10,
      "icon": Icons.warning_amber_rounded,
      "color": _amber,
      "soft": _amberSoft,
    },
    {
      "label": "System Health",
      "value": "${_systemHealth.toStringAsFixed(1)}%",
      "delta": "Stable",
      "up": true,
      "icon": Icons.monitor_heart_outlined,
      "color": _purple,
      "soft": _purpleSoft,
    },
  ];

  String _fmt(int n) =>
      n >= 1000 ? "${(n / 1000).toStringAsFixed(1)}k" : n.toString();

  // ── Update profile ─────────────────────────────────────────────────────
  void _log(String action, bool success) => setState(
    () => _activityLog.insert(0, {
      "action": action,
      "success": success,
      "time": DateTime.now(),
    }),
  );

  Future<void> _updateProfile() async {
    setState(() => _loading = true);
    bool ok = true;
    String summary = "";
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      if (_emailCtrl.text.trim() != user.email) {
        await user.updateEmail(_emailCtrl.text.trim());
        summary += "Email updated • ";
      }
      if (_passwordCtrl.text.trim().isNotEmpty) {
        await user.updatePassword(_passwordCtrl.text.trim());
        summary += "Password changed • ";
      }
      await user.updateDisplayName(_nameCtrl.text.trim());
      summary += "Display name saved";
      await user.reload();
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(_snackBar("Profile updated successfully", _green));
    } catch (e) {
      ok = false;
      summary = "Update failed: $e";
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(_snackBar(e.toString(), _red));
    }
    _log(summary, ok);
    if (mounted) setState(() => _loading = false);
  }

  SnackBar _snackBar(String msg, Color color) => SnackBar(
    content: Row(
      children: [
        Icon(
          color == _green ? Icons.check_circle_outline : Icons.error_outline,
          color: Colors.white,
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
      ],
    ),
    backgroundColor: color,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    margin: const EdgeInsets.all(16),
  );

  // ══════════════════════════════════════════════════════════════════════════
  //  ROOT BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final mobile = w < 600;
    final desktop = w >= 1000;

    return Container(
      color: _bg,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: desktop ? _buildDesktopLayout() : _buildMobileLayout(mobile),
      ),
    );
  }

  // ── Desktop: fixed left panel + scrollable right ───────────────────────
  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Left sidebar (fixed, full height) ─────────────────────────
        SizedBox(
          width: 260,
          child: Container(
            color: _panel,
            child: Column(
              children: [
                _buildSidebarHeader(),
                const SizedBox(height: 8),
                _buildSidebarNav(),
                const Spacer(),
                _buildSidebarFooter(),
              ],
            ),
          ),
        ),
        // ── Vertical divider ──────────────────────────────────────────
        Container(width: 1, color: _border),
        // ── Main content (scrollable) ─────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPageTitle(),
                const SizedBox(height: 24),
                _buildStatsGrid(false, cols: 4),
                const SizedBox(height: 24),
                // Two-column layout for main content
                _buildDesktopContentRow(),
                const SizedBox(height: 24),
                _buildQuickActions(false),
                const SizedBox(height: 24),
                _buildDangerZone(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Desktop: left col = tab content, right col = session/activity sidebar
  Widget _buildDesktopContentRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: tab bar + tab content
        Expanded(
          flex: 6,
          child: Column(
            children: [
              _buildTabBar(),
              const SizedBox(height: 16),
              if (_selectedTab == 0) _buildProfileTab(false),
              if (_selectedTab == 1) _buildSecurityTab(),
              if (_selectedTab == 2) _buildActivityTab(),
            ],
          ),
        ),
        const SizedBox(width: 20),
        // Right: always-visible summary panel
        SizedBox(
          width: 280,
          child: Column(
            children: [
              _buildSessionInfo(),
              const SizedBox(height: 16),
              _buildActivitySummaryCard(),
              const SizedBox(height: 16),
              _buildNotificationPrefs(),
            ],
          ),
        ),
      ],
    );
  }

  // ── Mobile / Tablet: single column, top header ─────────────────────────
  Widget _buildMobileLayout(bool mobile) {
    final pad = mobile ? 16.0 : 24.0;
    return SingleChildScrollView(
      padding: EdgeInsets.all(pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMobileHeader(),
          const SizedBox(height: 20),
          _buildStatsGrid(mobile, cols: mobile ? 2 : 4),
          const SizedBox(height: 20),
          _buildTabBar(),
          const SizedBox(height: 16),
          if (_selectedTab == 0) ...[
            _buildProfileTab(mobile),
            const SizedBox(height: 16),
            _buildSessionInfo(),
            const SizedBox(height: 16),
            _buildNotificationPrefs(),
          ],
          if (_selectedTab == 1) _buildSecurityTab(),
          if (_selectedTab == 2) _buildActivityTab(),
          const SizedBox(height: 20),
          _buildQuickActions(mobile),
          const SizedBox(height: 20),
          _buildDangerZone(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Sidebar header ─────────────────────────────────────────────────────
  Widget _buildSidebarHeader() {
    final user = FirebaseAuth.instance.currentUser;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F8EF7), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _accent.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _nameCtrl.text.isEmpty ? "Admin" : _nameCtrl.text,
            style: const TextStyle(
              color: _white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? "administrator",
            style: const TextStyle(color: _muted, fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          _pill(Icons.circle, "Online", _green),
        ],
      ),
    );
  }

  Widget _buildSidebarNav() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          const Divider(color: _divider),
          const SizedBox(height: 8),
          ...List.generate(_navItems.length, (i) {
            final active = _selectedTab == i;
            return GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: active ? _accentSoft : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: active
                        ? _accent.withOpacity(0.3)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _navItems[i]["icon"] as IconData,
                      size: 16,
                      color: active ? _accent : _muted,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _navItems[i]["label"] as String,
                      style: TextStyle(
                        color: active ? _accent : _muted,
                        fontSize: 13,
                        fontWeight: active
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    if (active) ...[
                      const Spacer(),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: _accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSidebarFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _subtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Last sync",
            style: TextStyle(color: _muted, fontSize: 10),
          ),
          const SizedBox(height: 4),
          Text(
            _now(),
            style: const TextStyle(
              color: _white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _loadStats,
            child: Row(
              children: [
                const Icon(Icons.refresh_rounded, color: _accent, size: 13),
                const SizedBox(width: 5),
                const Text(
                  "Refresh stats",
                  style: TextStyle(color: _accent, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Mobile header (replaces sidebar on small screens) ─────────────────
  Widget _buildMobileHeader() {
    final user = FirebaseAuth.instance.currentUser;
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4F8EF7), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.admin_panel_settings_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Admin Profile",
                style: TextStyle(
                  color: _white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                user?.email ?? "administrator",
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
            ],
          ),
        ),
        _pill(Icons.circle, "Online", _green),
      ],
    );
  }

  Widget _buildPageTitle() {
    return Row(
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Admin Profile",
              style: TextStyle(
                color: _white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 4),
            Text(
              "Manage your account, security and preferences",
              style: TextStyle(color: _muted, fontSize: 13),
            ),
          ],
        ),
        const Spacer(),
        _pill(Icons.circle, "Online", _green),
      ],
    );
  }

  // ── Stats grid ─────────────────────────────────────────────────────────
  Widget _buildStatsGrid(bool mobile, {required int cols}) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: mobile ? 1.5 : 1.8,
      ),
      itemCount: _stats.length,
      itemBuilder: (_, i) => _statCard(_stats[i]),
    );
  }

  Widget _statCard(Map<String, dynamic> s) {
    final color = s["color"] as Color;
    final soft = s["soft"] as Color;
    final isUp = s["up"] as bool;
    final isLoading = s["value"] == "…";
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: soft,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(s["icon"] as IconData, color: color, size: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: isUp ? _greenSoft : _redSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  s["delta"],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isUp ? _green : _red,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              isLoading
                  ? Container(
                      width: 48,
                      height: 20,
                      decoration: BoxDecoration(
                        color: _subtle,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )
                  : Text(
                      s["value"],
                      style: const TextStyle(
                        color: _white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
              const SizedBox(height: 2),
              Text(
                s["label"],
                style: const TextStyle(color: _muted, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Tab bar ────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    const tabs = ["Profile", "Security", "Activity"];
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = _selectedTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: active ? _accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Text(
                  tabs[i],
                  style: TextStyle(
                    color: active ? Colors.white : _muted,
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Profile tab ────────────────────────────────────────────────────────
  Widget _buildProfileTab(bool mobile) => Column(
    children: [
      _sectionCard(
        title: "Personal Information",
        icon: Icons.person_outline_rounded,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _inputField(
                    _nameCtrl,
                    "Full Name",
                    Icons.badge_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _inputField(
                    _emailCtrl,
                    "Email Address",
                    Icons.mail_outline_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _inputField(
                    TextEditingController(text: "Administrator"),
                    "Role",
                    Icons.shield_outlined,
                    readOnly: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _inputField(
                    TextEditingController(text: "Asia/Kathmandu (UTC+5:45)"),
                    "Timezone",
                    Icons.schedule_rounded,
                    readOnly: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _inputField(
                    TextEditingController(text: "Nepal (NPR)"),
                    "Region / Currency",
                    Icons.language_rounded,
                    readOnly: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _inputField(
                    TextEditingController(text: "Jan 12, 2024"),
                    "Account Created",
                    Icons.calendar_today_outlined,
                    readOnly: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _saveButton(),
    ],
  );

  // ── Security tab ───────────────────────────────────────────────────────
  Widget _buildSecurityTab() => Column(
    children: [
      _sectionCard(
        title: "Change Password",
        icon: Icons.lock_outline_rounded,
        child: Column(
          children: [
            _inputField(
              _passwordCtrl,
              "New Password",
              Icons.lock_outline_rounded,
              obscure: !_showPassword,
              suffix: IconButton(
                icon: Icon(
                  _showPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: _muted,
                  size: 18,
                ),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
            ),
            const SizedBox(height: 14),
            _passwordStrengthBar(),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _sectionCard(
        title: "Two-Factor Authentication",
        icon: Icons.security_rounded,
        child: Column(
          children: [
            _toggleRow(
              "2FA via Authenticator App",
              "Adds an extra layer of security",
              _twoFA,
              (v) => setState(() => _twoFA = v),
            ),
            const SizedBox(height: 12),
            const Divider(color: _divider, height: 0),
            const SizedBox(height: 12),
            _toggleRow(
              "Login Notifications",
              "Email me on new sign-in",
              _loginNotif,
              (v) => setState(() => _loginNotif = v),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _sectionCard(
              title: "Active Sessions",
              icon: Icons.devices_rounded,
              child: Column(
                children: [
                  _sessionRow("Chrome • macOS", "Kathmandu, NP · Now", true),
                  const SizedBox(height: 8),
                  _sessionRow(
                    "Mobile App • iOS",
                    "Pokhara, NP · 2 days ago",
                    false,
                  ),
                  const SizedBox(height: 8),
                  _sessionRow(
                    "Firefox • Windows",
                    "Unknown · 5 days ago",
                    false,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _sectionCard(
              title: "Login History",
              icon: Icons.history_rounded,
              child: Column(
                children: [
                  _loginHistoryRow("Today 09:42", "Chrome • macOS", true),
                  const SizedBox(height: 8),
                  _loginHistoryRow("Yesterday 21:15", "iOS App", true),
                  const SizedBox(height: 8),
                  _loginHistoryRow(
                    "Apr 14 · 11:03",
                    "Firefox • Windows",
                    false,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      _saveButton(),
    ],
  );

  // ── Activity tab ───────────────────────────────────────────────────────
  Widget _buildActivityTab() => Column(
    children: [
      _buildActivitySummaryCard(),
      const SizedBox(height: 12),
      _sectionCard(
        title: "Activity Log",
        icon: Icons.history_rounded,
        child: _activityLog.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    "No activity recorded yet",
                    style: TextStyle(color: _muted, fontSize: 13),
                  ),
                ),
              )
            : Column(
                children: _activityLog.take(10).map((item) {
                  final t = item["time"] as DateTime;
                  final ok = item["success"] as bool;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: ok ? _greenSoft : _redSoft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            ok ? Icons.check_rounded : Icons.close_rounded,
                            color: ok ? _green : _red,
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item["action"],
                            style: const TextStyle(color: _white, fontSize: 12),
                          ),
                        ),
                        Text(
                          "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}",
                          style: const TextStyle(color: _muted, fontSize: 11),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
      ),
    ],
  );

  // ── Always-visible activity summary ───────────────────────────────────
  Widget _buildActivitySummaryCard() => Row(
    children: [
      _activityChip(
        Icons.edit_rounded,
        "Edits",
        _activityLog.where((e) => e["success"] == true).length.toString(),
        _accent,
        _accentSoft,
      ),
      const SizedBox(width: 8),
      _activityChip(
        Icons.error_rounded,
        "Failures",
        _activityLog.where((e) => e["success"] == false).length.toString(),
        _red,
        _redSoft,
      ),
      const SizedBox(width: 8),
      _activityChip(
        Icons.history_rounded,
        "Total",
        _activityLog.length.toString(),
        _purple,
        _purpleSoft,
      ),
    ],
  );

  Widget _activityChip(
    IconData icon,
    String label,
    String value,
    Color color,
    Color soft,
  ) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(label, style: const TextStyle(color: _muted, fontSize: 9)),
            ],
          ),
        ],
      ),
    ),
  );

  // ── Session info ───────────────────────────────────────────────────────
  Widget _buildSessionInfo() => _sectionCard(
    title: "Session Info",
    icon: Icons.info_outline_rounded,
    child: Column(
      children: [
        _infoRow("Last Login", "Today, 09:42 AM"),
        const SizedBox(height: 8),
        _infoRow("IP Address", "192.168.1.1"),
        const SizedBox(height: 8),
        _infoRow("Device", "Chrome • macOS"),
        const SizedBox(height: 8),
        _infoRow("Account Created", "Jan 12, 2024"),
        const SizedBox(height: 8),
        _infoRow("Timezone", "UTC+5:45"),
      ],
    ),
  );

  // ── Notification prefs ─────────────────────────────────────────────────
  Widget _buildNotificationPrefs() => _sectionCard(
    title: "Notification Preferences",
    icon: Icons.notifications_none_rounded,
    child: Column(
      children: [
        _toggleRow(
          "New order alerts",
          "",
          _notifOrders,
          (v) => setState(() => _notifOrders = v),
        ),
        const SizedBox(height: 10),
        _toggleRow(
          "Low stock warnings",
          "",
          _notifStock,
          (v) => setState(() => _notifStock = v),
        ),
        const SizedBox(height: 10),
        _toggleRow(
          "User sign-up emails",
          "",
          _notifSignups,
          (v) => setState(() => _notifSignups = v),
        ),
        const SizedBox(height: 10),
        _toggleRow(
          "Weekly report digest",
          "",
          _notifDigest,
          (v) => setState(() => _notifDigest = v),
        ),
      ],
    ),
  );

  // ── Quick actions ──────────────────────────────────────────────────────
  Widget _buildQuickActions(bool mobile) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "Quick Actions",
        style: TextStyle(
          color: _white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 12),
      LayoutBuilder(
        builder: (ctx, constraints) {
          final cols = constraints.maxWidth < 400
              ? 3
              : constraints.maxWidth < 700
              ? 4
              : 6;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.95,
            ),
            itemCount: _quickActions.length,
            itemBuilder: (_, i) {
              final qa = _quickActions[i];
              return GestureDetector(
                onTap: () {},
                child: Container(
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _border),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: (qa["color"] as Color).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          qa["icon"] as IconData,
                          color: qa["color"] as Color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        qa["label"] as String,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: _muted, fontSize: 10),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    ],
  );

  // ── Danger zone ────────────────────────────────────────────────────────
  Widget _buildDangerZone() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: _redSoft,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _red.withOpacity(0.3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: _red, size: 14),
            const SizedBox(width: 7),
            const Text(
              "Danger Zone",
              style: TextStyle(
                color: _red,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Divider(color: Color(0x33EF4444), height: 0),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _dangerRow(
                "Sign Out All Devices",
                "Revoke all active sessions immediately",
                Icons.logout_rounded,
                () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _dangerRow(
                "Delete Admin Account",
                "Permanent and irreversible action",
                Icons.delete_forever_rounded,
                _showDeleteConfirm,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _dangerRow(
    String title,
    String sub,
    IconData icon,
    VoidCallback onTap,
  ) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.black12,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _red.withOpacity(0.2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: _red, size: 14),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: _red,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(sub, style: const TextStyle(color: _muted, fontSize: 11)),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              foregroundColor: _red,
              padding: const EdgeInsets.symmetric(vertical: 8),
              side: const BorderSide(color: _red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Proceed", style: TextStyle(fontSize: 11)),
          ),
        ),
      ],
    ),
  );

  void _showDeleteConfirm() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Delete Account?",
          style: TextStyle(color: _white, fontSize: 15),
        ),
        content: const Text(
          "This will permanently delete your admin account and all associated data. This cannot be undone.",
          style: TextStyle(color: _muted, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: _muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              // TODO: FirebaseAuth.instance.currentUser?.delete()
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Reusable widgets ───────────────────────────────────────────────────
  Widget _pill(IconData icon, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 8, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: _accent),
            const SizedBox(width: 7),
            Text(
              title,
              style: const TextStyle(
                color: _white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Divider(color: _divider, height: 0),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );

  Widget _inputField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscure = false,
    bool readOnly = false,
    Widget? suffix,
  }) => TextField(
    controller: controller,
    obscureText: obscure,
    readOnly: readOnly,
    style: const TextStyle(color: _white, fontSize: 13),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _muted, fontSize: 12),
      prefixIcon: Icon(icon, color: _muted, size: 16),
      suffixIcon: suffix,
      filled: true,
      fillColor: _surface,
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _accent, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _border),
      ),
    ),
  );

  Widget _infoRow(String label, String value) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(color: _muted, fontSize: 12)),
      Text(
        value,
        style: const TextStyle(
          color: _white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );

  Widget _toggleRow(
    String title,
    String sub,
    bool value,
    ValueChanged<bool> onChanged,
  ) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: _white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (sub.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(sub, style: const TextStyle(color: _muted, fontSize: 11)),
            ],
          ],
        ),
      ),
      GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 42,
          height: 24,
          decoration: BoxDecoration(
            color: value ? _accent : _subtle,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(3),
          child: Align(
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    ],
  );

  // Widget _toggle(bool on) => AnimatedContainer(
  //   duration: const Duration(milliseconds: 200),
  //   width: 42,
  //   height: 24,
  //   decoration: BoxDecoration(
  //     color: on ? _accent : _subtle,
  //     borderRadius: BorderRadius.circular(12),
  //   ),
  //   padding: const EdgeInsets.all(3),
  //   child: Align(
  //     alignment: on ? Alignment.centerRight : Alignment.centerLeft,
  //     child: Container(
  //       width: 18,
  //       height: 18,
  //       decoration: const BoxDecoration(
  //         color: Colors.white,
  //         shape: BoxShape.circle,
  //       ),
  //     ),
  //   ),
  // );

  Widget _sessionRow(String device, String meta, bool current) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: current ? _accentSoft : _subtle,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.devices_rounded,
          color: current ? _accent : _muted,
          size: 16,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              device,
              style: const TextStyle(
                color: _white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(meta, style: const TextStyle(color: _muted, fontSize: 11)),
          ],
        ),
      ),
      if (current)
        _pill(Icons.circle, "Current", _green)
      else
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            foregroundColor: _red,
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text("Revoke", style: TextStyle(fontSize: 11)),
        ),
    ],
  );

  Widget _loginHistoryRow(String time, String device, bool success) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: success ? _greenSoft : _redSoft,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          success ? Icons.login_rounded : Icons.block_rounded,
          color: success ? _green : _red,
          size: 14,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              device,
              style: const TextStyle(
                color: _white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(time, style: const TextStyle(color: _muted, fontSize: 11)),
          ],
        ),
      ),
      _pill(
        success ? Icons.check_circle : Icons.cancel,
        success ? "Success" : "Blocked",
        success ? _green : _red,
      ),
    ],
  );

  Widget _passwordStrengthBar() {
    final len = _passwordCtrl.text.length;
    final strength = len == 0
        ? 0
        : len < 6
        ? 1
        : len < 10
        ? 2
        : 3;
    const colors = [_muted, _red, _amber, _green];
    const labels = ["—", "Weak", "Fair", "Strong"];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(
            3,
            (i) => Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                height: 3,
                decoration: BoxDecoration(
                  color: strength > i ? colors[strength] : _subtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          strength == 0
              ? "Enter a password above"
              : "Password strength: ${labels[strength]}",
          style: TextStyle(color: colors[strength], fontSize: 11),
        ),
      ],
    );
  }

  Widget _saveButton() => SizedBox(
    width: double.infinity,
    height: 46,
    child: ElevatedButton(
      onPressed: _loading ? null : _updateProfile,
      style: ElevatedButton.styleFrom(
        backgroundColor: _accent,
        disabledBackgroundColor: _accentSoft,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.save_outlined, size: 16, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  "Save Changes",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
    ),
  );

  String _now() {
    final t = DateTime.now();
    return "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')} "
        "· ${t.day}/${t.month}/${t.year}";
  }
}
