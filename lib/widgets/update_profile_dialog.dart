import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/custom_snackbar.dart';
import '../main.dart'; // for isSinhalaMode

class UpdateProfileDialog extends StatefulWidget {
  final String? currentFactoryCode;
  final String? currentRoute;
  final String? currentSupplierNo;
  final bool isFarmer;

  const UpdateProfileDialog({
    super.key,
    this.currentFactoryCode,
    this.currentRoute,
    this.currentSupplierNo,
    required this.isFarmer,
  });

  @override
  State<UpdateProfileDialog> createState() => _UpdateProfileDialogState();
}

class _UpdateProfileDialogState extends State<UpdateProfileDialog> {
  late TextEditingController _factoryCodeController;
  late TextEditingController _supplierNumberController;
  String? _selectedRoute;
  bool _isLoading = false;

  final List<String> _demoRoutes = [
    'Line 1 (North)',
    'Line 2 (South)',
    'Line 3 (East)',
    'Line 4 (West)',
  ];

  @override
  void initState() {
    super.initState();
    _factoryCodeController = TextEditingController(text: widget.currentFactoryCode);
    _supplierNumberController = TextEditingController(text: widget.currentSupplierNo);
    _selectedRoute = _demoRoutes.contains(widget.currentRoute) ? widget.currentRoute : null;
  }

  @override
  void dispose() {
    _factoryCodeController.dispose();
    _supplierNumberController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      await AuthService.instance.updateProfileDetails(
        factoryCode: _factoryCodeController.text.trim(),
        routeName: _selectedRoute,
        supplierNumber: widget.isFarmer ? _supplierNumberController.text.trim() : null,
      );
      
      if (!mounted) return;
      CustomSnackBar.showSuccess(context, isSinhalaMode.value ? 'විස්තර යාවත්කාලීන විය!' : 'Profile updated successfully!');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      CustomSnackBar.showError(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isSinhala = isSinhalaMode.value;
    
    return AlertDialog(
      title: Text(isSinhala ? 'ගිණුමේ විස්තර' : 'Update Profile Details'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _factoryCodeController,
              decoration: InputDecoration(
                labelText: isSinhala ? 'කර්මාන්තශාලා අංකය (Factory Code)' : 'Factory Code (e.g., ROS-123)', 
                border: const OutlineInputBorder()
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedRoute,
              decoration: InputDecoration(
                labelText: isSinhala ? 'මාර්ගය (Collection Route)' : 'Collection Route', 
                border: const OutlineInputBorder()
              ),
              items: _demoRoutes.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (val) => setState(() => _selectedRoute = val),
            ),
            if (widget.isFarmer) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _supplierNumberController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isSinhala ? 'සැපයුම්කරු අංකය (Supplier Number)' : 'Supplier Number', 
                  border: const OutlineInputBorder()
                ),
              ),
            ]
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(isSinhala ? 'අවලංගු කරන්න' : 'Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : Text(isSinhala ? 'සුරකින්න' : 'Save'),
        ),
      ],
    );
  }
}
