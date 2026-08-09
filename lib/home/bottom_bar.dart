import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meeras_fest_app/admin/adminScreen.dart';
import 'package:meeras_fest_app/home/home_provider.dart';
import 'package:meeras_fest_app/home/home_screen.dart';
import 'package:meeras_fest_app/judges/judgement_screen.dart';
import 'package:meeras_fest_app/registration/list_registration_screen.dart';
import 'package:meeras_fest_app/profile/profileProvider.dart';
import 'package:meeras_fest_app/profile/profile_screen.dart';
import 'package:meeras_fest_app/registration/register_screen.dart';
import 'package:meeras_fest_app/result/result_screen.dart';
import 'package:provider/provider.dart';

class BottomBar extends StatelessWidget {
  const BottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    var mainPages=[
      HomeScreen(),
      ResultScreen(),
      ProfileScreen(),
      AdminScreen(),
      RegisterScreen(),
      ListRegistrationScreen(),
      JudgePanelPage()
    ];

    return Scaffold(
      backgroundColor: Color(0xffFFF9F5),
      bottomNavigationBar: Container(
        height: 70,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, -3),
            ),
          ],
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
          ),
        ),
        child: Consumer<ProfileProvider>(
          builder: (context,profPro,child) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                bottomItem(
                  icon: "assets/icons/homeIcon.svg",
                  name: "Home",
                  index: 0,
                ),
                bottomItem(
                  icon: "assets/icons/resultIcon.svg",
                  name: "Results",
                  index: 1,
                ),
                if(profPro.loggedRole=='User'||profPro.loggedRole=='Gust')
                bottomItem(
                  icon: "assets/icons/profileIcon.svg",
                  name: "Profile",
                  index: 2,
                ),
                if(profPro.loggedRole=='Admin')
                bottomItem(
                  icon: "assets/icons/adminDashIcon.svg",
                  name: "Admin",
                  index: 3,
                ),
                if(profPro.loggedRole=='Leader')
                bottomItem(
                  icon: "assets/icons/studentAddIcon.svg",
                  name: "Register",
                  index: 4,
                ),
                if(profPro.loggedRole=='Leader')
                bottomItem(
                  icon: "assets/icons/registerIcon.svg",
                  name: "List",
                  index: 5,
                ),
                if(profPro.loggedRole=='Judge')
                bottomItem(
                  icon: "assets/icons/registerIcon.svg",
                  name: "Judge",
                  index: 6,
                ),
              ],
            );
          }
        ),
      ),
      body: Consumer<HomeProvider>(
        builder: (context,homePro,child) {
          return mainPages[homePro.selectedBottomIndex];
        }
      ),
    );
  }
}

Widget bottomItem({
  required String icon,
  required String name,
  required int index,
}) {
  return Consumer<HomeProvider>(
    builder: (context, mainPro, child) {
      bool isSelected = index == mainPro.selectedBottomIndex;
      return InkWell(
        onTap: () {
          mainPro.changeBottomIndex(index);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 15.0,bottom:3),
              child: SvgPicture.asset(
                colorFilter: ColorFilter.mode(
                  isSelected ? Color(0xff667EEA) : Color(0xff9CA3AF),
                  BlendMode.srcIn,
                ),
                icon,
                height: 18,
                width: 18,
              ),
            ),
            Text(
              name,
              style: TextStyle(
                color: isSelected ? Color(0xff667EEA) : Color(0xff9CA3AF),
                fontSize: 10,
              ),
            ),
            isSelected
                ? Container(
                    margin: EdgeInsets.only(top: 8),
                    height: 3,
                    width: 3,
                    decoration: BoxDecoration(
                      color: Color(0xff667EEA),
                      shape: BoxShape.circle,
                    ),
                  )
                : const SizedBox.shrink(),
          ],
        ),
      );
    },
  );
}
