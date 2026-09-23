import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/user_controller.dart';
import '../../core/constants/app_currency.dart';
import '../../core/services/service_request_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/ui_helper.dart';
import '../../models/service_category_model.dart';
import '../../models/service_request_model.dart';
import '../../models/user_model.dart';

/// Modal bottom sheet allowing a customer to book a service using either
/// 1) "Random Karigar" (Broadcast to all nearby specialists in category)
/// 2) "Specific Karigar" (Browse & choose a specific verified specialist)
class CreateBookingModal extends StatefulWidget {
  final ServiceCategory category;
  final VoidCallback? onBookingCreated;

  const CreateBookingModal({
    super.key,
    required this.category,
    this.onBookingCreated,
  });

  static Future<void> show({
    required BuildContext context,
    required ServiceCategory category,
    VoidCallback? onBookingCreated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CreateBookingModal(
        category: category,
        onBookingCreated: onBookingCreated,
      ),
    );
  }

  @override
  State<CreateBookingModal> createState() => _CreateBookingModalState();
}

class _CreateBookingModalState extends State<CreateBookingModal> {
  final _formKey = GlobalKey<FormState>();
  final ServiceRequestService _requestService = ServiceRequestService();

  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _addressController;
  late final TextEditingController _amountController;

  String _dispatchMode = RequestDispatchType.broadcast; // 'broadcast' or 'specific'
  UserModel? _selectedProvider;
  List<UserModel> _availableProviders = [];
  bool _isLoadingProviders = false;
  bool _isSubmitting = false;

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    String defaultTitle = '${widget.category.name} Service';
    if (widget.category.id == 'appliance_repair') {
      defaultTitle = 'AC Repair & Servicing';
    } else if (widget.category.id == 'plumbing') {
      defaultTitle = 'Pipe Leak & Tap Repair';
    } else if (widget.category.id == 'electrical') {
      defaultTitle = 'Switchboard & Wiring Fix';
    }

    _titleController = TextEditingController(text: defaultTitle);
    _descController = TextEditingController();
    _addressController = TextEditingController(text: 'Home / Primary Residence');
    _amountController = TextEditingController(text: '1200');

