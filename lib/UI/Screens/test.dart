void _showCongratulationsDialog() {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ... (Your existing Header "Congratulations !")

            // ... (Your existing Image and "Watch video to collect 4 Points" text)

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton(
                onPressed: !_adManager.isLoaded ? null : () {
                  _adManager.showAd(onRewardEarned: () async {
                    if (mounted) {
                      Navigator.pop(context); // Close the "Watch Ad" dialog

                      // 1. Update Database first
                      await _updateDatabase(true, points: 4);

                      // 2. Fetch the updated points for the dialog
                      final userSnap = await _dbRef.child('User').child(_deviceId!).get();
                      int currentBalance = 0;
                      if (userSnap.exists) {
                        Map data = userSnap.value as Map;
                        currentBalance = data['MyPoints'] ?? 0;
                      }

                      // 3. Show the "Success" dialog (Your design image_ea5b3b.png)
                      _showSuccessDialog(4, currentBalance);
                    }
                  });
                },
                // ... (Your existing Purple Button Style)
                child: const Text("Collect Points 🔊"),
              ),
            ),

            // ... (Your existing Cancel Button)
          ],
        ),
      );
    },
  );
}