import 'package:cocoa_supply/services/tour_service.dart';
import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

/// The pages the guided tour walks through, in order (docs-and-plan#310).
/// - roleInfo .. roleReview: the role form's pages (about you, address, the
///   role's own questions, review).
/// - farmTab: the home page's ฟาร์ม tab, where "เพิ่มข้อมูลฟาร์ม" is.
/// - farmInfo / farmAddress / farmMap: the farm form's three pages.
/// - plotAdd: the farm card's plots box on the ฟาร์ม tab, once a farm exists.
/// - plotInfo / plotMap: the plot form's first page and its map page.
/// - done: back on the ฟาร์ม tab after the first plot is saved.
enum TourStage {
  signUp,
  role,
  roleInfo,
  roleAddress,
  roleDetails,
  roleReview,
  home,
  farmTab,
  farmInfo,
  farmAddress,
  farmMap,
  plotAdd,
  plotInfo,
  plotMap,
  done,
}

/// The widgets the tour points at. showcaseview 5 uses these only as ids
/// (they aren't attached to the widgets), so pages and the scaffold around
/// them can share them.
abstract final class TourKeys {
  static final GlobalKey signUpPhone = GlobalKey(debugLabel: 'tour:signUpPhone');
  static final GlobalKey signUpPassword = GlobalKey(debugLabel: 'tour:signUpPassword');
  static final GlobalKey signUpEmail = GlobalKey(debugLabel: 'tour:signUpEmail');
  static final GlobalKey signUpSubmit = GlobalKey(debugLabel: 'tour:signUpSubmit');

  static final GlobalKey roleFarmer = GlobalKey(debugLabel: 'tour:roleFarmer');
  static final GlobalKey roleNext = GlobalKey(debugLabel: 'tour:roleNext');

  static final GlobalKey roleInfo = GlobalKey(debugLabel: 'tour:roleInfo');
  static final GlobalKey roleAddress = GlobalKey(debugLabel: 'tour:roleAddress');
  static final GlobalKey roleDetails = GlobalKey(debugLabel: 'tour:roleDetails');
  static final GlobalKey roleReview = GlobalKey(debugLabel: 'tour:roleReview');

  static final GlobalKey homeDate = GlobalKey(debugLabel: 'tour:homeDate');
  static final GlobalKey homeTasks = GlobalKey(debugLabel: 'tour:homeTasks');
  static final GlobalKey profile = GlobalKey(debugLabel: 'tour:profile');
  static final GlobalKey farmTab = GlobalKey(debugLabel: 'tour:farmTab');

  static final GlobalKey registerFarm = GlobalKey(debugLabel: 'tour:registerFarm');

  static final GlobalKey farmInfo = GlobalKey(debugLabel: 'tour:farmInfo');
  static final GlobalKey farmAddress = GlobalKey(debugLabel: 'tour:farmAddress');
  static final GlobalKey farmMap = GlobalKey(debugLabel: 'tour:farmMap');

  static final GlobalKey plotAdd = GlobalKey(debugLabel: 'tour:plotAdd');
  static final GlobalKey plotInfo = GlobalKey(debugLabel: 'tour:plotInfo');
  static final GlobalKey plotMap = GlobalKey(debugLabel: 'tour:plotMap');

  static final GlobalKey done = GlobalKey(debugLabel: 'tour:done');

  /// The home page's steps, in order. It ends on the ฟาร์ม tab, which
  /// leads to the "เพิ่มข้อมูลฟาร์ม" button.
  static List<GlobalKey> get home => [homeDate, homeTasks, profile, farmTab];

  /// Every page's steps, in tour order. The "1/7" counter on each step is
  /// counted from this, so a page that adds steps adds them here too.
  static List<GlobalKey> get signUp => [signUpPhone, signUpPassword, signUpEmail, signUpSubmit];

