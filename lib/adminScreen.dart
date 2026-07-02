import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meeras_fest_app/adminProvider.dart';
import 'package:meeras_fest_app/analytic_page.dart';
import 'package:meeras_fest_app/overview_page.dart';
import 'package:provider/provider.dart';
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 30,),
              Text("Admin Panel",style: TextStyle(color: Color(0xff1F2937),fontSize: 18,fontWeight: FontWeight.bold),),
              Text("Manage festival operations",style: TextStyle(color: Color(0xff6B7280),fontSize: 12),),
              SizedBox(height: 15,),
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
            SizedBox(height: 15,),
              Consumer<AdminProvider>(
                builder: (context, adminPro, child) {
                if(adminPro.isAnalyticTab){
                  return AnalyticPage();
                }
                return OverviewPage();
              },)
            ],
          ),
        ),
      ),
    );
  }
}
