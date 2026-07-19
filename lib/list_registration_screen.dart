import 'package:flutter/material.dart';
import 'package:meeras_fest_app/register_provider.dart';
import 'package:meeras_fest_app/resultProvider.dart';
import 'package:provider/provider.dart';
class ListRegistrationScreen extends StatelessWidget {
  const ListRegistrationScreen({super.key});

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
            child: Text("Registrations",style: TextStyle(color: Color(0xff1F2937),fontWeight: FontWeight.bold,fontSize: 18),),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Text("View and manage your team's entries",style: TextStyle(color: Color(0xff6B7280),fontWeight: FontWeight.w400,fontSize: 12),),
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
      Consumer<StudentEntryProvider>(
        builder: (context, provider, child) {
          final List<Map<String, dynamic>> registrations = [
            {
              "name": "John Doe",
              "program": "Water Color",
              "category": "Art",
              "team": "Spartans",
              "status": "Approved",
              "registrationId": "REG1",
            },
            {
              "name": "Jane Smith",
              "program": "Classical Dance",
              "category": "Dance",
              "team": "Phoenix",
              "status": "Pending",
              "registrationId": "REG2",
            },
            {
              "name": "Mike Ross",
              "program": "One Act Play",
              "category": "Drama",
              "team": "Spartans",
              "status": "Approved",
              "registrationId": "REG3",
            },
            {
              "name": "Rachel Zane",
              "program": "Poetry Recitation",
              "category": "Literary",
              "team": "Titans",
              "status": "Rejected",
              "registrationId": "REG4",
            },
            {
              "name": "David Miller",
              "program": "Group Song",
              "category": "Music",
              "team": "Warriors",
              "status": "Approved",
              "registrationId": "REG5",
            },
            {
              "name": "Emily Clark",
              "program": "Mimicry",
              "category": "Stage",
              "team": "Legends",
              "status": "Pending",
              "registrationId": "REG6",
            },
          ];
          Color getStatusColor(String status) {
            switch (status.toLowerCase()) {
              case "approved":
                return Colors.green;
              case "pending":
                return Colors.orange;
              case "rejected":
                return Colors.red;
              default:
                return Colors.grey;
            }
          }
          Color getCategoryColor(String category) {
            switch (category.toLowerCase()) {
              case "music":
                return const Color(0xFFE3F2FD); // Light Blue

              case "dance":
                return const Color(0xFFFCE4EC); // Light Pink

              case "drama":
                return const Color(0xFFEDE7F6); // Light Purple

              case "literary":
                return const Color(0xFFE0F7F4); // Light Teal

              case "art":
                return const Color(0xFFFFF3E0); // Light Orange

              case "stage":
                return const Color(0xFFE8F5E9); // Light Green

              case "sports":
                return const Color(0xFFFFEBEE); // Light Red

              default:
                return const Color(0xFFF5F5F5); // Light Grey
            }
          }

          Color getCategoryTextColor(String category) {
            switch (category.toLowerCase()) {
              case "music":
                return const Color(0xFF1976D2);

              case "dance":
                return const Color(0xFFD81B60);

              case "drama":
                return const Color(0xFF8E24AA);

              case "literary":
                return const Color(0xFF00897B);

              case "art":
                return const Color(0xFFEF6C00);

              case "stage":
                return const Color(0xFF2E7D32);

              case "sports":
                return const Color(0xFFC62828);

              default:
                return Colors.black87;
            }
          }
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: registrations.length,
                itemBuilder: (context, index) {
                  final item = registrations[index];
                  final isExpanded = provider.isExpanded(index);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [

                        /// Header
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => provider.toggleExpand(index),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [

                                      Text(
                                        item["name"],
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),

                                      const SizedBox(height: 4),

                                      Text(
                                        item["program"],
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: getCategoryColor(item["category"]),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    item["category"],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                      getCategoryTextColor(item["category"]),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 8),

                                AnimatedRotation(
                                  turns: isExpanded ? .5 : 0,
                                  duration:
                                  const Duration(milliseconds: 250),
                                  child: const Icon(
                                    Icons.keyboard_arrow_down,
                                    color: Colors.grey,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        /// Expanded Content
                        AnimatedCrossFade(
                          duration: const Duration(milliseconds: 250),
                          crossFadeState: isExpanded
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          firstChild: const SizedBox.shrink(),
                          secondChild: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(12),
                              ),
                            ),
                            child: Row(
                              children: [

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: const [
                                      Text(
                                        "Team",
                                        style: TextStyle(
                                          fontSize: 12,
                                            color: Colors.grey),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        "Spartans",
                                        style: TextStyle(
                                          fontSize: 12,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(height: 10),
                                      Text(
                                        "Registration ID",
                                        style: TextStyle(
                                          fontSize: 12,
                                            color: Colors.grey),
                                      ),
                                      SizedBox(height: 4),
                                      Text("REG3",
                                      style: TextStyle(
                                        fontSize: 12
                                      ),),
                                    ],
                                  ),
                                ),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: const [
                                      Text(
                                        "Status",
                                        style: TextStyle(
                                          fontSize: 12,
                                            color: Colors.grey),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        "Approved",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
        ],
      ),
    );
  }
}
