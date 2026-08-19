import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:society_app/SocietyApp/screens/gatepass.dart';
import 'package:society_app/presentation/providers/viewModel_provider.dart';
 
enum EntryType { guest, cab, service, delivery }
 
class VisitorManagementDialogs {
  static Future<void> showAddEntryDialog(
    BuildContext context,
    WidgetRef ref, {
    required EntryType type,
  }) async {
    // Controllers
    final nameController = TextEditingController();
    final contactController = TextEditingController();
    final dateController = TextEditingController();
    final companyController = TextEditingController();
    final vehicleController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String selectedDeliveryOption = 'doorstep';
    bool isLoading = false;
 
    // Titles, Icons & Colors per type
    final config = {
      EntryType.guest: {
        'title': 'Add Guest',
        'icon': Icons.person_add,
        'colors': [Colors.green.shade600, Colors.green.shade400],
      },
      EntryType.cab: {
        'title': 'Add Cab',
        'icon': Icons.local_taxi,
        'colors': [Colors.orange.shade600, Colors.orange.shade400],
      },
      EntryType.service: {
        'title': 'Add Service',
        'icon': Icons.home_repair_service,
        'colors': [Colors.blue.shade600, Colors.blue.shade400],
      },
      EntryType.delivery: {
        'title': 'Add Delivery',
        'icon': Icons.local_shipping,
        'colors': [Colors.indigo.shade600, Colors.indigo.shade400],
      },
    };
 
    // Submit Logic per type
    // Future<void> handleSubmit(void Function(void Function()) setState) async {
    //   if (!(formKey.currentState?.validate() ?? false)) return;
    //   setState(() => isLoading = true);
 
    //   final notifier = ref.read(visitorViewModelProvider.notifier);
    //   final info = ref.watch(basicInfoViewModelProvider);
 
    //   notifier.reset();
 
    //   switch (type) {
    //     case EntryType.guest:
    //       await notifier.addGuest(
    //         nameController.text.trim(),
    //         dateController.text.trim(),
    //         contactController.text.trim(),
    //         info.societyID!,
    //         info.ownerId!,
    //         info.flatId!
          
         
    //       );
    //       break;
 
    //     case EntryType.cab:
    //       await notifier.addCab(
         
    //         nameController.text.trim(),
    //         vehicleController.text.trim(),
    //         dateController.text.trim(),
    //         contactController.text.trim(),
    //         companyController.text.trim(),
    //         info.societyID!,
    //         info.ownerId!,
    //         info.flatId!
            
    //       );
    //       break;
 
    //     case EntryType.service:
    //       await notifier.addService(
         
    //         nameController.text.trim(),
    //         dateController.text.trim(),
    //         contactController.text.trim(),
    //         companyController.text.trim(),
    //         info.societyID!,
    //         info.ownerId!,
    //         info.flatId!

    //       );
    //       break;
 
    //     case EntryType.delivery:
    //       await notifier.addDelivery(
      
    //         nameController.text.trim(),
    //         dateController.text.trim(),
    //         contactController.text.trim(),
    //         selectedDeliveryOption,
    //         companyController.text.trim(),
    //         info.societyID!,
    //         info.ownerId!,
    //         info.flatId!
    //       );
    //       break;
    //   }
 
    //   setState(() => isLoading = false);
 
    //   final visitor = ref.read(visitorViewModelProvider).data;
    //   if (visitor != null && visitor['gateOtp'] != null) {
    //     Navigator.of(context).pop();
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(
    //         content: Text("${config[type]!['title']} added successfully!"),
    //         backgroundColor: Colors.green,
    //         duration: const Duration(seconds: 2),
    //       ),
    //     );
 
    //     Navigator.push(
    //       context,
    //       MaterialPageRoute(
    //         builder: (_) => GatePassScreen(
    //           guestName:
    //               nameController.text.isNotEmpty ? nameController.text : 'Unknown',
    //           otp: visitor['gateOtp'].toString(),
    //           flatNo: info.unit ?? 'N/A',
    //         ),
    //       ),
    //     ).then((_) => notifier.reset());
    //   } else if (ref.read(visitorViewModelProvider).error != null) {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(content: Text(ref.read(visitorViewModelProvider).error!)),
    //     );
    //   }
    // }
    Future<void> handleSubmit(void Function(void Function()) setState) async {
  if (!(formKey.currentState?.validate() ?? false)) return;

  final notifier = ref.read(visitorViewModelProvider.notifier);
  final info = ref.read(basicInfoViewModelProvider);

  notifier.reset();

  switch (type) {
    case EntryType.guest:
      await notifier.addGuest(
        nameController.text.trim(),
        dateController.text.trim(),
        contactController.text.trim(),
        info.societyID!,
        info.ownerId!,
        info.flatId!,
      );
      break;

    case EntryType.cab:
      await notifier.addCab(
        nameController.text.trim(),
        vehicleController.text.trim(),
        dateController.text.trim(),
        contactController.text.trim(),
        companyController.text.trim(),
        info.societyID!,
        info.ownerId!,
        info.flatId!,
      );
      break;

    case EntryType.service:
      await notifier.addService(
        nameController.text.trim(),
        dateController.text.trim(),
        contactController.text.trim(),
        companyController.text.trim(),
        info.societyID!,
        info.ownerId!,
        info.flatId!,
      );
      break;

    case EntryType.delivery:
      await notifier.addDelivery(
        nameController.text.trim(),
        dateController.text.trim(),
        contactController.text.trim(),
        selectedDeliveryOption,
        companyController.text.trim(),
        info.societyID!,
        info.ownerId!,
        info.flatId!,
      );
      break;
  }

  final state = ref.read(visitorViewModelProvider);

  // if (state.data != null && state.data!['gateOtp'] != null) {
  //   Navigator.of(context).pop(); // dialog close immediately

  //   Navigator.pushReplacement(
  //     context,
  //     MaterialPageRoute(
  //       builder: (_) => GatePassScreen(
  //         guestName: nameController.text.isNotEmpty
  //             ? nameController.text
  //             : 'Unknown',
  //         otp: state.data!['gateOtp'].toString(),
  //         flatNo: info.unit ?? 'N/A',
  //       ),
  //     ),
  //   );

  //   notifier.reset();
  // } else if (state.error != null) {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(content: Text(state.error!)),
  //   );
  // }
 

if (state.data != null && state.data!['gateOtp'] != null) {

  // 1️⃣ Close dialog safely
  Navigator.of(context, rootNavigator: true).pop();

  // 2️⃣ Open GatePass safely
  Future.microtask(() {
 Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => GatePassScreen( guestName: nameController.text.isNotEmpty
              ? nameController.text
              : 'Unknown',
          otp: state.data!['gateOtp'].toString(),
          flatNo: info.unit ?? 'N/A',))
);

  });

  notifier.reset();
}
else if (state.error != null) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(state.error!)),
  );
}

    }
    // Build form dynamically
    List<Widget> formFields = [];
 
    // Common name field
    formFields.add(_buildTextField(
      controller: nameController,
      label: type == EntryType.cab
          ? 'Driver Name'
          : type == EntryType.service
              ? 'Service Person Name'
              : type == EntryType.delivery
                  ? 'Delivery Person Name'
                  : 'Guest Name',
      icon: Icons.person,
      validator: (v) => v!.isEmpty ? 'Please enter name' : null,
    ));
 
    if (type != EntryType.guest) {
      // Company for cab, service, delivery
      formFields.add(const SizedBox(height: 12));
      formFields.add(_buildTextField(
        controller: companyController,
        label: 'Company Name',
        icon: Icons.business,
        validator: (v) =>
            (type == EntryType.service || type == EntryType.cab || type == EntryType.delivery)
                ? (v!.isEmpty ? 'Please enter company name' : null)
                : null,
      ));
    }
 
    // Contact number (all types)
    formFields.add(const SizedBox(height: 12));
    formFields.add(_buildTextField(
      controller: contactController,
      label: 'Contact Number',
      icon: Icons.phone,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      validator: (v) =>
          v!.length != 10 ? 'Contact number must be 10 digits' : null,
    ));
 
    // Vehicle field for Cab
    if (type == EntryType.cab) {
      formFields.add(const SizedBox(height: 12));
      formFields.add(_buildTextField(
        controller: vehicleController,
        label: 'Last 4 Digits of Vehicle No.',
        icon: Icons.directions_car,
        inputFormatters: [
          LengthLimitingTextInputFormatter(4),
          FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
        ],
        validator: (v) =>
            v!.length != 4 ? 'Must be exactly 4 characters' : null,
      ));
    }
 
    // Date field for all
    formFields.add(const SizedBox(height: 12));
    formFields.add(_buildDateField(
      context: context,
      controller: dateController,
      label: type == EntryType.service
          ? 'Service Date'
          : type == EntryType.delivery
              ? 'Delivery Date'
              : 'Expected Date',
      icon: Icons.calendar_today,
    ));
 
    // Delivery options (Gate / Doorstep)
    // if (type == EntryType.delivery) {
    //   formFields.add(const SizedBox(height: 20));
    //   formFields.add(Text(
    //     'Delivery Location:',
    //     style: TextStyle(
    //         fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[700]),
    //   ));
    //   formFields.add(const SizedBox(height: 8));
    //   formFields.add(Container(
    //     decoration: BoxDecoration(
    //       borderRadius: BorderRadius.circular(12),
    //       border: Border.all(color: Colors.grey.shade300),
    //     ),
    //     child: Column(
    //       children: [
    //         RadioListTile<String>(
    //           title: const Text('Doorstep'),
    //           value: 'doorstep',
    //           groupValue: selectedDeliveryOption,
    //           onChanged: (v) => selectedDeliveryOption = v!,
    //         ),
    //         RadioListTile<String>(
    //           title: const Text('Gate'),
    //           value: 'gate',
    //           groupValue: selectedDeliveryOption,
    //           onChanged: (v) => selectedDeliveryOption = v!,
    //         ),
    //       ],
    //     ),
    //   ));
    // }
    if (type == EntryType.delivery) {
  formFields.add(const SizedBox(height: 20));
  formFields.add(Text(
    'Delivery Location:',
    style: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Colors.grey[700],
    ),
  ));
  formFields.add(const SizedBox(height: 8));
  formFields.add(
    StatefulBuilder(
      builder: (context, setState) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              RadioListTile<String>(
                title: const Text('Doorstep'),
                value: 'doorstep',
                groupValue: selectedDeliveryOption,
                onChanged: (v) {
                  setState(() {
                    selectedDeliveryOption = v!;
                  });
                },
              ),
              RadioListTile<String>(
                title: const Text('Gate'),
                value: 'gate',
                groupValue: selectedDeliveryOption,
                onChanged: (v) {
                  setState(() {
                    selectedDeliveryOption = v!;
                  });
                },
              ),
            ],
          ),
        );
      },
    ),
  );
}

 
    // Show dialog
    await _showVisitorDialog(
      context: context,
      title: config[type]!['title'] as String,
      icon: config[type]!['icon'] as IconData,
      gradientColors: config[type]!['colors'] as List<Color>,
      submitText: config[type]!['title'] as String,
      onSubmit: handleSubmit,
      formContent: Form(
        key: formKey,
        child: Column(children: formFields),
      ),
    );
  }
 
  // Helper: Text field builder
  static Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
 
  // Helper: Date field builder
  static Widget _buildDateField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      validator: (v) => v!.isEmpty ? 'Please select a date' : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) {
          controller.text =
              "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
        }
      },
    );
  }
 
  
static Future<void> _showVisitorDialog({
  required BuildContext context,
  required String title,
  required IconData icon,
  required List<Color> gradientColors,
  required Widget formContent,
  required Future<void> Function(void Function(void Function())) onSubmit,
  required String submitText,
}) async {
  bool isLoading = false;
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(builder: (context, setState) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header (Fixed)
              Container(
                padding: const EdgeInsets.all(20),
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradientColors),
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20)),
                ),
                child: Row(children: [
                  Icon(icon, color: Colors.white),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    ),
                  )
                ]),
              ),
              // Scrollable Form Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: formContent,
                ),
              ),
              // Buttons (Fixed at bottom)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 15),
                child: Row(children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade300,
                        foregroundColor: Colors.grey.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      // onPressed:
                      //     isLoading ? null : () => onSubmit(setState),
                      onPressed: isLoading
    ? null
    : () async {
        setState(() => isLoading = true);
        await onSubmit(setState);
      },

                      style: ElevatedButton.styleFrom(
                        backgroundColor: gradientColors.first,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                     // child: Text(submitText),
                     child: isLoading
    ? const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white,
        ),
      )
    : Text(submitText),

                    ),
                  ),
                ]),
              )
            ],
          ),
        );
      });
    },
  );
}

}
 
 