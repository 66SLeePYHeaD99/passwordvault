import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FlutterSecureStorage secureStorage = FlutterSecureStorage();
  bool _autoLockEnabled = true;
  int _autoLockTimeout = 5; // minutes
  bool _clipboardClearEnabled = true;
  int _clipboardClearTimeout = 50; // seconds

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoLockEnabled = prefs.getBool('auto_lock_enabled') ?? true;
      _autoLockTimeout = prefs.getInt('auto_lock_timeout') ?? 5;
      _clipboardClearEnabled = prefs.getBool('clipboard_clear_enabled') ?? true;
      _clipboardClearTimeout = prefs.getInt('clipboard_clear_timeout') ?? 50;
    });
  }

  Future<void> _saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_lock_enabled', _autoLockEnabled);
    await prefs.setInt('auto_lock_timeout', _autoLockTimeout);
    await prefs.setBool('clipboard_clear_enabled', _clipboardClearEnabled);
    await prefs.setInt('clipboard_clear_timeout', _clipboardClearTimeout);
  }

  Future<void> _logout() async {
    // Show confirmation dialog
    bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  Future<void> _clearAllData() async {
    bool? shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear All Data'),
        content: Text('This will delete all saved passwords. This action cannot be undone. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Clear All'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (shouldClear == true) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('passwords');
      await secureStorage.deleteAll();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All data cleared successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Security Settings',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 16),
                  SwitchListTile(
                    title: Text('Auto Lock'),
                    subtitle: Text('Lock app when inactive'),
                    value: _autoLockEnabled,
                    onChanged: (value) {
                      setState(() {
                        _autoLockEnabled = value;
                      });
                      _saveSettings();
                    },
                  ),
                  if (_autoLockEnabled) ...[
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Auto Lock Timeout: $_autoLockTimeout minutes'),
                          Slider(
                            value: _autoLockTimeout.toDouble(),
                            min: 1,
                            max: 30,
                            divisions: 29,
                            label: '$_autoLockTimeout minutes',
                            onChanged: (value) {
                              setState(() {
                                _autoLockTimeout = value.toInt();
                              });
                              _saveSettings();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                  SwitchListTile(
                    title: Text('Auto Clear Clipboard'),
                    subtitle: Text('Clear clipboard automatically for security'),
                    value: _clipboardClearEnabled,
                    onChanged: (value) {
                      setState(() {
                        _clipboardClearEnabled = value;
                      });
                      _saveSettings();
                    },
                  ),
                  if (_clipboardClearEnabled) ...[
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Clipboard Clear Timeout: $_clipboardClearTimeout seconds'),
                          Slider(
                            value: _clipboardClearTimeout.toDouble(),
                            min: 10,
                            max: 120,
                            divisions: 11,
                            label: '$_clipboardClearTimeout seconds',
                            onChanged: (value) {
                              setState(() {
                                _clipboardClearTimeout = value.toInt();
                              });
                              _saveSettings();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data Management',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 16),
                  ListTile(
                    leading: Icon(Icons.delete_forever, color: Colors.red),
                    title: Text('Clear All Data'),
                    subtitle: Text('Delete all saved passwords and settings'),
                    onTap: _clearAllData,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 16),
                  ListTile(
                    leading: Icon(Icons.logout),
                    title: Text('Logout'),
                    subtitle: Text('Sign out of your account'),
                    onTap: _logout,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}