  static Map<TourStage, List<GlobalKey>> get byStage => {
        TourStage.signUp: signUp,
        TourStage.role: [roleFarmer, roleNext],
        TourStage.roleInfo: [roleInfo],
        TourStage.roleAddress: [roleAddress],
        TourStage.roleDetails: [roleDetails],
        TourStage.roleReview: [roleReview],
        TourStage.home: home,
        TourStage.farmTab: [registerFarm],
        TourStage.farmInfo: [farmInfo],
        TourStage.farmAddress: [farmAddress],
        TourStage.farmMap: [farmMap],
        TourStage.plotAdd: [plotAdd],
        TourStage.plotInfo: [plotInfo],
        TourStage.plotMap: [plotMap],
        TourStage.done: [done],
      };
}

/// Carries the guided tour across pages (docs-and-plan#311).
///
/// showcaseview only highlights widgets on the page that is on screen, so
/// each page shows its own steps with [show] when it is built. This class
/// remembers whether a tour is running and which pages have had their turn,
/// so the tour can continue sign-up -> role -> home -> farm -> plot.
///
/// - Skip (on any step) ends the whole tour and sets the "seen" flag.
/// - Finishing the last page's steps sets the flag too.
/// - The tour only starts from [startForNewUser] (the sign-up button) or
///   [replay] (the profile sheet), so someone who just logs in never sees it.
/// - Its progress is saved on the phone, so closing the app mid-tour picks
///   it up again on the page the person was on ([restore]).
class TourController extends ChangeNotifier {
  TourController._(this._seen) {
    _view = ShowcaseView.register(
      scope: scope,
      onFinish: _onPageFinished,
      onDismiss: (_) => skip(),
      // Scrolls a long page (e.g. sign-up on a small phone) to each step's
      // widget, so the tooltip never points off-screen.
      enableAutoScroll: true,
    );
  }

  static TourController _instance = TourController._(TourService());
  static TourController get instance => _instance;

  /// A fresh controller for each test, so one test's tour doesn't leak
  /// into the next.
  @visibleForTesting
  static void debugReset([TourService? seen]) {
    _instance._view.unregister();
    _instance = TourController._(seen ?? TourService());
  }

  /// The showcaseview scope every [TourStep] uses.
  static const String scope = 'cocoa_tour';

  /// MaterialApp's scaffoldMessengerKey, so skipping can say where the tour
  /// can be replayed from whatever page it was on.
  static final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();

  final TourService _seen;
  late final ShowcaseView _view;

  bool _active = false;
  TourStage _start = TourStage.signUp;
  TourStage _stage = TourStage.signUp;
  final Set<TourStage> _shown = {};
  // Stages this tour won't show, e.g. the farm form for someone replaying
  // the tour who already has a farm. Left out of the step counter.
  final Set<TourStage> _skipped = {};

  bool get isActive => _active;

  /// Where [key]'s step is in the whole tour, e.g. "3/7", counted from the
  /// page the tour started on. Null when no tour is running or the step
  /// isn't in [TourKeys.byStage].
  String? progressOf(GlobalKey key) {
    if (!_active) return null;
    final steps = [
      for (final stage in TourStage.values)
        if (stage.index >= _start.index && !_skipped.contains(stage)) ...?TourKeys.byStage[stage],
    ];
    final index = steps.indexOf(key);
    return index < 0 ? null : '${index + 1}/${steps.length}';
  }

  /// Leaves [stages] out of this tour (and of the counter).
  void skipStages(Iterable<TourStage> stages) {
    if (!_active || _skipped.containsAll(stages)) return;
    _skipped.addAll(stages);
    _save();
    notifyListeners();
  }

