import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:meeras_fest_app/result/resultProvider.dart';
import 'package:provider/provider.dart';

import '../home/home_screen.dart';

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
    final Map<String, Map<String, Color>> buttonColors = {
      "All": {
        "text": const Color(0xFFBE185D),
        "bg": const Color(0xFFFCE7F3),
        "border": const Color(0xFFFBCFE8),
      },
      "Music": {
        "text": const Color(0xFF1D4ED8),
        "bg": const Color(0xFFDBEAFE),
        "border": const Color(0xFFBFDBFE),
      },
      "Malappattu": {
        "text": const Color(0xFFC2410C),
        "bg": const Color(0xFFFFEDD5),
        "border": const Color(0xFFFED7AA),
      },
      "Burda": {
        "text": const Color(0xFFBE185D),
        "bg": const Color(0xFFFCE7F3),
        "border": const Color(0xFFFBCFE8),
      },
      "Quiz": {
        "text": const Color(0xFF1D4ED8),
        "bg": const Color(0xFFDBEAFE),
        "border": const Color(0xFFBFDBFE),
      },
    };
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
          SizedBox(height: 18,),
          SizedBox(height: 41,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0,vertical: 6),
              child: ListView.separated(
                shrinkWrap: true,
               scrollDirection: Axis.horizontal,
               itemBuilder: (context, index) {
                 return  Consumer<ResultProvider>(
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
                 );
               }, separatorBuilder: (BuildContext context, int index) {
                 return SizedBox(width: 6,);
              }, itemCount: buttons.length,

              ),
            ),
          ),
          SizedBox(height: 18,),
          Expanded(child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: buttons.length,
            itemBuilder: (context, index) {
           String  buttonText=buttons[index];
            final colors = buttonColors[buttonText]!;
            return  FadeSlideAnimation(
              order: 1,
              from: SlideFrom.bottom,
              child: Container(
                margin: EdgeInsets.only(right:13,left: 13,bottom: 13),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.2),
                      blurRadius: 8,
                      spreadRadius: 1,
                      offset: Offset(0, 3),
                    ),
                  ],
                  color: Colors.white,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(

                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Classical Dance",style: GoogleFonts.inter(fontSize: 10,fontWeight: FontWeight.bold,color: Color(0xff1F2937)),),
                      SizedBox(height: 8,),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          decoration: BoxDecoration(
                            color: colors["bg"],
                            border: Border.all(
                              color: colors["border"]!,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              buttons[index],
                              style: TextStyle(
                                color: colors["text"],
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 10,),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text("🥇",style: GoogleFonts.inter(fontSize: 16,),),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Alice Johnson",style: GoogleFonts.inter(fontSize: 10,fontWeight: FontWeight.w600,color: Color(0xff6B7280)),),
                                Text("Phoenix",style: GoogleFonts.inter(fontSize: 10,fontWeight: FontWeight.w400,color: Color(0xff6B7280)),),

                              ],
                            ),
                            Spacer(),

                            Container(
                              decoration: BoxDecoration(
                                color: Color(0xffFAF5FF),
                                borderRadius: BorderRadius.circular(9999),),
                              child: Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Text(
                                  '345 Pts',
                                  style:
                                  GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xff667EEA),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text("🥈",style: GoogleFonts.inter(fontSize: 16,),),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Alice Johnson",style: GoogleFonts.inter(fontSize: 10,fontWeight: FontWeight.w600,color: Color(0xff6B7280)),),
                                Text("Phoenix",style: GoogleFonts.inter(fontSize: 10,fontWeight: FontWeight.w400,color: Color(0xff6B7280)),),

                              ],
                            ),
                            Spacer(),

                            Container(
                              decoration: BoxDecoration(
                                color: Color(0xffFAF5FF),
                                borderRadius: BorderRadius.circular(9999),),
                              child: Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Text(
                                  '345 Pts',
                                  style:
                                  GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xff667EEA),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text("🥉",style: GoogleFonts.inter(fontSize: 16,),),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Alice Johnson",style: GoogleFonts.inter(fontSize: 10,fontWeight: FontWeight.w600,color: Color(0xff6B7280)),),
                                Text("Phoenix",style: GoogleFonts.inter(fontSize: 10,fontWeight: FontWeight.w400,color: Color(0xff6B7280)),),

                              ],
                            ),
                            Spacer(),

                            Container(
                              decoration: BoxDecoration(
                                color: Color(0xffFAF5FF),
                                borderRadius: BorderRadius.circular(9999),),
                              child: Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Text(
                                  '345 Pts',
                                  style:
                                  GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xff667EEA),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },))
        ],
      ),
    );
  }
}
