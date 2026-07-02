import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    List<Map<String,dynamic>>status=[
      {"title":'Approved',
        'name':"John Doe",
        "program":"Water Color",
        'textColor':Color(0xff22C55E),
        'backColor':Color(0xffDCFCE7)},
      {"title":'Pending',
        'name':"John Doe",
        "program":"Water Color",
        'textColor':Color(0xffF97316),
        'backColor':Color(0xffFFEDD5)},
      {"title":'Approved',
        'name':"John Doe",
        "program":"Water Color",
        'textColor':Color(0xff22C55E),
        'backColor':Color(0xffDCFCE7)},
      {"title":'Approved',
        'name':"John Doe",
        "program":"Water Color",
        'textColor':Color(0xff22C55E),
        'backColor':Color(0xffDCFCE7)},
    ];
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
    return SizedBox(
      child: Column(
        children: [
          GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: tile.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 1.5,
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
          },),
          SizedBox(height: 15,),
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Recent Registrations",style: TextStyle(color: Color(0xff1F2937),fontWeight: FontWeight.bold,fontSize: 12),),
                SizedBox(height: 15,),
                ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount:status.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(status[index]['name'],style: TextStyle(color: Color(0xff1F2937),fontWeight: FontWeight.w400,fontSize: 12),),
                              Text(status[index]['program'],style: TextStyle(color: Color(0xff6B7280),fontSize: 12),),
                            ],
                          ),
                          Container(
                            padding: EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: status[index]['backColor'],
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child:Text(status[index]['title'],style: TextStyle(color:status[index]['textColor'],fontWeight: FontWeight.w400,fontSize: 12),),
                          )
                        ],
                      ),
                    );
                  },)

              ],
            ),
          ),
        ],
      ),
    );
  }
}
