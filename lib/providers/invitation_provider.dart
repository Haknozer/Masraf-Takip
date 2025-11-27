import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/invitation_model.dart';
import '../services/firebase_service.dart';
import 'auth_provider.dart';

final myInvitationsProvider = StreamProvider<List<InvitationModel>>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return Stream.value([]);

  return FirebaseService.firestore
      .collection('invitations')
      .where('toUserId', isEqualTo: currentUser.uid)
      .where('status', isEqualTo: 'pending')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          return InvitationModel.fromJson({...data, 'id': doc.id});
        }).toList();
      });
});