  /// Picks up a tour that was running when the app was closed. The page the
  /// person was on shows its steps again; earlier pages don't.
  Future<void> restore() async {
    final saved = await _seen.loadProgress();
    if (saved == null) return;
    try {
      TourStage stage(Object? name) => TourStage.values.byName(name as String);
      _start = stage(saved['start']);
      _stage = stage(saved['stage']);
      _shown
        ..clear()
        ..addAll((saved['shown'] as List).map(stage))
        ..remove(_stage);
      _skipped
        ..clear()
        ..addAll((saved['skipped'] as List? ?? const []).map(stage));
      _active = true;
      notifyListeners();
    } catch (_) {
      // A saved tour from an older version of the app: drop it.
      await _seen.clearProgress();
    }
  }

  void _save() => _seen.saveProgress({
        'start': _start.name,
        'stage': _stage.name,
        'shown': [for (final s in _shown) s.name],
        'skipped': [for (final s in _skipped) s.name],
      });

  /// Starts the tour from sign-up, unless this phone has seen it already.
  Future<void> startForNewUser() async {
    if (await _seen.hasSeen()) return;
    _begin(TourStage.signUp);
  }

  /// Runs the tour again from the home page ("วิธีใช้แอป"). The "seen"
  /// flag stays set, so a replay never turns the tour back on at sign-up.
  void replay() => _begin(TourStage.home);

  void _begin(TourStage from) {
    _active = true;
    _start = from;
    _stage = from;
    _shown.clear();
    _skipped.clear();
    _save();
    notifyListeners();
  }

  /// Whether [stage]'s page should show its steps now.
  bool wants(TourStage stage) =>
      _active && stage.index >= _stage.index && !_shown.contains(stage);

  /// Whether the tour has got as far as [stage]. For a page that shows more
  /// than one stage (the ฟาร์ม tab): a later stage waits until the person
  /// has actually been through the pages before it.
  bool reached(TourStage stage) => _active && _stage.index >= stage.index;

  /// Shows [stage]'s steps, in the order of [keys], if the tour is running
  /// and hasn't reached a later page yet. Call it after the page's first
  /// frame, once the highlighted widgets are laid out. Steps whose widget
  /// isn't on screen are left out (e.g. the ฟาร์ม tab for someone who isn't
  /// a farmer).
  void show(TourStage stage, List<GlobalKey> keys) {
    if (!wants(stage)) return;
    final onScreen = keys.where(_view.isTargetRendered).toList();
    if (onScreen.isEmpty) return;
    _stage = stage;
    _shown.add(stage);
    _save();
    _view.startShowCase(onScreen);
  }

  /// Moves to the next step, as "ถัดไป" does, then runs [action] (what the
  /// tapped button does). Used by steps that continue when the highlighted
  /// button itself is tapped.
  ///
  /// [action] waits until the step has closed: if it opened another page
  /// first, the step's closing animation would pause with the covered page
  /// and the tooltip would stay stuck on top of the new one.
  void nextThen(VoidCallback action) {
    var ran = false;
    void done(int? index, GlobalKey key) {
      if (ran) return;
      ran = true;
      // Not removed right here: showcaseview is looping over its callbacks.
      Future.microtask(() => _view.removeOnCompleteCallback(done));
      action();
    }

    _view.addOnCompleteCallback(done);
    _view.next(force: true);
  }

  /// Skip: ends the whole tour, not just this page's steps, and says where
  /// to replay it, so one stray tap doesn't lose it for good.
  Future<void> skip() async {
    if (!_active) return;
    messengerKey.currentState?.showSnackBar(
      const SnackBar(
        content: Text('ปิดคำแนะนำแล้ว ดูอีกครั้งได้ที่ปุ่ม ? มุมขวาบนของหน้าหลัก'),
        duration: Duration(seconds: 5),
      ),
    );
    await _end();
  }

  // One page's steps are done. The tour waits for the next page unless
  // this was the last one.
  void _onPageFinished() {
    if (_active && _stage == TourStage.values.last) _end();
  }

  Future<void> _end() async {
    _active = false;
    notifyListeners();
    await _seen.clearProgress();
    await _seen.markSeen();
  }
}
