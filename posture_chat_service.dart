import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PostureChatService {
  // ⚠️ เปลี่ยนเป็น API Key ของคุณ (แนะนำให้ดึงจาก .env หรือ Firebase Remote Config)
  static const String _apiKey = 'ใส่_GEMINI_API_KEY_ที่นี่';
  
  late final GenerativeModel _model;
  late ChatSession _chat;

  PostureChatService() {
    _initChat();
  }

  void _initChat() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash', // ใช้รุ่น Flash เพื่อความรวดเร็ว
      apiKey: _apiKey,
      systemInstruction: Content.system('''
คุณคือผู้ช่วย AI ที่เป็นมิตรและคอยให้กำลังใจ ชื่อ "Posture Pal" มีหน้าที่ช่วยผู้ใช้ปรับปรุงท่านั่ง 
        
ข้อมูลสำคัญ: แอปพลิเคชันนี้มีการเก็บข้อมูลพฤติกรรมการนั่งของผู้ใช้จาก Firebase โดยมีข้อมูลดังนี้:
1. สถานะการนั่ง: "นั่งถูก" หรือ "นั่งผิด"
2. ค่า Pitch (การก้ม/เงยของหลัง/คอ)
3. ค่า Roll (การเอียงซ้าย/ขวาของลำตัว)
(ระบบจะคำนวณมาให้แล้วว่าค่าเหล่านี้ดีหรือไม่)

หน้าที่ของคุณ:
- คุณจะได้รับข้อมูลประวัติการนั่ง (Pitch, Roll, สถานะ) จากระบบ หรือผู้ใช้อาจจะบอกคุณ
- ให้นำข้อมูลเหล่านี้มาวิเคราะห์และอธิบายให้ผู้ใช้ฟังแบบเข้าใจง่าย (ไม่ต้องใช้ศัพท์เทคนิคจ๋าเกินไป)
- หากค่านั่งผิด (เช่น Pitch ก้มเกินไป หรือ Roll เอียงไปข้างใดข้างหนึ่ง) ให้คำแนะนำที่นำไปปฏิบัติได้จริงในการปรับแก้
- ให้กำลังใจเพื่อให้พวกเขามีแรงจูงใจในการดูแลสุขภาพ
- ตอบกลับอย่างกระชับ เข้าใจง่าย และให้การสนับสนุนเสมอ 
- ใช้ภาษาไทยที่เป็นธรรมชาติ เป็นกันเอง และมีความเห็นอกเห็นใจ
      '''),
    );

    // เริ่มต้นประวัติการแชท
    _chat = _model.startChat(history: [
      Content.model([
        TextPart('สวัสดีค่ะ! ฉันคือ **Posture Pal** ผู้ช่วยดูแลท่านั่งของคุณ วันนี้คุณนั่งทำงานมานานแค่ไหนแล้วคะ? มีอาการปวดเมื่อยตรงไหนบ้างไหม เล่าให้ฉันฟังได้เลยค่ะ 😊')
      ])
    ]);
  }

  // ดึงข้อมูลล่าสุดจาก Firebase
  Future<Map<String, dynamic>?> _getLatestPostureData() async {
    try {
      // ⚠️ แก้ไขชื่อ Collection และ Field ให้ตรงกับ Database ของแอป
      final snapshot = await FirebaseFirestore.instance
          .collection('user_posture_logs')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data();
      }
    } catch (e) {
      print('Error fetching Firebase data: $e');
    }
    return null;
  }

  // ส่งข้อความหา AI พร้อมแนบข้อมูล Firebase
  Future<String> sendMessage(String userMessage) async {
    try {
      final postureData = await _getLatestPostureData();
      String contextData = "";

      // ถ้ามีข้อมูลจาก Firebase ให้สร้าง Context ซ่อนไว้ให้ AI รู้
      if (postureData != null) {
        final status = postureData['status'] ?? 'ไม่ทราบ';
        final pitch = postureData['pitch'] ?? 0.0;
        final roll = postureData['roll'] ?? 0.0;

        contextData = '''
[ข้อมูลระบบ (ไม่ต้องบอกผู้ใช้ว่าเห็นข้อความนี้): ข้อมูลการนั่งล่าสุดของผู้ใช้]
สถานะ: $status
ค่า Pitch: $pitch องศา
ค่า Roll: $roll องศา
-------------------
ผู้ใช้ถามว่า: ''';
      }

      // รวมข้อมูลระบบกับข้อความผู้ใช้
      final finalMessage = contextData + userMessage;

      // ส่งไปให้ Gemini
      final response = await _chat.sendMessage(Content.text(finalMessage));
      return response.text ?? 'ขออภัยค่ะ ฉันไม่สามารถตอบกลับได้ในขณะนี้';
      
    } catch (e) {
      print('Error sending message to Gemini: $e');
      return 'ขออภัยค่ะ เกิดข้อผิดพลาดในการเชื่อมต่อ กรุณาลองใหม่อีกครั้งนะคะ';
    }
  }
}
