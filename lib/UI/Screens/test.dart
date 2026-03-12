class _BottomNavigationState extends State<BottomNavigation> {
  // --- Create an instance of your manager here ---
  final InterstitialAdManager _adManager = InterstitialAdManager();

  @override
  void initState() {
    super.initState();
    _adManager.loadAd(); // Pre-load the ad so it's ready
  }

  void _onTap(int index, Widget screen) {
    // ... your existing _onTap code ...
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double itemWidth = (screenWidth - 20) / 4;

    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;

          // RULE 1: If not on Home tab, go to Home
          if (widget.currentIndex != 0) {
            _onTap(0, const HomeScreen());
            return;
          }

          // RULE 2: If on Home, call your manager's showAd method
          _adManager.showAd(onAdDismissed: () {
            // This runs after the ad is closed OR if the ad fails to show
            SystemNavigator.pop();
          });

          // Safety timeout (optional): Ensures app closes even if
          // the ad SDK hangs for some reason.
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (mounted) SystemNavigator.pop();
          });
        },
        child: SafeArea(
    // ... rest of your UI code ...