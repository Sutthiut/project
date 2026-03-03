import 'package:flutter/material.dart';
import '../widgets/floating_chat_widget.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Posture App')),
      body: Center(child: Text('หน้าหลักของแอป')),
      
      // ปุ่มแชทมุมขวาล่าง
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green[600],
        child: Icon(Icons.chat, color: Colors.white),
        onPressed: () {
          // แสดงหน้าต่างแชทแบบ Bottom Sheet เด้งขึ้นมาจากด้านล่าง
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom, // ขยับหลบคีย์บอร์ด
              ),
              child: FloatingChatWidget(),
            ),
          );
        },
      ),
    );
  }
}
