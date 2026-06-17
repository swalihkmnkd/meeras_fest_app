import 'package:flutter/material.dart';
import 'package:meeras_fest_app/resultProvider.dart';
import 'package:provider/provider.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    List buttons=[
      "All",
      'Music',
      'Music',
      'Malappattu',
      'Malappattu',
      'Burda',
      'Burda',
      'Quiz',
    ];
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 30,),
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Text("Result",style: TextStyle(color: Color(0xff1F2937),fontWeight: FontWeight.bold,fontSize: 18),),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Text("Check out the latest winners",style: TextStyle(color: Color(0xff6B7280),fontWeight: FontWeight.w400,fontSize: 12),),
          ),
          SizedBox(height: 41,
            child: ListView.separated(
              shrinkWrap: true,
             scrollDirection: Axis.horizontal,
             itemBuilder: (context, index) {
               return  Padding(
                 padding: const EdgeInsets.symmetric(vertical: 6.0),
                 child: Consumer<ResultProvider>(
                   builder: (context,resultPro,child) {
                     return InkWell(
                       onTap: (){
                         resultPro.selectResultButton(index);
                       },
                       child: Container(
                         decoration: BoxDecoration(
                           border: Border.all(
                             color: resultPro.resultButtonIndex==index? Color(0xFFFF8E53): Color(0xFFE5E7EB),
                             width: 1,
                           ),
                           borderRadius: BorderRadius.circular(9999),
                           gradient: LinearGradient(
                             begin: Alignment.centerRight,
                             end: Alignment.centerLeft,
                             colors:resultPro.resultButtonIndex==index? const [
                               Color(0xFFFF6B6B),
                               Color(0xFFFF8E53),
                             ]:const [Colors.white,Colors.white],
                           ),
                           boxShadow:resultPro.resultButtonIndex==index? [
                             BoxShadow(
                               color: Color(0x33FF6B6B),
                               blurRadius: 12,
                               offset: Offset(0, 6),
                             ),
                           ]:[],
                         ),
                         child: Padding(
                           padding: const EdgeInsets.symmetric(horizontal: 8.0),
                           child: Center(
                             child: Text(
                               buttons[index],
                               style: TextStyle(
                                 color:resultPro.resultButtonIndex==index? Colors.white:Color(0xff4B5563),
                                 fontSize: 12,
                                 fontWeight: FontWeight.w600,
                               ),
                             ),
                           ),
                         ),
                       ),
                     );
                   }
                 ),
               );
             }, separatorBuilder: (BuildContext context, int index) {
               return SizedBox(width: 6,);
            }, itemCount: buttons.length,

            ),
          ),
        ],
      ),
    );
  }
}
