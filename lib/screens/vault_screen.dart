import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Secure storage
import 'dart:convert'; // For encoding/decoding JSON
import 'package:random_password_generator/random_password_generator.dart';
import 'package:flutter/services.dart'; // For copying to clipboard
import 'dart:async'; // For clipboard timeout

class VaultScreen extends StatefulWidget {
  @override
  _VaultScreenState createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> with SingleTickerProviderStateMixin {
  List<Map<String, String>> passwords = [];
  List<bool> _isPasswordVisibleInList = []; // Tracking visibility of each password
  late TabController _tabController;

  // Secure storage instance
  final FlutterSecureStorage secureStorage = FlutterSecureStorage();

  // Variables for password generation
  String _generatedPassword = '';
  double _passwordLength = 8;  // Default password length
  bool _includeDigits = true;
  bool _includeSymbols = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPasswords();  // Load saved passwords from local storage
  }

  // Load passwords from SharedPreferences
  Future<void> _loadPasswords() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedPasswords = prefs.getString('passwords');

    if (savedPasswords != null) {
      List<dynamic> decodedPasswords = jsonDecode(savedPasswords);
      setState(() {
        passwords = decodedPasswords.map((entry) => Map<String, String>.from(entry)).toList();
        _isPasswordVisibleInList = List<bool>.generate(passwords.length, (index) => false);
      });
    }
  }

  // Save passwords to SharedPreferences
  Future<void> _savePasswords() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String encodedPasswords = jsonEncode(passwords);
    await prefs.setString('passwords', encodedPasswords);  // Save passwords as JSON
  }

  // Save passwords to secure storage
  Future<void> _saveToSecureStorage(String key, String value) async {
    await secureStorage.write(key: key, value: value);
  }

  // Read passwords from secure storage
  Future<String?> _readFromSecureStorage(String key) async {
    return await secureStorage.read(key: key);
  }

  // Add new password and keep lists in sync
  void addPassword(String name, String password) async {
    if (name.isNotEmpty && password.isNotEmpty) {
      setState(() {
        passwords.add({'name': name, 'password': password});
        _isPasswordVisibleInList.add(false);
      });
      await _saveToSecureStorage(name, password);
      await _savePasswords();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Account name and password must not be empty!')),
      );
    }
  }

  // Update password at a specific index
  void updatePassword(int index, String name, String password) async {
    if (name.isNotEmpty && password.isNotEmpty) {
      setState(() {
        passwords[index] = {'name': name, 'password': password};
      });
      await _saveToSecureStorage(name, password);
      await _savePasswords();
    }
  }

  // Delete password and keep lists in sync
  void deletePassword(int index) {
    setState(() {
      passwords.removeAt(index);
      _isPasswordVisibleInList.removeAt(index);
    });
    _savePasswords();
  }

  // Show dialog to add or edit password
  void _showAddPasswordDialog({int? index}) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    if (index != null) {
      nameController.text = passwords[index]['name'] ?? '';
      passwordController.text = passwords[index]['password'] ?? '';
    }

    bool _isPasswordVisible = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(index == null ? 'Add New Password' : 'Edit Password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: 'Account Name'),
                  ),
                  TextField(
                    controller: passwordController,
                    obscureText : !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    String accountName = nameController.text;
                    String password = passwordController.text;
                    if (accountName.isNotEmpty && password.isNotEmpty) {
                      if (index == null) {
                        addPassword(accountName, password);
                      } else {
                        updatePassword(index, accountName, password);
                      }
                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Both fields are required!')),
                      );
                    }
                  },
                  child: Text(index == null ? 'Save' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Method to generate a random password
  String generatePassword() {
    final passwordGenerator = RandomPasswordGenerator();
    String newPassword = passwordGenerator.randomPassword(
      letters: true,
      numbers: _includeDigits,
      specialChar: _includeSymbols,
      passwordLength: _passwordLength,
    );
    setState(() {
      _generatedPassword = newPassword;
    });
    return newPassword;
  }

  // Function to clear the clipboard after a few seconds
  void _clearClipboard() {
    Timer(Duration(seconds: 50), () {
      Clipboard.setData(ClipboardData(text: ''));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Clipboard cleared for security!')),
      );
    });
  }

  Future<bool> _showExitDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Exit App'),
        content: Text('Are you sure you want to exit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // Do not exit
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true), // Exit
            child: Text('Exit'),
          ),
        ],
      ),
    ).then((value) => value ?? false); // Return false if dialog is dismissed
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return await _showExitDialog(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("Password Vault"),
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(icon: Icon(Icons.security), text: "Saved Passwords"),
              Tab(icon: Icon(Icons.lock), text: "Generate Password"),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: Saved Passwords
            ListView.builder(
              itemCount: passwords.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(passwords[index]['name'] ?? ''),
                  subtitle: Text(
                    _isPasswordVisibleInList[index]
                        ? passwords[index]['password'] ?? ''
                        : '********',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(_isPasswordVisibleInList[index]
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisibleInList[index] =
                            !_isPasswordVisibleInList[index];
                          });
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.copy),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(
                              text: passwords[index]['password'] ?? ''));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Password copied to clipboard!')),
                          );
                          _clearClipboard();
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          _showAddPasswordDialog(index: index);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          deletePassword(index);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
            // Tab 2: Generate Password
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_generatedPassword.isNotEmpty)
                    Column(
                      children: [
                        Text(
                          "Generated Password: $_generatedPassword",
                          style: TextStyle(fontSize: 18),
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: _generatedPassword));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                  Text('Password copied to clipboard!')),
                            );
                            _clearClipboard();
                          },
                          child: Text("Copy Password"),
                        ),
                      ],
                    ),
                  SizedBox(height: 20),
                  Text("Password Length: ${_passwordLength.toInt()}"),
                  Slider(
                    value: _passwordLength,
                    min: 4,
                    max: 20,
                    divisions: 16,
                    label: _passwordLength.toInt().toString(),
                    onChanged: (value) {
                      setState(() {
                        _passwordLength = value;
                      });
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Checkbox(
                        value: _includeDigits,
                        onChanged: (value) {
                          setState(() {
                            _includeDigits = value ?? true;
                          });
                        },
                      ),
                      Text('Include Digits'),
                      Checkbox(
                        value: _includeSymbols,
                        onChanged: (value) {
                          setState(() {
                            _includeSymbols = value ?? true;
                          });
                        },
                      ),
                      Text('Include Symbols'),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: generatePassword,
                    child: Text("Generate Password"),
                  ),
                ],
              ),
            ),
          ],
        ),
        // Add Floating Action Button for adding a new password
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _showAddPasswordDialog();  // Open the add password dialog
          },
          child: Icon(Icons.add),  // Icon for the add button
          tooltip: 'Add New Password',  // Tooltip for accessibility
        ),
      ),
    );
  }
}