    _fetchProviders();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _addressController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _fetchProviders() async {
    setState(() => _isLoadingProviders = true);
    final providers = await _requestService.getVerifiedProvidersForCategory(widget.category.id);
    if (mounted) {
      setState(() {
        _availableProviders = providers;
        _isLoadingProviders = false;
        if (_availableProviders.isNotEmpty) {
          _selectedProvider = _availableProviders.first;
        }
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.accent),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.accent),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _onSubmitBooking() async {
    if (!_formKey.currentState!.validate()) return;

    if (_dispatchMode == RequestDispatchType.specific && _selectedProvider == null) {
      UiHelper.showSnackBar(
        context,
        'Please select a specific Karigar from the list',
        isError: true,
      );
      return;
    }

    final user = context.read<UserController>().user;
    final double amount = double.tryParse(_amountController.text.trim()) ?? 1200.0;
    final String dateStr =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    final String timeStr = _selectedTime.format(context);

    setState(() => _isSubmitting = true);

    try {
      await _requestService.createRequest(
        customerId: user.uid,
        customerName: user.name.isNotEmpty ? user.name : 'Customer',
        customerPhone: user.phone,
        customerAddress: _addressController.text.trim(),
        categoryId: widget.category.id,
        categoryName: widget.category.name,
        serviceTitle: _titleController.text.trim(),
        description: _descController.text.trim().isNotEmpty
            ? _descController.text.trim()
            : 'Standard on-demand service request',
        estimatedAmount: amount,
        scheduledDate: dateStr,
        scheduledTime: timeStr,
        requestType: _dispatchMode,
        targetProviderId: _dispatchMode == RequestDispatchType.specific
            ? _selectedProvider?.uid
            : null,
        targetProviderName: _dispatchMode == RequestDispatchType.specific
            ? _selectedProvider?.name
            : null,
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
        Navigator.of(context).pop();

        final msg = _dispatchMode == RequestDispatchType.broadcast
            ? 'Broadcast request sent to all verified ${widget.category.name} Karigars!'
            : 'Direct request sent to ${_selectedProvider?.name}!';
        UiHelper.showSnackBar(context, msg);
        widget.onBookingCreated?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        UiHelper.showSnackBar(context, 'Failed to book service: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.90;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag indicator
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.category.accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.category.icon,
                    color: widget.category.accentColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Book ${widget.category.name}',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        'Choose dispatch method & service details',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.secondaryText),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          // Form Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // STEP 1: Two-way Dispatch Selection
                    Text(
                      'Choose How to Request Karigar:',
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Option A: Random Karigar (Broadcast)
                    _buildDispatchOptionCard(
                      type: RequestDispatchType.broadcast,
                      title: 'Random Karigar (Quick Broadcast)',
                      subtitle:
                          'Broadcast your job to all verified ${widget.category.name} Karigars. The first available provider will accept and assist you.',
                      icon: Icons.cell_tower_rounded,
                      accentColor: AppColors.accent,
                    ),

                    const SizedBox(height: 10),

                    // Option B: Specific Karigar (Direct)
                    _buildDispatchOptionCard(
                      type: RequestDispatchType.specific,
                      title: 'Specific Karigar (Choose Karigar)',
                      subtitle:
                          'Browse and choose a specific verified specialist based on their rating, completed tasks, and contact.',
                      icon: Icons.person_pin_rounded,
                      accentColor: Colors.purple,
                    ),

                    // Specific Provider Picker List
                    if (_dispatchMode == RequestDispatchType.specific) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Select Verified Karigar:',
                        style: AppTextStyles.labelMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_isLoadingProviders)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: CircularProgressIndicator(color: AppColors.accent),
                          ),
                        )
                      else if (_availableProviders.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.amber, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'No specific specialists available for this trade right now. Please use "Random Karigar (Quick Broadcast)".',
                                  style: TextStyle(fontSize: 12, color: Colors.amber),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _availableProviders.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, idx) {
                            final provider = _availableProviders[idx];
                            final isSelected = _selectedProvider?.uid == provider.uid;

                            return InkWell(
                              onTap: () {
                                setState(() => _selectedProvider = provider);
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.purple.withValues(alpha: 0.08)
                                      : AppColors.background,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? Colors.purple : AppColors.border,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: isSelected ? Colors.purple : AppColors.accent,
                                      child: Text(
                                        provider.name.isNotEmpty
                                            ? provider.name[0].toUpperCase()
                                            : 'K',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                provider.name,
                                                style: AppTextStyles.titleSmall.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              const Icon(
                                                Icons.verified_rounded,
                                                size: 14,
                                                color: AppColors.success,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Specialist • ${provider.phone}',
                                            style: AppTextStyles.caption.copyWith(
                                              color: AppColors.secondaryText,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected ? Colors.purple : AppColors.secondaryText,
                                          width: isSelected ? 6.5 : 2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                    ],

                    const SizedBox(height: 20),
                    const Divider(color: AppColors.border),
                    const SizedBox(height: 16),

                    // STEP 2: Service Job Details
                    Text(
                      'Job & Location Details',
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Service Title
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Service Requirement',
                        hintText: 'e.g. AC Gas Refill, Water Leak Fix',
                        prefixIcon: const Icon(Icons.build_outlined, color: AppColors.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) =>
                          (val == null || val.trim().isEmpty) ? 'Enter service requirement' : null,
                    ),

                    const SizedBox(height: 12),

                    // Problem Description
                    TextFormField(
                      controller: _descController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Description / Problem Notes (Optional)',
                        hintText: 'Describe issue details, appliance brand, or floor no.',
                        prefixIcon: const Icon(Icons.description_outlined, color: AppColors.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Service Address / Location
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: 'Service Address / Location',
                        hintText: 'Enter street address, building, or landmark',
                        prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) =>
                          (val == null || val.trim().isEmpty) ? 'Please enter address' : null,
                    ),

                    const SizedBox(height: 12),

                    // Date & Time Picker Row
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _selectDate,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_month_rounded,
                                      size: 18, color: AppColors.accent),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: _selectTime,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time_rounded,
                                      size: 18, color: AppColors.accent),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _selectedTime.format(context),
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Estimated Budget / Price
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Estimated Budget / Offering',
                        prefixText: '${AppCurrency.symbol} ',
                        prefixIcon: const Icon(AppCurrency.icon, color: AppColors.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Enter budget amount';
                        if (double.tryParse(val.trim()) == null) return 'Enter a valid number';
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: AppDimensions.buttonHeight,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _dispatchMode == RequestDispatchType.broadcast
                              ? AppColors.accent
                              : Colors.purple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 2,
                        ),
                        onPressed: _isSubmitting ? null : _onSubmitBooking,
                        child: _isSubmitting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _dispatchMode == RequestDispatchType.broadcast
                                        ? Icons.send_rounded
                                        : Icons.person_search_rounded,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _dispatchMode == RequestDispatchType.broadcast
                                        ? 'Send Broadcast to Karigars'
                                        : 'Send Request to Selected Karigar',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDispatchOptionCard({
    required String type,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    final isSelected = _dispatchMode == type;

    return InkWell(
      onTap: () {
        setState(() => _dispatchMode = type);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withValues(alpha: 0.08) : AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accentColor : AppColors.border,
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.secondaryText,
                      height: 1.3,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? accentColor : AppColors.secondaryText,
                  width: isSelected ? 6.5 : 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
