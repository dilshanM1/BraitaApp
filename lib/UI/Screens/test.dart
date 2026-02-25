void _showSuccessDialog(int earned, int totalBalance) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: const BoxDecoration(
                color: Color(0xFF9C27B0),
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30), topRight: Radius.circular(30)),
              ),
              child: const Text(
                "Wow.. You earnd",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            // Robot on gold coins from image_ea5b3b.png
            Image.asset('Assets/Images/robot_gold.png', height: 140),
            const SizedBox(height: 15),
            Text("You earned $earned extra points",
                style: const TextStyle(fontSize: 14, color: Colors.black54)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Your point balance",
                    style: TextStyle(fontSize: 14, color: Colors.black54)),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE1BEE7),
                    shape: BoxShape.circle,
                  ),
                  child: Text("$totalBalance",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF9C27B0))),
                ),
              ],
            ),
            const SizedBox(height: 25),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close this dialog
                  _streakCount = 0;
                  _proceedToNext(); // ONLY NOW start the next quiz and timer
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9C27B0),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: const Text("Continue",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
    },
  );
}