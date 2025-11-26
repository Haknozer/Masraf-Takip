import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/settlement_model.dart';
import '../models/user_model.dart';
import '../utils/debt_calculator.dart';
import '../services/firebase_service.dart';
import '../providers/group_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/auth_provider.dart';

/// Settlement Controller - MVC prensiplerine uygun hesaplaşma işlemleri controller'ı
class SettlementController {
  /// Borç ödeme kaydı oluştur (masrafları güncelle)
  static Future<void> recordPayment(
    WidgetRef ref,
    String groupId,
    String fromUserId, // Borçlu
    double amount, // Ödenen miktar
    String? note,
  ) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) throw Exception('Kullanıcı oturumu bulunamadı');

    // Grubu al
    final groupState = ref.read(groupProvider(groupId));
    final group = groupState.valueOrNull;
    if (group == null) throw Exception('Grup bulunamadı');

    // Masrafları al
    final expensesState = ref.read(groupExpensesProvider(groupId));
    final expenses = expensesState.valueOrNull ?? [];

    // Kullanıcı map'ini oluştur
    final allUserIds = <String>{fromUserId, currentUser.uid};
    allUserIds.addAll(group.memberIds);
    for (final expense in expenses) {
      allUserIds.add(expense.paidBy);
      allUserIds.addAll(expense.sharedBy);
      if (expense.paidAmounts != null) {
        allUserIds.addAll(expense.paidAmounts!.keys);
      }
    }

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

    // Borçları hesapla
    final debtSummary = DebtCalculator.calculateGroupDebts(
      userId: currentUser.uid,
      group: group,
      expenses: expenses,
      usersMap: usersMap,
    );

    // fromUserId'nin currentUser'a olan borcunu bul
    final debt = debtSummary.debts.firstWhere(
      (d) => d.fromUserId == fromUserId && d.toUserId == currentUser.uid,
      orElse: () => throw Exception('Borç bulunamadı'),
    );

    if (amount > debt.amount) {
      throw Exception('Ödeme miktarı borçtan fazla olamaz');
    }

    // Settlement payment kaydı oluştur
    final paymentId = FirebaseService.firestore.collection('settlements').doc().id;
    final payment = SettlementPayment(
      id: paymentId,
      groupId: groupId,
      fromUserId: fromUserId,
      toUserId: currentUser.uid,
      amount: amount,
      paidAt: DateTime.now(),
      note: note,
    );

    await FirebaseService.addDocument(
      collection: 'settlements',
      data: payment.toJson(),
    );

    // Masrafları güncelle (ödenen miktarı düş)
    // Bu karmaşık bir işlem, şimdilik sadece payment kaydı oluşturuyoruz
    // Borç hesaplama sırasında settlement'ları da dikkate almak gerekecek
  }

  /// "Kimseden alacağım yok" işaretle
  static Future<void> markAsSettled(
    WidgetRef ref,
    String groupId,
  ) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) throw Exception('Kullanıcı oturumu bulunamadı');

    // Grubu al
    final groupState = ref.read(groupProvider(groupId));
    final group = groupState.valueOrNull;
    if (group == null) throw Exception('Grup bulunamadı');

    // settledUserIds'e ekle
    final updatedSettledUserIds = Set<String>.from(group.settledUserIds)..add(currentUser.uid);

    // Grubu güncelle
    await FirebaseService.updateDocument(
      path: 'groups/$groupId',
      data: {
        'settledUserIds': updatedSettledUserIds.toList(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Grubu kapat
  static Future<void> closeGroup(
    WidgetRef ref,
    String groupId,
  ) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) throw Exception('Kullanıcı oturumu bulunamadı');

    // Grubu al
    final groupState = ref.read(groupProvider(groupId));
    final group = groupState.valueOrNull;
    if (group == null) throw Exception('Grup bulunamadı');

    // Grubu kapat
    await FirebaseService.updateDocument(
      path: 'groups/$groupId',
      data: {
        'isActive': false,
        'updatedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  /// "Kimseden alacağım yok" işaretini kaldır
  static Future<void> unmarkAsSettled(
    WidgetRef ref,
    String groupId,
  ) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) throw Exception('Kullanıcı oturumu bulunamadı');

    // Grubu al
    final groupState = ref.read(groupProvider(groupId));
    final group = groupState.valueOrNull;
    if (group == null) throw Exception('Grup bulunamadı');

    // settledUserIds'den çıkar
    final updatedSettledUserIds = Set<String>.from(group.settledUserIds)..remove(currentUser.uid);

    // Grubu güncelle ve aktif yap
    await FirebaseService.updateDocument(
      path: 'groups/$groupId',
      data: {
        'settledUserIds': updatedSettledUserIds.toList(),
        'isActive': true, // Grup tekrar aktif olur
        'updatedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Grup settlement özetini al
  static Future<GroupSettlementStatus> getSettlementStatus(
    WidgetRef ref,
    String groupId,
  ) async {
    // Grubu al
    final groupState = ref.read(groupProvider(groupId));
    final group = groupState.valueOrNull;
    if (group == null) throw Exception('Grup bulunamadı');

    // Settlement payment'ları al
    final paymentsSnapshot = await FirebaseService.firestore
        .collection('settlements')
        .where('groupId', isEqualTo: groupId)
        .get();

    final payments = paymentsSnapshot.docs
        .map((doc) => SettlementPayment.fromJson({
              'id': doc.id,
              ...doc.data(),
            }))
        .toList();

    return GroupSettlementStatus(
      groupId: groupId,
      settledUserIds: group.settledUserIds,
      payments: payments,
      isClosed: !group.isActive,
    );
  }
}

