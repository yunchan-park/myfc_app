import 'package:flutter/material.dart';
import 'package:myfc_app/config/routes.dart';
import 'package:myfc_app/utils/validators.dart';
import 'package:intl/intl.dart';

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
      appBar: AppBar(
        title: const Text('매치 추가'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.grey[300],
            height: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step indicator
                _buildStepIndicator(),
                const SizedBox(height: 32),
                
                // Date selection
                const Text(
                  '경기 날짜',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: Colors.grey[700],
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('yyyy년 MM월 dd일').format(_selectedDate),
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Opponent team name
                const Text(
                  '상대 구단명',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _opponentController,
                  decoration: const InputDecoration(
                    hintText: '상대 구단 이름을 입력해주세요',
                    prefixIcon: Icon(Icons.people),
                  ),
                  validator: Validators.validateOpponentName,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 24),
                
                // Quarter selection
                const Text(
                  '쿼터 선택',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildQuarterSelection(),
                const SizedBox(height: 32),
                
                // Next button
                ElevatedButton(
                  onPressed: _goToNextStep,
                  child: const Text('다음 단계로'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildStepIndicator() {
    return Row(
      children: [
        _buildStepCircle(1, true),
        _buildStepLine(),
        _buildStepCircle(2, false),
        _buildStepLine(),
        _buildStepCircle(3, false),
        _buildStepLine(),
        _buildStepCircle(4, false),
      ],
    );
  }
  
  Widget _buildStepCircle(int step, bool isActive) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? Colors.black : Colors.grey[300],
      ),
      child: Center(
        child: Text(
          '$step',
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
  
  Widget _buildStepLine() {
    return Expanded(
      child: Container(
        height: 2,
        color: Colors.grey[300],
      ),
    );
  }
  
  Widget _buildQuarterSelection() {
    return Row(
      children: [
        _buildQuarterOption(1),
        const SizedBox(width: 8),
        _buildQuarterOption(2),
        const SizedBox(width: 8),
        _buildQuarterOption(3),
        const SizedBox(width: 8),
        _buildQuarterOption(4),
      ],
    );
  }
  
  Widget _buildQuarterOption(int quarters) {
    final isSelected = _selectedQuarters == quarters;
    
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedQuarters = quarters;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '${quarters}쿼터',
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
} 