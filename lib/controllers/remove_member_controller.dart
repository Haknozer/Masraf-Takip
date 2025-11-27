import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/debt_model.dart';
import '../models/settlement_model.dart';
import '../utils/debt_calculator.dart';
import '../services/firebase_service.dart';
import '../providers/group_provider.dart';
import '../providers/expense_provider.dart';

/// Remove Member Controller - MVC prensiplerine uygun üye çıkarma işlemleri controller'ı
class RemoveMemberController {
  /// Üyenin gruptaki borçlarını kontrol et
  static Future<List<DebtBetweenUsers>> checkMemberDebts(WidgetRef ref, String groupId, String memberId) async {
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
      if (expense.paidAmounts != null) {
        allUserIds.addAll(expense.paidAmounts!.keys);
      }
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

    // Settlement payment'ları al
    final settlements = <SettlementPayment>[];
    try {
      final settlementsSnapshot =
          await FirebaseService.firestore.collection('settlements').where('groupId', isEqualTo: groupId).get();

      settlements.addAll(
        settlementsSnapshot.docs.map(
          (doc) => SettlementPayment.fromJson({'id': doc.id, ...doc.data()}),
        ),
      );
    } catch (e) {
      // Hata durumunda settlement'lar olmadan devam et
    }

    // Üyenin borçlarını hesapla
    final debtSummary = DebtCalculator.calculateGroupDebts(
      userId: memberId,
      group: group,
      expenses: expenses,
      usersMap: usersMap,
      settlements: settlements,
    );

    // Üyenin borçlu olduğu borçları filtrele (sadece başka üyelere olan borçlar)
    return debtSummary.debts.where((debt) => debt.fromUserId == memberId).toList();
  }

  /// Üyeyi gruptan çıkar ve masrafları güncelle
  /// [blockAfterRemove] true ise, çıkarılan kullanıcı grup tarafından engellenir.
  static Future<void> removeMemberFromGroup(WidgetRef ref, String groupId, String memberId,
      {bool blockAfterRemove = false}) async {
    // Grubu al
    final groupState = ref.read(groupProvider(groupId));
    final group = groupState.valueOrNull;
    if (group == null) {
      throw Exception('Grup bulunamadı');
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

    // 3.1 Eğer admin tarafından çıkarılıyorsa ve blockAfterRemove true ise, engellenenler listesine ekle
    if (blockAfterRemove) {
      await FirebaseService.updateDocument(
        path: 'groups/$groupId',
        data: {
          'blockedUserIds': FieldValue.arrayUnion([memberId]),
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
    }

    // 4. Kullanıcının users dokümanından grubu kaldır
    try {
      final userDocSnapshot =
          await FirebaseService.firestore.collection('users').where('id', isEqualTo: memberId).limit(1).get();

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
      debugPrint('Kullanıcı dokümanı güncellenemedi: $memberId - $e');
    }
  }
}
