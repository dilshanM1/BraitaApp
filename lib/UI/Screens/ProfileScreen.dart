import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:braita_new/Services/DatabaseService.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final DatabaseService _dbService = DatabaseService();
  String? _deviceId;

  // Controllers for the dialog fields
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  String _selectedGender = 'Male';

  @override
  void initState() {
    super.initState();
    _loadUserContext();
  }

  @override
  void dispose() {
    // Clean up all controllers to prevent memory leaks
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _districtController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _loadUserContext() async {
    String? rawId = await _dbService.getDeviceId();
    if (rawId != null) {
      setState(() {
        _deviceId = rawId.replaceAll(RegExp(r'[.#$\[\]]'), '_');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _deviceId == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder(
        stream: _dbRef.child('User').child(_deviceId!).onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          // Default local data
          Map userData = {
            'UserName': 'Visitor user',
            'Email': 'visiter@gmail.com',
            'Age': '0',
            'Gender': 'Custom',
            'District': 'Custom',
            'ProfileImage': ''
          };

          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            userData = Map<dynamic, dynamic>.from(snapshot.data!.snapshot.value as Map);
          }

          return Column(
            children: [
              const SizedBox(height: 35),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          _buildHeader(context),
                          Positioned(
                            top: 150,
                            child: _buildProfileCard(context, userData),
                          ),
                          Positioned(
                            top: 70,
                            child: _buildProfileImage(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 130),
                      _buildEditButton(context, userData),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- Profile Card UI ---
  Widget _buildProfileCard(BuildContext context, Map userData) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      padding: const EdgeInsets.fromLTRB(20, 90, 20, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          Text(userData['UserName'] ?? "Visitor user",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF605454))),
          const Divider(height: 30, thickness: 1.5, indent: 20, endIndent: 20),
          Text(userData['Email'] ?? "visiter@gmail.com", style: const TextStyle(fontSize: 16, color: Color(0xFF605454))),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCategoryPill(userData['Age']?.toString() ?? "0"),
              _buildCategoryPill(userData['Gender'] ?? "Custom"),
              _buildCategoryPill(userData['District'] ?? "Custom"),
            ],
          ),
          const SizedBox(height: 40),
          const Text("Have a grateful day and take \nanother quiz to keep yourself motivated!",
              textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Color(0xFF605454))),
          const SizedBox(height: 20),
          _buildBottomIndicator(),
        ],
      ),
    );
  }

  // --- Logic to Update Firebase ---
  Future<void> _updateFirebaseProfile(BuildContext dialogContext) async {
    String fullName = "${_firstNameController.text} ${_lastNameController.text}";

    // Updates name, email, gender, district, and AGE
    await _dbRef.child('User').child(_deviceId!).update({
      'UserName': fullName.trim().isEmpty ? 'Visitor user' : fullName,
      'Email': _emailController.text,
      'Gender': _selectedGender,
      'District': _districtController.text,
      'Age': _ageController.text, // Correctly captures age from controller
    });

    if (mounted) Navigator.pop(dialogContext);
  }

  // --- Main Edit Button ---
  Widget _buildEditButton(BuildContext context, Map userData) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 70),
      child: GestureDetector(
        onTap: () => _showEditProfileDialog(context, userData),
        child: Container(
          width: double.infinity, height: 55,
          decoration: BoxDecoration(
            color: const Color(0xFF9C27B0),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: const Color(0xFF9C27B0).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
          ),
          child: const Center(
            child: Text("Edit My Profile", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          ),
        ),
      ),
    );
  }

  // --- Main Profile Edit Dialog (Matches your UI Screenshot) ---
  void _showEditProfileDialog(BuildContext context, Map existingData) {
    List<String> names = (existingData['UserName'] ?? "").split(" ");
    _firstNameController.text = names.isNotEmpty ? names[0] : "";
    _lastNameController.text = names.length > 1 ? names.sublist(1).join(" ") : "";
    _emailController.text = existingData['Email'] ?? '';
    _districtController.text = existingData['District'] ?? '';
    _ageController.text = existingData['Age']?.toString() ?? '';
    _selectedGender = (existingData['Gender'] == 'Male' || existingData['Gender'] == 'Female') ? existingData['Gender'] : 'Male';

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
            builder: (context, setDialogState) {
              return Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDialogHeader("Edit Profile"),
                      const SizedBox(height: 20),
                      _buildEditableAvatar(),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: _buildTextField("First name", _firstNameController)),
                                const SizedBox(width: 10),
                                Expanded(child: _buildTextField("Last name", _lastNameController)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _buildTextField("E-mail address", _emailController),
                            const SizedBox(height: 10),
                            _buildTextField("District", _districtController),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(child: _buildDropdownField(setDialogState)),
                                const SizedBox(width: 10),
                                Expanded(child: _buildTextField("Age", _ageController, isNumber: true)),
                              ],
                            ),
                            const SizedBox(height: 25),
                            _buildDialogButton("Update profile", const Color(0xFF9C27B0), Colors.white, () => _updateFirebaseProfile(dialogContext)),
                            const SizedBox(height: 10),
                            _buildDialogButton("Skip", const Color(0xFF6D676E), Colors.white, () => Navigator.pop(dialogContext)),
                            const SizedBox(height: 25),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
        );
      },
    );
  }

  // --- Helper Widgets ---
  Widget _buildTextField(String hint, TextEditingController controller, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint, filled: true,
        fillColor: const Color(0xFFEDE7F6).withOpacity(0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildDropdownField(StateSetter setDialogState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: const Color(0xFFEDE7F6).withOpacity(0.5), borderRadius: BorderRadius.circular(10)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedGender, isExpanded: true,
          items: const [DropdownMenuItem(value: 'Male', child: Text('Male')), DropdownMenuItem(value: 'Female', child: Text('Female'))],
          onChanged: (val) { if (val != null) setDialogState(() => _selectedGender = val); },
        ),
      ),
    );
  }

  Widget _buildDialogHeader(String title) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(color: Color(0xFF9C27B0), borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30))),
      child: Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEditableAvatar() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        const CircleAvatar(radius: 50, backgroundImage: AssetImage('Assets/Images/avatar.png')),
        const CircleAvatar(radius: 14, backgroundColor: Color(0xFF9C27B0), child: Icon(Icons.camera_alt, size: 15, color: Colors.white)),
      ],
    );
  }

  Widget _buildBottomIndicator() {
    return Container(height: 8, width: 80, decoration: const BoxDecoration(color: Color(0xFF9C27B0), borderRadius: BorderRadius.vertical(top: Radius.circular(10))));
  }

  Widget _buildCategoryPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFFEFE6F3), borderRadius: BorderRadius.circular(10)),
      child: Text(label, style: const TextStyle(color: Color(0xFF605454), fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10), height: 300, width: double.infinity,
      decoration: const BoxDecoration(color: Color(0xFF9C27B0), borderRadius: BorderRadius.all(Radius.circular(40))),
      child: Stack(
        children: [
          ..._buildFullStarPattern(rows: 4, columns: 4),
          Positioned(
            top: 20, left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(padding: const EdgeInsets.all(10), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF9C27B0), size: 18)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    return Container(
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 5)),
      child: const CircleAvatar(radius: 75, backgroundImage: AssetImage('Assets/Images/avatar.png')),
    );
  }

  List<Widget> _buildFullStarPattern({required int rows, required int columns}) {
    List<Widget> stars = [];
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < columns; j++) {
        stars.add(Positioned(top: (i * 90).toDouble() - 10, left: (j * 110).toDouble() - 10, child: Opacity(opacity: 0.3, child: Image.asset('Assets/Images/star2.png', width: (i + j) % 2 == 0 ? 80 : 50, height: (i + j) % 2 == 0 ? 80 : 50))));
      }
    }
    return stars;
  }

  Widget _buildDialogButton(String text, Color color, Color textColor, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity, height: 48,
      child: ElevatedButton(onPressed: onPressed, style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)), elevation: 0), child: Text(text, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16))),
    );
  }
}