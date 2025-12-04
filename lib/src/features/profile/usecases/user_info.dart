// import 'package:cultureyo/src/core/network/dio_client.dart';
// import 'package:cultureyo/src/features/profile/domain/user_service.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:provider/provider.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:cultureyo/src/features/home.dart';
// import 'package:flutter/services.dart';
// class NameInputPage extends StatefulWidget {
//   const NameInputPage({super.key});
//   @override
//   _NameInputPageState createState() => _NameInputPageState();
// }
//
// class _NameInputPageState extends State<NameInputPage> {
//   final TextEditingController _controller = TextEditingController();
//   final bannedNames = [
//     // 시스템/관리 관련
//     '관리자', '운영자', 'Admin', 'Administrator', 'Root', 'SuperUser', 'System', 'Moderator', 'Mod', 'Staff',
//     // 욕설
//     '씨발', '병신', '개새끼', '좆', 'ㅂㅅ', 'ㅅㅂ', 'ㄲㅈ', '시발','애미','애비','ㅄ',
//     // 기타
//     'Test', 'Guest', 'Anonymous', '익명', '유저', 'User'
//   ];
//   String name='';
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Column(
//                 children: [
//                   SizedBox(height: MediaQuery.of(context).size.height * 0.10),
//                   const Text(
//                     '닉네임을 입력해 주세요',
//                     style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 16),
//                   TextField(
//                     controller: _controller,
//                     maxLength: 7,
//                     inputFormatters: [
//                       LengthLimitingTextInputFormatter(7),
//                       FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9ㄱ-ㅎ가-힣]')),
//                     ],
//                     decoration: const InputDecoration(
//                       border: OutlineInputBorder(),
//                       hintText: '닉네임',
//                     ),
//                   ),
//                   const SizedBox(height: 24),
//                 ],
//               ),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//                   ElevatedButton(
//                     onPressed: () {
//                       final enteredName = _controller.text.trim();
//                       final lowerBanned = bannedNames.map((e) => e.toLowerCase()).toList();
//                       bool isBanned = lowerBanned.any((b) => enteredName.contains(b));
//                       if (isBanned || enteredName.isEmpty) {
//                         showDialog(
//                           context: context,
//                           builder: (context) => AlertDialog(
//                             content: Text('사용할 수 없는 이름입니다.'),
//                             actions: [
//                               TextButton(
//                                 onPressed: () => Navigator.pop(context),
//                                 child: Text('확인'),
//                               ),
//                             ],
//                           ),
//                         );
//                         return;
//                       }
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(builder: (context) => BirthdayInputPage(name: _controller.text,)),
//                       );
//                     },
//                     child: const Text('다음'),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
// class BirthdayInputPage extends StatefulWidget {
//   final String name;
//   const BirthdayInputPage({
//     required this.name,   // 이름 필수로 받기
//     super.key,
//   });
//   @override
//   _BirthdayInputPageState createState() => _BirthdayInputPageState();
//
// }
//
// class _BirthdayInputPageState extends State<BirthdayInputPage> {
//   bool isLeapYear(int year) {
//     if (year % 4 != 0) return false;
//     if (year % 100 != 0) return true;
//     return year % 400 == 0;
//   }
//   int selectedMonth = 1;
//   int selectedYear = 2024;
//   int curYear = 2024;
//   int selectedDay = 1;
//   int getDaysInMonth(int year, int month) {
//     List<int> monthDays = [31,28,31,30,31,30,31,31,30,31,30,31];
//     if (month == 2 && isLeapYear(year)) {
//       return 29;
//     }
//     return monthDays[month - 1];
//   }
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Center(
//               child:Column(
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Column(
//                     children: [
//                       SizedBox(height: MediaQuery.of(context).size.height * 0.10),
//                       const Text(
//                         '생일을 입력하세요',
//                         style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                       ),
//                       const SizedBox(height: 16),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Expanded(child: Column(children: [
//                             SizedBox(height: 150,
//                               child: CupertinoPicker(
//                                 itemExtent: 40,
//                                 scrollController: FixedExtentScrollController(initialItem: curYear - 1950),
//                                 onSelectedItemChanged: (index){
//                                   setState(() {
//                                     selectedYear = index +1950;
//                                   });
//                                 },
//                                 children: List.generate(curYear - 1950+1, (index)=>Center(child: Text('${index+1950}년'),)),
//                               ),)
//                           ],)),
//                           Expanded(child: Column(children: [
//                             SizedBox(height: 150,
//                               child: CupertinoPicker(
//                                 itemExtent: 40,
//                                 scrollController: FixedExtentScrollController(initialItem: selectedMonth - 1),
//                                 onSelectedItemChanged: (index){
//                                   setState(() {
//                                     selectedMonth = index +1;
//                                   });
//                                 },
//                                 children: List.generate(12, (index)=>Center(child: Text('${index+1}월'),)),
//                               ),)
//                           ],)),
//                           Expanded(child: Column(children: [
//                             SizedBox(height: 150,
//                               child: CupertinoPicker(
//                                 itemExtent: 40,
//                                 scrollController: FixedExtentScrollController(initialItem: selectedDay - 1),
//                                 onSelectedItemChanged: (index){
//                                   setState(() {
//                                     selectedDay = index +1;
//                                   });
//                                 },
//                                 children: List.generate(getDaysInMonth(selectedYear,selectedMonth), (index)=>Center(child: Text('${index+1}일'),)),
//                               ),)
//                           ],) ),
//                         ],
//                       ),
//                     ],
//                   ),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [ElevatedButton(onPressed: (){Navigator.pop(context);}, child: const Text('이전')),
//                       ElevatedButton(onPressed: (){Navigator.push(context,MaterialPageRoute(builder: (context) => CategorySelectionPage(name: widget.name,selectedYear: selectedYear,selectedMonth: selectedMonth,selectedDay: selectedDay,)) );}, child: const Text('다음'),
//                       )],
//                   )
//                 ],
//               )
//           ),
//         ),
//       ),
//     );
//   }
// }
//
//
//
// class CategorySelectionPage extends StatefulWidget {
//   final int selectedMonth;
//   final int selectedYear;
//   final int selectedDay;
//   final String name;
//   const CategorySelectionPage({
//     required this.name,
//     required this.selectedYear,
//     required this.selectedMonth,
//     required this.selectedDay,
//     super.key,
//   });
//   @override
//   _CategorySelectionPageState createState() => _CategorySelectionPageState();
// }
//
// class _CategorySelectionPageState extends State<CategorySelectionPage> {
//
//   final List<String> categories = ['국악','기타','무용/발레','뮤지컬/오페라','연극','전시','행사/축제','교육/체험'];
//   final List<String> regions = [
//     '강원', '경기','경남', '경북', '광주', '대구','대전','부산','서울','세종','울산','인천'
//   ];
//
//
//   final Set<String> selectedCategories = {};
//   final Set<String> selectedRegions = {};
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       //appBar: PreferredSize(preferredSize: Size.fromHeight(30),child: AppBar(title: Text('컬쳐요 시작하기'),automaticallyImplyLeading: false,)),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: SingleChildScrollView(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 SizedBox(height: MediaQuery.of(context).size.height * 0.10),
//                 const Text('•선호 카테고리를 선택하세요',
//                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//                 const SizedBox(height: 8),
//                 Wrap(
//                   spacing: 8,
//                   runSpacing: 8,
//                   children: categories.map((category) {
//                     final isSelected = selectedCategories.contains(category);
//                     return FilterChip(
//                       label: Text(category),
//                       selected: isSelected,
//                       selectedColor: Colors.blue.shade300,
//                       showCheckmark: false,
//                       onSelected: (selected) {
//                         setState(() {
//                           if (selected) {
//                             selectedCategories.add(category);
//                           } else {
//                             selectedCategories.remove(category);
//                           }
//                         });
//                       },
//                     );
//                   }).toList(),
//                 ),
//                 const SizedBox(height: 24),
//                 Divider(color: Colors.grey.shade300, thickness: 1, height: 32),
//                 const SizedBox(height: 24),
//                 const Text('•선호 지역을 선택하세요',
//                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//                 const SizedBox(height: 8),
//                 Wrap(
//                   spacing: 8,
//                   runSpacing: 8,
//                   children: regions.map((region) {
//                     final isSelected = selectedRegions.contains(region);
//                     return FilterChip(
//                       label: Text(region),
//                       selected: isSelected,
//                       selectedColor: Colors.blue.shade300,
//                       showCheckmark: false,
//                       onSelected: (selected) {
//                         setState(() {
//                           if (selected) {
//                             selectedRegions.add(region);
//                           } else {
//                             selectedRegions.remove(region);
//                           }
//                         });
//                       },
//                     );
//                   }).toList(),
//                 ),
//                 const SizedBox(height: 12),
//                 Align(
//                   alignment: Alignment.centerRight,
//                   child: TextButton(
//                     onPressed: () {
//                       setState(() {
//                         selectedCategories.clear();
//                         selectedRegions.clear();
//                       });
//                     },
//                     child: const Text('선택 초기화',style: TextStyle(color: Colors.grey),),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//       bottomNavigationBar: SafeArea(
//         top: false,
//         child: Padding(padding: const EdgeInsets.fromLTRB(16,1,16,10),
//           child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               //width: double.infinity,
//               children: [ElevatedButton(onPressed: (){Navigator.pop(context);}, child: const Text('이전')),
//                 ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     //backgroundColor: Colors.blue
//                   ),
//                   onPressed: (selectedCategories.isNotEmpty ||
//                       selectedRegions.isNotEmpty)
//                       ? () async {
//                     showDialog(
//                       context: context,
//                       barrierDismissible: false,
//                       builder: (BuildContext context) {
//                         return const Center(child: CircularProgressIndicator());
//                       }
//                     );
//
//                     try {
//                       final dioClient = Provider.of<DioClient>(context, listen: false);
//                       await saveUserData(
//                         name: widget.name,
//                         year: widget.selectedYear,
//                         month: widget.selectedMonth,
//                         day: widget.selectedDay,
//                         categories: selectedCategories,
//                         regions: selectedRegions,
//                       );
//
//                       Navigator.pop(context);
//
//                       Navigator.pushAndRemoveUntil(context,
//                           MaterialPageRoute(builder: (_) => MainScreen()),
//                           (route) => false,
//                       );
//                     } catch(e) {
//                       Navigator.pop(context);
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(content: Text('정보 저장 중 오류가 발생했습니다: $e')),
//                       );
//                     }
//                   }
//                   : null,
//                   child: const Text('다음',
//                     //style: TextStyle(color: Colors.white),
//                   ),
//                 ),]
//           ),),
//       ),
//     );
//   }
// }
//
