
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'category_selection_page.dart'; // 다음 페이지 import

class BirthYearInputPage extends StatefulWidget {
  final String name;
  const BirthYearInputPage({
    required this.name,
    super.key,
  });
  @override
  _BirthYearInputPageState createState() => _BirthYearInputPageState();
}

class _BirthYearInputPageState extends State<BirthYearInputPage> {
  late int selectedYear;
  final int maxYear = 2006; // 1. 선택 가능한 최대 연도를 2006으로 지정
  final int minYear = 1950; // 선택 가능한 최소 연도

  @override
  void initState() {
    super.initState();
    selectedYear = maxYear;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.10),
                  const Text(
                    '출생연도를 입력하세요',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 150,
                          child: CupertinoPicker(
                            itemExtent: 40,
                            scrollController: FixedExtentScrollController(
                                initialItem: maxYear - minYear),
                            onSelectedItemChanged: (index) {
                              setState(() {
                                selectedYear = index + minYear;
                              });
                            },
                            children: List.generate(
                                maxYear - minYear + 1,
                                    (index) => Center(
                                    child: Text('${index + minYear}년'))),
                          ),
                        ),
                      ),
                      // Expanded(
                      //   child: SizedBox(
                      //     height: 150,
                      //     child: CupertinoPicker(
                      //       itemExtent: 40,
                      //       scrollController: FixedExtentScrollController(initialItem: selectedMonth - 1),
                      //       onSelectedItemChanged: (index) {
                      //         setState(() {
                      //           selectedMonth = index + 1;
                      //         });
                      //       },
                      //       children: List.generate(12, (index) => Center(child: Text('${index + 1}월'))),
                      //     ),
                      //   ),
                      // ),
                      // Expanded(
                      //   child: SizedBox(
                      //     height: 150,
                      //     child: CupertinoPicker(
                      //       itemExtent: 40,
                      //       scrollController: FixedExtentScrollController(initialItem: selectedDay - 1),
                      //       onSelectedItemChanged: (index) {
                      //         setState(() {
                      //           selectedDay = index + 1;
                      //         });
                      //       },
                      //       children: List.generate(getDaysInMonth(selectedYear, selectedMonth), (index) => Center(child: Text('${index + 1}일'))),
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(onPressed: () { Navigator.pop(context); }, child: const Text('이전')),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CategorySelectionPage(
                            name: widget.name,
                            selectedYear: selectedYear,
                            // selectedMonth: selectedMonth,
                            // selectedDay: selectedDay,
                          ),
                        ),
                      );
                    },
                    child: const Text('다음'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}