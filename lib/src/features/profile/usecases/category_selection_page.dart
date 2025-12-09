import 'package:cultureyo/src/core/network/dio_client.dart';
import 'package:cultureyo/src/features/authentication/domain/usecases/auth_manager.dart';
import 'package:cultureyo/src/features/home.dart';
import 'package:cultureyo/src/features/profile/domain/user_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategorySelectionPage extends StatefulWidget {
  final int selectedYear;

  // final int selectedMonth;
  // final int selectedDay;
  final String name;

  const CategorySelectionPage({
    required this.name,
    required this.selectedYear,
    // required this.selectedMonth,
    // required this.selectedDay,
    super.key,
  });

  @override
  _CategorySelectionPageState createState() => _CategorySelectionPageState();
}

class _CategorySelectionPageState extends State<CategorySelectionPage> {
  final List<String> categories = [
    '국악',
    '기타',
    '무용/발레',
    '뮤지컬/오페라',
    '연극',
    '전시',
    '행사/축제',
    '교육/체험'
  ];
  final List<String> regions = [
    '강원',
    '경기',
    '경남',
    '경북',
    '광주',
    '대구',
    '대전',
    '부산',
    '서울',
    '세종',
    '울산',
    '인천',
    '제주',
    '전북',
    '전남',
    '충남',
    '충북',
  ];

  final Set<String> selectedCategories = {};
  final Set<String> selectedRegions = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.10),
                const Text('•선호 카테고리를 선택하세요',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categories.map((category) {
                    final isSelected = selectedCategories.contains(category);
                    return FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      selectedColor: Colors.blue.shade300,
                      showCheckmark: false,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            selectedCategories.add(category);
                          } else {
                            selectedCategories.remove(category);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                Divider(color: Colors.grey.shade300, thickness: 1, height: 32),
                const SizedBox(height: 24),
                const Text('•선호 지역을 선택하세요',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: regions.map((region) {
                    final isSelected = selectedRegions.contains(region);
                    return FilterChip(
                      label: Text(region),
                      selected: isSelected,
                      selectedColor: Colors.blue.shade300,
                      showCheckmark: false,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            selectedRegions.add(region);
                          } else {
                            selectedRegions.remove(region);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        selectedCategories.clear();
                        selectedRegions.clear();
                      });
                    },
                    child: const Text('선택 초기화',
                        style: TextStyle(color: Colors.grey)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 1, 16, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('이전')),
              ElevatedButton(
                onPressed: (selectedCategories.isNotEmpty ||
                        selectedRegions.isNotEmpty)
                    ? () async {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) {
                            return const Center(
                                child: CircularProgressIndicator());
                          },
                        );

                        try {
                          final userService = context.read<UserService>();
                          await userService.saveUserData(
                            name: widget.name,
                            year: widget.selectedYear,
                            categories: selectedCategories,
                            regions: selectedRegions,
                          );
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('isProfileComplete', true);

                          Navigator.pop(context); // 로딩 다이얼로그 닫기

                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => MainScreen()),
                            (route) => false,
                          );
                        } catch (e) {
                          Navigator.pop(context); // 로딩 다이얼로그 닫기
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('정보 저장 중 오류가 발생했습니다: $e')),
                          );
                        }
                      }
                    : null,
                child: const Text('다음'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
