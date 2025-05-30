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
  int _selectedQuarters = 4; // 기본값을 4쿼터로 변경
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
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.white,
              surface: AppColors.white,
              onSurface: AppColors.darkGray,
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
          '매치 등록',
          style: AppTextStyles.displaySmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.darkGray),
          onPressed: () => Navigator.pop(context),
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
                    Text(
                      '경기 기본 정보를 입력해주세요',
                      style: AppTextStyles.displayMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkGray,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    _buildDateSelection(),
                    const SizedBox(height: 24),
                    _buildOpponentInput(),
                    const SizedBox(height: 24),
                    _buildQuarterSelection(),
                    const SizedBox(height: 40),
                    AppButton(
                      onPressed: _goToNextStep,
                      text: '다음 단계로',
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
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      color: AppColors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStepDot(1, true),  // 현재 단계
          _buildStepLine(false),
          _buildStepDot(2, false),
          _buildStepLine(false),
          _buildStepDot(3, false),
          _buildStepLine(false),
          _buildStepDot(4, false),
        ],
      ),
    );
  }
  
  Widget _buildStepDot(int step, bool isActive) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.white,
        border: Border.all(
          color: isActive ? AppColors.primary : AppColors.neutral,
          width: 2,
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          step.toString(),
          style: AppTextStyles.bodyMedium.copyWith(
            color: isActive ? AppColors.white : AppColors.neutral,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
  
  Widget _buildStepLine(bool isCompleted) {
    return Container(
      width: 32,
      height: 2,
      color: isCompleted ? AppColors.primary : AppColors.neutral,
    );
  }
  
  Widget _buildDateSelection() {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '경기 날짜',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.darkGray,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _selectDate(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.white,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('yyyy년 MM월 dd일').format(_selectedDate),
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.darkGray,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_drop_down,
                      color: AppColors.neutral,
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
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '상대 구단',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.darkGray,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _opponentController,
              decoration: InputDecoration(
                hintText: '상대 구단의 이름을 입력해주세요',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.neutral,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.all(16),
                prefixIcon: Icon(
                  Icons.sports_soccer,
                  color: AppColors.primary,
                ),
              ),
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.darkGray,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '상대 구단 이름을 입력해주세요';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuarterSelection() {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '경기 쿼터 수',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.darkGray,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildQuarterOption(1)),
                const SizedBox(width: 12),
                Expanded(child: _buildQuarterOption(2)),
                const SizedBox(width: 12),
                Expanded(child: _buildQuarterOption(3)),
                const SizedBox(width: 12),
                Expanded(child: _buildQuarterOption(4)),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuarterOption(int quarters) {
    final isSelected = _selectedQuarters == quarters;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedQuarters = quarters;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.white,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.white,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.neutral,
                  width: 2,
                ),
                shape: BoxShape.circle,
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      size: 12,
                      color: AppColors.white,
                    )
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              '${quarters}쿼터',
              style: AppTextStyles.bodyMedium.copyWith(
                color: isSelected ? AppColors.primary : AppColors.darkGray,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 