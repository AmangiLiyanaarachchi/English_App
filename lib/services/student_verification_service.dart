import 'package:cloud_firestore/cloud_firestore.dart';

class StudentVerificationService {
  static final StudentVerificationService _instance =
      StudentVerificationService._internal();
  factory StudentVerificationService() => _instance;
  StudentVerificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if student ID is valid and within date range
  Future<Map<String, dynamic>> verifyStudentId(String studentId) async {
    try {
      print('🔍 Checking student ID: $studentId');

      // Query the students collection
      final studentDoc = await _firestore
          .collection('students')
          .doc(studentId.trim().toUpperCase())
          .get();

      if (!studentDoc.exists) {
        print('❌ Student ID not found in database');
        return {
          'isValid': false,
          'message': 'Invalid student ID',
        };
      }

      final data = studentDoc.data()!;
      final startDate = (data['startDate'] as Timestamp).toDate();
      final endDate = (data['endDate'] as Timestamp).toDate();
      final now = DateTime.now();

      // Check if current date is within the valid period
      if (now.isBefore(startDate)) {
        print('⏰ Student ID not yet active');
        return {
          'isValid': false,
          'message':
              'Student ID not yet active. Valid from ${_formatDate(startDate)}',
          'startDate': startDate,
          'endDate': endDate,
        };
      }

      if (now.isAfter(endDate)) {
        print('⏰ Student ID expired');
        return {
          'isValid': false,
          'message': 'Student ID expired on ${_formatDate(endDate)}',
          'startDate': startDate,
          'endDate': endDate,
        };
      }

      print('✅ Student ID is valid');
      return {
        'isValid': true,
        'message': 'Student ID verified successfully',
        'startDate': startDate,
        'endDate': endDate,
        'studentId': studentId.trim().toUpperCase(),
      };
    } catch (e) {
      print('❌ Error verifying student ID: $e');
      return {
        'isValid': false,
        'message': 'Error verifying student ID: ${e.toString()}',
      };
    }
  }

  /// Activate Community Plan for verified student
  Future<void> activateCommunityPlanForStudent(
    String userId,
    String studentId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      print('💾 Activating Community Plan for user: $userId');
      print('📝 Student ID: $studentId');
      print('📅 Valid from: $startDate to $endDate');

      await _firestore.collection('users').doc(userId).set({
        'package': 'Community Plan',
        'studentId': studentId,
        'studentIdVerified': true,
        'studentPlanStartDate': Timestamp.fromDate(startDate),
        'studentPlanEndDate': Timestamp.fromDate(endDate),
        'studentVerifiedAt': FieldValue.serverTimestamp(),
        'voiceTotalMinutes': 200, // Default 200 minutes for students
        'voiceUsedMinutes': 0,
        'voiceEnabled': true,
      }, SetOptions(merge: true));

      print(
          '✅ Community Plan activated for student: $userId with 200 voice minutes');
    } catch (e) {
      print('❌ Error activating Community Plan: $e');
      rethrow;
    }
  }

  /// Check if student plan is still valid
  Future<bool> isStudentPlanActive(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) return false;

      final data = userDoc.data();
      if (data == null || data['studentIdVerified'] != true) return false;

      final endDate = (data['studentPlanEndDate'] as Timestamp?)?.toDate();
      if (endDate == null) return false;

      return DateTime.now().isBefore(endDate);
    } catch (e) {
      print('❌ Error checking student plan status: $e');
      return false;
    }
  }

  /// Remove student plan (for admin or when expired)
  Future<void> deactivateStudentPlan(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'package': FieldValue.delete(),
        'studentIdVerified': false,
        'studentPlanDeactivatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Student plan deactivated for user: $userId');
    } catch (e) {
      print('❌ Error deactivating student plan: $e');
      rethrow;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
