import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cultureyo/src/features/home.dart';

class NameInputPage extends StatefulWidget {
  @override
  _NameInputPageState createState() => _NameInputPageState();
}

class _NameInputPageState extends State<NameInputPage> {
  final TextEditingController _controller = TextEditingController();
  String name='';
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
                    '이름을 입력하세요',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '이름',
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      print("입력된 이름: ${_controller.text}");
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => BirthdayInputPage(name: _controller.text,)),
                      );
                    },
                    child: const Text('다음'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class BirthdayInputPage extends StatefulWidget {
  final name;
  const BirthdayInputPage({
    required this.name,   // 이름 필수로 받기
    super.key,
  });
  @override
  _BirthdayInputPageState createState() => _BirthdayInputPageState();

}

class _BirthdayInputPageState extends State<BirthdayInputPage> {
  int selectedMonth = 1;
  int selectedYear = 1;
  int curYear = DateTime.now().year;
  int selectedDay = 1;
  List<int> monthDays = [31,28,31,30,31,30,31,31,30,31,30,31];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
              child:Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.10),
                      const Text(
                        '생일을 입력하세요',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(child: Column(children: [
                            SizedBox(height: 150,
                              child: CupertinoPicker(
                                itemExtent: 40,
                                scrollController: FixedExtentScrollController(initialItem: curYear - 1950),
                                onSelectedItemChanged: (index){
                                  setState(() {
                                    selectedYear = index +1;
                                  });
                                },
                                children: List.generate(curYear - 1950+1, (index)=>Center(child: Text('${index+1950}년'),)),
                              ),)
                          ],)),
                          Expanded(child: Column(children: [
                            SizedBox(height: 150,
                              child: CupertinoPicker(
                                itemExtent: 40,
                                scrollController: FixedExtentScrollController(initialItem: selectedMonth - 1),
                                onSelectedItemChanged: (index){
                                  setState(() {
                                    selectedMonth = index +1;
                                  });
                                },
                                children: List.generate(12, (index)=>Center(child: Text('${index+1}월'),)),
                              ),)
                          ],)),
                          Expanded(child: Column(children: [
                            SizedBox(height: 150,
                              child: CupertinoPicker(
                                itemExtent: 40,
                                scrollController: FixedExtentScrollController(initialItem: selectedDay - 1),
                                onSelectedItemChanged: (index){
                                  setState(() {
                                    selectedDay = index +1;
                                  });
                                },
                                children: List.generate(monthDays[selectedMonth-1], (index)=>Center(child: Text('${index+1}일'),)),
                              ),)
                          ],) ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [ElevatedButton(onPressed: (){Navigator.pop(context);}, child: const Text('이전')),
                      ElevatedButton(onPressed: (){Navigator.push(context,MaterialPageRoute(builder: (context) => CategorySelectionPage(name: widget.name,selectedYear: selectedYear,selectedMonth: selectedMonth,selectedDay: selectedDay,)) );}, child: const Text('다음'),
                      )],
                  )
                ],
              )
          ),
        ),
      ),
    );
  }
}



class CategorySelectionPage extends StatefulWidget {
  final selectedMonth;
  final selectedYear;
  final selectedDay;
  final name;
  const CategorySelectionPage({
    required this.name,
    required this.selectedYear,
    required this.selectedMonth,
    required this.selectedDay,
    super.key,
  });
  @override
  _CategorySelectionPageState createState() => _CategorySelectionPageState();
}

class _CategorySelectionPageState extends State<CategorySelectionPage> {

  final List<String> categories = ['뮤지컬','콘서트','클래식','오페라','연극','행사','전시'];
  final List<String> regions = [
    '서울', '부산','인천', '대구', '광주', '대전','경기도','강원도','충청도','전라도','경상도','제주도'
  ];


  final Set<String> selectedCategories = {};
  final Set<String> selectedRegions = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appBar: PreferredSize(preferredSize: Size.fromHeight(30),child: AppBar(title: Text('컬쳐요 시작하기'),automaticallyImplyLeading: false,)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.10),
                const Text('•선호 카테고리를 선택하세요',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                    child: const Text('선택 초기화',style: TextStyle(color: Colors.grey),),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(padding: const EdgeInsets.fromLTRB(16,1,16,10),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //width: double.infinity,
              children: [ElevatedButton(onPressed: (){Navigator.pop(context);}, child: const Text('이전')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    //backgroundColor: Colors.blue
                  ),
                  onPressed: (selectedCategories.isNotEmpty ||
                      selectedRegions.isNotEmpty)
                      ? () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => MainScreen()),
                          (route) => false,
                    );
                  } : null,
                  child: const Text('다음',
                    //style: TextStyle(color: Colors.white),
                  ),
                ),]
          ),),
      ),
    );
  }
}

Future<void> saveUserData({
  required String name,
  required int year,
  required int month,
  required int day,
  required Set<String> categories,
  required Set<String> regions,
}) async {
  final birthDay = "$year-$month-$day";
  final data = {
    "name": name,
    "birth_day": birthDay,
    "preferred_categories": categories.toList(),
    "preferred_regions": regions.toList(),
  };
  //final response = await Supabase.instance.client.from("users").insert(data);

  //print("Inserted: $response");
}