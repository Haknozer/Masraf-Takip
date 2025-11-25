import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/debt_model.dart';
import '../utils/debt_calculator.dart';
import '../services/firebase_service.dart';
import '../providers/group_provider.dart';
import '../providers/expense_provider.dart';

/// Remove Member Controller - MVC prensiplerine uygun üye çıkarma işlemleri controller'ı
class RemoveMemberController {
  /// Üyenin gruptaki borçlarını kontrol et
  static Future<List<DebtBetweenUsers>> checkMemberDebts(
    WidgetRef ref,
    String groupId,
    String memberId,
  ) async {
    // Grubu al
    final groupState = ref.read(groupProvider(groupId));
    final group = groupState.valueOrNull;
    if (group == null) {
      throw Exception('Grup bulunamadı');
    }

    // Masrafları al
    final expensesState = ref.read(groupExpensesProvider(groupId));
    final expenses = expensesState.valueOrNull ?? [];

    // Tüm kullanıcı ID'lerini topla
    final allUserIds = <String>{memberId};
    allUserIds.addAll(group.memberIds);
    for (final expense in expenses) {
      allUserIds.add(expense.paidBy);
      allUserIds.addAll(expense.sharedBy);
    }

    // Kullanıcı map'ini oluştur
    final usersMap = <String, UserModel>{};
    for (final userId in allUserIds) {
      try {
        final userDoc = await FirebaseService.getDocumentSnapshot('users/$userId');
        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          usersMap[userId] = UserModel.fromJson(data);
        }
      } catch (e) {
        continue;
      }
    }

    // Üyenin borçlarını hesapla
    final debtSummary = DebtCalculator.calculateGroupDebts(
      userId: memberId,
      group: group,
      expenses: expenses,
      usersMap: usersMap,
    );

    // Üyenin borçlu olduğu borçları filtrele (sadece başka üyelere olan borçlar)
    return debtSummary.debts.where((debt) => debt.fromUserId == memberId).toList();
  }

  /// Üyeyi gruptan çıkar ve masrafları güncelle
  static Future<void> removeMemberFromGroup(
    WidgetRef ref,
    String groupId,
    String memberId,
  ) async {
    // Grubu al
    final groupState = ref.read(groupProvider(groupId));
    final group = groupState.valueOrNull;
    if (group == null) {
      throw Exception('Grup bulunamadı');
    }

    // Masrafları al
    final expensesState = ref.read(groupExpensesProvider(groupId));
    final expenses = expensesState.valueOrNull ?? [];

    // 1. Masrafları güncelle (o üyeyi sharedBy ve paidBy'dan çıkar)
    for (final expense in expenses) {
      final updatedSharedBy = expense.sharedBy.where((id) => id != memberId).toList();
      final updatedPaidBy = expense.paidBy == memberId ? group.memberIds.firstWhere(
        (id) => id != memberId,
        orElse: () => group.createdBy,
      ) : expense.paidBy;

      // Manuel dağılım varsa, o üyenin tutarını kaldır
      Map<String, double>? updatedManualAmounts;
      if (expense.manualAmounts != null) {
        updatedManualAmounts = Map<String, double>.from(expense.manualAmounts!);
        updatedManualAmounts.remove(memberId);
        if (updatedManualAmounts.isEmpty) {
          updatedManualAmounts = null;
        }
      }

      // Eğer sharedBy boşaldıysa, masrafı sil
      if (updatedSharedBy.isEmpty) {
        await FirebaseService.deleteDocument('expenses/${expense.id}');
      } else {
        // Masrafı güncelle
        final updateData = <String, dynamic>{
          'sharedBy': updatedSharedBy,
          'paidBy': updatedPaidBy,
          'updatedAt': DateTime.now().toIso8601String(),
        };

        if (updatedManualAmounts != null) {
          updateData['manualAmounts'] = updatedManualAmounts;
        } else {
          updateData['manualAmounts'] = null;
        }

        await FirebaseService.updateDocument(
          path: 'expenses/${expense.id}',
          data: updateData,
        );
      }
    }

    // 2. Eğer ayrılan kişi admin ise, başka birine admin yetkisi devret
    final isLeavingAdmin = group.isGroupAdmin(memberId);
    if (isLeavingAdmin) {
      // Kalan üyeleri al (ayrılan kişi hariç)
      final remainingMembers = group.memberIds.where((id) => id != memberId).toList();
      
      // Başka admin var mı kontrol et
      final hasOtherAdmin = remainingMembers.any((id) => group.isGroupAdmin(id));
      
      // Eğer başka admin yoksa, ilk üyeye admin yetkisi ver
      if (!hasOtherAdmin && remainingMembers.isNotEmpty) {
        final newAdminId = remainingMembers.first;
        await ref.read(groupNotifierProvider.notifier).updateUserRole(groupId, newAdminId, 'admin');
      }
    }

    // 3. Grubu güncelle (üyeyi memberIds'den çıkar)
    await ref.read(groupNotifierProvider.notifier).removeMember(groupId, memberId);

    // 4. Kullanıcının users dokümanından grubu kaldır
    try {
      final userDocSnapshot = await FirebaseService.firestore
          .collection('users')
          .where('id', isEqualTo: memberId)
          .limit(1)
          .get();

      if (userDocSnapshot.docs.isNotEmpty) {
        final userDocId = userDocSnapshot.docs.first.id;
        await FirebaseService.updateDocument(
          path: 'users/$userDocId',
          data: {
            'groups': FieldValue.arrayRemove([groupId]),
            'updatedAt': DateTime.now().toIso8601String(),
          },
        );
      }
    } catch (e) {
      // Kullanıcı dokümanı güncellenemezse devam et
      print('Kullanıcı dokümanı güncellenemedi: $memberId - $e');
    }
  }
}

