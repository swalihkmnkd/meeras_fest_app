import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Column(
          children: [
            animatedWidget(
              from: SlideFrom.top,
              child: Center(
                child: Column(

                children: [
                  SizedBox(height: 50,),
                  Text("🎨 🎭 🎪 🎵",style:  TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),),
                  ShaderMask(
                    shaderCallback: (bounds) {
                      return const LinearGradient(
                        colors: [
                          Color(0xFFFF6B6B), // stop 0%
                          Color(0xFFFF8E53), // stop 50%
                          Color(0xFF667EEA), // stop 100%
                        ],
                        stops: [0.0, 0.5, 1.0],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ).createShader(bounds);
                    },
                    child: const Text(
                      "MEERAS FEST 2K27",
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    textAlign: TextAlign.center,
                    "Meerasul Ambiya Heigher secondary Madrassa\noravampuram",
                    style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold,color: Color(0xff6B7280)),
                  ),
                ],
                          ),
              ),),
            SizedBox(height: 15,),
            Row(
              children: [
                Expanded(
                    child:  animatedWidget(
                      from: SlideFrom.bottom,
                      child:Container(
                        height: 90,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 10,
                              spreadRadius: 2,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              backgroundColor: Color(0xffFFEDD5),
                              radius: 18,
                              child: SvgPicture.asset(
                                "assets/icons/resultIcon.svg",
                                colorFilter: ColorFilter.mode(Color(0xffFF8E53), BlendMode.srcIn),
                              ),
                            ),
                            Text("Result",
                            style: TextStyle(
                              color: Color(0xff1F2937),
                              fontWeight: FontWeight.w400,
                              fontSize: 15,
                            ),)
                          ],
                        ),
                      ),
                    ),
                  ),

                SizedBox(width: 10,),
                Expanded(
                  child: animatedWidget(
                    from: SlideFrom.bottom,
                    child:Container(
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 10,
                            spreadRadius: 2,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            backgroundColor: Color(0xffFFEDD5),
                            radius: 18,
                            child: Icon(Icons.login_rounded,size: 18,color: Color(0xff667EEA),),
                          ),
                          Text("Result",
                            style: TextStyle(
                              color: Color(0xff1F2937),
                              fontWeight: FontWeight.w400,
                              fontSize: 15,
                            ),)
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Latest Winners",style: TextStyle(fontSize: 13,fontWeight: FontWeight.bold,color: Color(0xff1F2937)),),
                SizedBox(
                  child: Row(
                    children: [
                      Text("View All",style: TextStyle(fontSize: 10,fontWeight: FontWeight.w400,color: Color(0xff667EEA)),),
                      Icon(Icons.arrow_forward_outlined,color: Color(0xff667EEA),size: 12,)
                    ],
                  ),
                )
              ],
            ),
            SizedBox(height: 12,),
            SizedBox(
              height: 150,

              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                return animatedWidget(
                  from: SlideFrom.right,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0,vertical: 10),
                    child: Container(
                      width: 240,
                      height: 140,
                      margin: EdgeInsets.only(right:10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
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
                            Text("Song",style: TextStyle(fontSize: 10,fontWeight: FontWeight.w400,color: Color(0xff6B7280)),),
                            SizedBox(height: 10,),
                            Text("Classical Dance",style: TextStyle(fontSize: 10,fontWeight: FontWeight.bold,color: Color(0xff1F2937)),),
                            SizedBox(height: 10,),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                                color: Color(0xffF9FAFB),
                              ),
                              child:Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                      child: Text("🥇",style: TextStyle(fontSize: 16,),),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text("Alice Johnson",style: TextStyle(fontSize: 10,fontWeight: FontWeight.w600,color: Color(0xff6B7280)),),
                                        Text("Phoenix",style: TextStyle(fontSize: 10,fontWeight: FontWeight.w400,color: Color(0xff6B7280)),),

                                      ],
                                    ),

                                  ],
                                ),
                              ) ,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },),
            )

          ],
        ),
      ),
    );
  }
}
enum SlideFrom { top, bottom, left, right }


Widget animatedWidget({
  required Widget child,
  SlideFrom from = SlideFrom.top,
  double distance = 100, // how far it moves
  int durationMs = 600,
}) {
  Offset beginOffset;

  switch (from) {
    case SlideFrom.top:
      beginOffset = const Offset(0, -1);
      break;
    case SlideFrom.bottom:
      beginOffset = const Offset(0, 1);
      break;
    case SlideFrom.left:
      beginOffset = const Offset(-1, 0);
      break;
    case SlideFrom.right:
      beginOffset = const Offset(1, 0);
      break;
  }

  return TweenAnimationBuilder<Offset>(
    duration: Duration(milliseconds: durationMs),
    tween: Tween(begin: beginOffset, end: const Offset(0, 0)),
    curve: Curves.easeOut,
    builder: (context, value, child) {
      return Transform.translate(
        offset: Offset(
          value.dx * distance,
          value.dy * distance,
        ),
        child: child,
      );
    },
    child: child,
  );
}