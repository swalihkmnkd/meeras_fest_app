import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meeras_fest_app/adminProvider.dart';
import 'package:provider/provider.dart';
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    List<Map<String,dynamic>>tile=[
      {"title":'5',
      'subTitle':"Total Programs",
      'icon':'assets/icons/musicIcon.svg',
      'iconColor':Color(0xff3B82F6),
      'backColor':Color(0xffDBEAFE)},
      {"title":'4',
      'subTitle':"Registrations",
      'icon':'assets/icons/registerIcon.svg',
      'iconColor':Color(0xff22C55E),
      'backColor':Color(0xffDCFCE7)},
      {"title":'4',
      'subTitle':"Teams",
      'icon':'assets/icons/teamsIcon.svg',
      'iconColor':Color(0xffF97316),
      'backColor':Color(0xffFFEDD5)},
      {"title":'3',
      'subTitle':"Judges",
      'icon':'assets/icons/judgeIcon.svg',
      'iconColor':Color(0xffA855F7),
      'backColor':Color(0xffF3E8FF)},
    ];
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 30,),
            Text("Admin Panel",style: TextStyle(color: Color(0xff1F2937),fontSize: 18,fontWeight: FontWeight.bold),),
            Text("Manage festival operations",style: TextStyle(color: Color(0xff6B7280),fontSize: 12),),
            Container(height: 33,
            decoration: BoxDecoration(
              color: Color(0xAAE5E7EB),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Consumer<AdminProvider>(
                builder: (context,adminPro,child) {
                  return Row(
                    children: [

                      Expanded(
                          child: GestureDetector(
                            onTap: (){
                              adminPro.changeAnalyticTab(false);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(9),
                                color: !adminPro.isAnalyticTab?Colors.white:null,
                              ),
                              child:  Center(child: Text("Overview",style: TextStyle(color:!adminPro.isAnalyticTab?Colors.black: Color(0xff6B7280),fontSize: 15),)),
                            ),
                          ),
                        ),
                    Expanded(
                          child: GestureDetector(
                            onTap: (){
                              adminPro.changeAnalyticTab(true);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(9),
                                color: adminPro.isAnalyticTab?Colors.white:null,
                              ),
                              child:  Center(child: Text("Analytics",style: TextStyle(color: adminPro.isAnalyticTab?Colors.black: Color(0xff6B7280),fontSize: 15),)),
                            ),
                          ),
                        ),
                    ],
                  );
                }
              ),
            ),),
          GridView.builder(
            shrinkWrap: true,
            itemCount: tile.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 2,
            ), itemBuilder: (context, index) {
            return   Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:tile[index]['backColor'],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SvgPicture.asset(tile[index]['icon'],height: 15,width: 15,colorFilter: ColorFilter.mode(tile[index]['iconColor'], BlendMode.srcIn),),
                  ),
                  Text(tile[index]['title'],style: TextStyle(color: Colors.black,fontSize: 12,fontWeight: FontWeight.bold),),
                  Text(tile[index]['subTitle'],style: TextStyle(color: Color(0xff6B7280),fontSize: 12),),

                ],
              ),
            );
          },)
          ],
        ),
      ),
    );
  }
}
