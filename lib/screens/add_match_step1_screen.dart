import 'package:flutter/material.dart';
import 'package:myfc_app/config/routes.dart';
import 'package:myfc_app/config/theme.dart';
import 'package:myfc_app/utils/validators.dart';
import 'package:myfc_app/widgets/common/app_button.dart';
import 'package:myfc_app/widgets/common/app_input.dart';
import 'package:intl/intl.dart';
import 'package:myfc_app/services/api_service.dart';
import 'package:myfc_app/services/storage_service.dart';
import 'package:myfc_app/widgets/common/app_card.dart';

class AddMatchStep1Screen extends StatefulWidget {
  const AddMatchStep1Screen({Key? key}) : super(key: key);

  @override
  State<AddMatchStep1Screen> createState() => _AddMatchStep1ScreenState();
}

class _AddMatchStep1ScreenState extends State<AddMatchStep1Screen> {
  final _formKey = GlobalKey<FormState>();
  final _opponentController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  int _selectedQuarters = 2; // Default to 2 quarters
  bool _isLoading = false;
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
  
  void _goToNextStep() {
    if (!_formKey.currentState!.validate()) return;
    
    Navigator.pushNamed(
      context,
      AppRoutes.addMatchStep2,
      arguments: {
        'date': _selectedDate,
        'opponent': _opponentController.text.trim(),
        'quarters': _selectedQuarters,
      },
    );
  }
  
  @override
  void dispose() {
    _opponentController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          '매치 추가',
          style: AppTextStyles.displaySmall,
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
          : _buildContent(),
    );
  }
  
  Widget _buildContent() {
    return Column(
      children: [
        _buildStepIndicator(),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildDateSelection(),
                    const SizedBox(height: 24),
                    _buildOpponentInput(),
                    const SizedBox(height: 24),
                    _buildQuarterSelection(),
                    const SizedBox(height: 24),
                    AppButton(
                      onPressed: _goToNextStep,
                      text: '다음',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: AppColors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStep(1, '기본 정보', false),
          _buildStep(2, '선수 선택', true),
          _buildStep(3, '점수 입력', true),
          _buildStep(4, '확인', true),
        ],
      ),
    );
  }
  
  Widget _buildStep(int step, String label, bool isCompleted) {
    final isCurrentStep = step == 1;
    final color = isCurrentStep ? AppColors.primary : AppColors.neutral;

    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isCurrentStep ? AppColors.primary : AppColors.white,
            border: Border.all(
              color: color,
              width: 2,
            ),
            shape: BoxShape.circle,
          ),
          child: isCompleted
              ? Icon(
                  Icons.check,
                  size: 16,
                  color: isCurrentStep ? AppColors.white : color,
                )
              : Text(
                  step.toString(),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isCurrentStep ? AppColors.white : color,
                  ),
                  textAlign: TextAlign.center,
                ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: color,
          ),
        ),
        if (step < 4) ...[
          const SizedBox(width: 8),
          Container(
            width: 24,
            height: 2,
            color: color,
          ),
          const SizedBox(width: 8),
        ],
      ],
    );
  }
  
  Widget _buildDateSelection() {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '경기 날짜',
              style: AppTextStyles.displayLarge.copyWith(
                color: AppColors.neutral,
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.neutral.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('yyyy-MM-dd').format(_selectedDate),
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.neutral,
                      ),
                    ),
                    Icon(
                      Icons.calendar_today,
                      color: AppColors.neutral.withOpacity(0.6),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOpponentInput() {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '상대팀',
              style: AppTextStyles.displayLarge.copyWith(
                color: AppColors.neutral,
              ),
            ),
            const SizedBox(height: 16),
            AppInput(
              label: '상대팀 이름',
              hint: '상대팀 이름을 입력해주세요',
              controller: _opponentController,
              validator: Validators.validateOpponentName,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuarterSelection() {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '쿼터 수',
              style: AppTextStyles.displayLarge.copyWith(
                color: AppColors.neutral,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [1, 2, 3, 4].map((quarter) {
                final isSelected = _selectedQuarters == quarter;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedQuarters = quarter;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.1)
                            : AppColors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.neutral.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        '$quarter쿼터',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.neutral,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
} 