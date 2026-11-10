import 'package:cocoa_supply/services/tour_service.dart';
import 'package:flutter/widgets.dart';
import 'package:showcaseview/showcaseview.dart';

/// The pages the guided tour walks through, in order (docs-and-plan#310).
/// farmTab is the home page's ฟาร์ม tab, where the "เพิ่มข้อมูลฟาร์ม"
/// button is; farm and plot are the two register pages.
enum TourStage { signUp, role, home, farmTab, farm, plot }

/// The widgets the tour points at. showcaseview 5 uses these only as ids
/// (they aren't attached to the widgets), so pages and the scaffold around
/// them can share them.
abstract final class TourKeys {
  static final GlobalKey roleCards = GlobalKey(debugLabel: 'tour:roleCards');
  static final GlobalKey roleNext = GlobalKey(debugLabel: 'tour:roleNext');

  static final GlobalKey homeDate = GlobalKey(debugLabel: 'tour:homeDate');
  static final GlobalKey homeTasks = GlobalKey(debugLabel: 'tour:homeTasks');
  static final GlobalKey profile = GlobalKey(debugLabel: 'tour:profile');
  static final GlobalKey farmTab = GlobalKey(debugLabel: 'tour:farmTab');

  static final GlobalKey registerFarm = GlobalKey(debugLabel: 'tour:registerFarm');

  /// The home page's steps, in order. It ends on the ฟาร์ม tab, which
  /// leads to the "เพิ่มข้อมูลฟาร์ม" button.
  static List<GlobalKey> get home => [homeDate, homeTasks, profile, farmTab];
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
class TourController extends ChangeNotifier {
  TourController._(this._seen) {
    _view = ShowcaseView.register(
      scope: scope,
      onFinish: _onPageFinished,
      onDismiss: (_) => skip(),
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

  final TourService _seen;
  late final ShowcaseView _view;

  bool _active = false;
  TourStage _stage = TourStage.signUp;
  final Set<TourStage> _shown = {};

  bool get isActive => _active;

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
    _stage = from;
    _shown.clear();
    notifyListeners();
  }

  /// Whether [stage]'s page should show its steps now.
  bool wants(TourStage stage) =>
      _active && stage.index >= _stage.index && !_shown.contains(stage);

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
    _view.startShowCase(onScreen);
  }

  /// Skip: ends the whole tour, not just this page's steps.
  Future<void> skip() async {
    if (!_active) return;
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
    await _seen.markSeen();
  }
}
