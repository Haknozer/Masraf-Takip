import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../constants/expense_categories.dart';
import '../controllers/group_members_controller.dart';
import '../models/expense_model.dart';
import '../models/group_model.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import '../utils/expense_utils.dart';
import '../widgets/common/error_snackbar.dart';

/// Grup özeti PDF raporu oluşturan servis
class PdfReportService {
  static const _fontAssetPath = 'assets/fonts/Roboto.ttf';
  static pw.Font? _regularFont;
  static pw.Font? _boldFont;

  /// Grup detayı için PDF raporu üretir ve paylaşım ekranını açar
  static Future<void> generateGroupSummary({
    required BuildContext context,
    required GroupModel group,
    int recentExpenseLimit = 5,
  }) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    bool loadingDialogVisible = false;

    try {
      // Basit yükleniyor diyaloğu
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      loadingDialogVisible = true;

      // Grup üyelerini getir
      final members = await GroupMembersController.getGroupMembers(group);
      final membersMap = {for (final member in members) member.id: member};

      // Grup masraflarını getir
      final expensesSnapshot =
          await FirebaseService.firestore
              .collection('expenses')
              .where('groupId', isEqualTo: group.id)
              .orderBy('date', descending: true)
              .get();

      final expenses = expensesSnapshot.docs.map(ExpenseUtils.fromDocumentSnapshot).whereType<ExpenseModel>().toList();

      final totalExpense = expenses.fold<double>(0, (sum, expense) => sum + expense.amount);
      final memberCount = group.memberIds.length;
      final averagePerMember = memberCount == 0 ? 0.0 : totalExpense / memberCount;
      final recentExpenses = expenses.take(recentExpenseLimit).toList();

      final memberSummaries = _buildMemberSummaries(group: group, expenses: expenses, membersMap: membersMap);

      final baseFont = await _getRegularFont();
      final boldFont = await _getBoldFont();

      final pdf = await _buildDocument(
        group: group,
        totalExpense: totalExpense,
        averagePerMember: averagePerMember,
        memberSummaries: memberSummaries,
        recentExpenses: recentExpenses,
        membersMap: membersMap,
        baseFont: baseFont,
        boldFont: boldFont,
      );

      if (loadingDialogVisible && navigator.canPop()) {
        navigator.pop();
        loadingDialogVisible = false;
      }

      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
      if (context.mounted) {
        ErrorSnackBar.showSuccess(context, 'PDF raporu hazır!');
      }
    } catch (e) {
      if (loadingDialogVisible && navigator.canPop()) {
        navigator.pop();
      }
      if (context.mounted) {
        ErrorSnackBar.show(context, 'PDF oluşturma hatası: $e');
      }
    }
  }

  static Future<pw.Document> _buildDocument({
    required GroupModel group,
    required double totalExpense,
    required double averagePerMember,
    required List<_MemberFinancialSummary> memberSummaries,
    required List<ExpenseModel> recentExpenses,
    required Map<String, UserModel> membersMap,
    required pw.Font baseFont,
    required pw.Font boldFont,
  }) async {
    final pdf = pw.Document();

    final currencyFormatter = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);
    final dateFormatter = DateFormat('dd.MM.yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(32),
          theme: pw.ThemeData.withFont(base: baseFont, bold: boldFont),
        ),
        build:
            (context) => [
              pw.Header(
                level: 0,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Grup Özeti Raporu', style: pw.TextStyle(font: boldFont, fontSize: 20)),
                    pw.SizedBox(height: 4),
                    pw.Text('Grup: ${group.name}', style: pw.TextStyle(font: baseFont, fontSize: 12)),
                    pw.Text(
                      'Rapor Tarihi: ${dateFormatter.format(DateTime.now())}',
                      style: pw.TextStyle(font: baseFont, fontSize: 12),
                    ),
                  ],
                ),
              ),
              _buildGroupInfoSection(group, currencyFormatter, baseFont, boldFont),
              pw.SizedBox(height: 16),
              _buildMembersSection(memberSummaries, baseFont, boldFont),
              pw.SizedBox(height: 16),
              _buildFinancialSummarySection(
                totalExpense: totalExpense,
                averagePerMember: averagePerMember,
                currencyFormatter: currencyFormatter,
                memberSummaries: memberSummaries,
                baseFont: baseFont,
                boldFont: boldFont,
              ),
              pw.SizedBox(height: 16),
              _buildRecentExpensesSection(
                recentExpenses: recentExpenses,
                membersMap: membersMap,
                currencyFormatter: currencyFormatter,
                dateFormatter: dateFormatter,
                baseFont: baseFont,
                boldFont: boldFont,
              ),
            ],
      ),
    );

    return pdf;
  }

  static pw.Widget _buildGroupInfoSection(
    GroupModel group,
    NumberFormat currencyFormatter,
    pw.Font baseFont,
    pw.Font boldFont,
  ) {
    final infoRows = [
      ['Grup Adı', group.name],
      ['Açıklama', group.description.isNotEmpty ? group.description : '-'],
      ['Davet Kodu', group.inviteCode],
      ['Üye Sayısı', group.memberIds.length.toString()],
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Grup Bilgileri', style: pw.TextStyle(font: boldFont, fontSize: 14)),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headers: ['Alan', 'Bilgi'],
          headerStyle: pw.TextStyle(font: boldFont, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey900),
          cellStyle: pw.TextStyle(font: baseFont, fontSize: 11),
          cellAlignment: pw.Alignment.centerLeft,
          data: infoRows,
        ),
      ],
    );
  }

  static pw.Widget _buildMembersSection(
    List<_MemberFinancialSummary> memberSummaries,
    pw.Font baseFont,
    pw.Font boldFont,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Üyeler ve Roller', style: pw.TextStyle(font: boldFont, fontSize: 14)),
        pw.SizedBox(height: 8),
        if (memberSummaries.isEmpty)
          pw.Text('Üye bulunamadı', style: pw.TextStyle(font: baseFont))
        else
          pw.TableHelper.fromTextArray(
            headers: ['Üye', 'Rol', 'E-posta'],
            headerStyle: pw.TextStyle(font: boldFont, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey900),
            cellStyle: pw.TextStyle(font: baseFont, fontSize: 10),
            data: memberSummaries.map((summary) => [summary.name, summary.roleLabel, summary.email ?? '-']).toList(),
          ),
      ],
    );
  }

  static pw.Widget _buildFinancialSummarySection({
    required double totalExpense,
    required double averagePerMember,
    required NumberFormat currencyFormatter,
    required List<_MemberFinancialSummary> memberSummaries,
    required pw.Font baseFont,
    required pw.Font boldFont,
  }) {
    final totalsRows = [
      ['Toplam Harcama', currencyFormatter.format(totalExpense)],
      ['Kişi Başına Ortalama', currencyFormatter.format(averagePerMember)],
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Borç / Alacak Özeti', style: pw.TextStyle(font: boldFont, fontSize: 14)),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headers: ['Metrik', 'Değer'],
          headerStyle: pw.TextStyle(font: boldFont, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey900),
          cellStyle: pw.TextStyle(font: baseFont, fontSize: 10),
          data: totalsRows,
        ),
        pw.SizedBox(height: 12),
        if (memberSummaries.isEmpty)
          pw.Text('Borç/Alacak bilgisi bulunamadı', style: pw.TextStyle(font: baseFont))
        else
          pw.TableHelper.fromTextArray(
            headers: ['Üye', 'Ödenen', 'Payı', 'Net'],
            headerStyle: pw.TextStyle(font: boldFont, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey900),
            cellStyle: pw.TextStyle(font: baseFont, fontSize: 10),
            data:
                memberSummaries
                    .map(
                      (summary) => [
                        summary.name,
                        currencyFormatter.format(summary.paidTotal),
                        currencyFormatter.format(summary.shareTotal),
                        '${currencyFormatter.format(summary.netAmount)} ${summary.netAmount >= 0 ? '(Alacak)' : '(Borç)'}',
                      ],
                    )
                    .toList(),
          ),
      ],
    );
  }

  static pw.Widget _buildRecentExpensesSection({
    required List<ExpenseModel> recentExpenses,
    required Map<String, UserModel> membersMap,
    required NumberFormat currencyFormatter,
    required DateFormat dateFormatter,
    required pw.Font baseFont,
    required pw.Font boldFont,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Son Masraflar', style: pw.TextStyle(font: boldFont, fontSize: 14)),
        pw.SizedBox(height: 8),
        if (recentExpenses.isEmpty)
          pw.Text('Masraf bulunamadı', style: pw.TextStyle(font: baseFont))
        else
          pw.TableHelper.fromTextArray(
            headers: ['Tarih', 'Kategori', 'Açıklama', 'Ödeyen', 'Tutar'],
            headerStyle: pw.TextStyle(font: boldFont, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey900),
            cellStyle: pw.TextStyle(font: baseFont, fontSize: 9),
            columnWidths: {
              0: const pw.FixedColumnWidth(60),
              1: const pw.FixedColumnWidth(70),
              2: const pw.FlexColumnWidth(),
              3: const pw.FixedColumnWidth(80),
              4: const pw.FixedColumnWidth(60),
            },
            data:
                recentExpenses
                    .map(
                      (expense) => [
                        dateFormatter.format(expense.date),
                        ExpenseCategories.getById(expense.category)?.name ?? expense.category,
                        expense.description,
                        membersMap[expense.paidBy]?.displayName ?? expense.paidBy,
                        currencyFormatter.format(expense.amount),
                      ],
                    )
                    .toList(),
          ),
      ],
    );
  }

  static List<_MemberFinancialSummary> _buildMemberSummaries({
    required GroupModel group,
    required List<ExpenseModel> expenses,
    required Map<String, UserModel> membersMap,
  }) {
    return group.memberIds.map((memberId) {
      final user = membersMap[memberId];
      double paidTotal = 0;
      double shareTotal = 0;

      for (final expense in expenses) {
        if (expense.paidBy == memberId) {
          paidTotal += expense.amount;
        }
        if (expense.sharedBy.contains(memberId)) {
          shareTotal += expense.getAmountForUser(memberId);
        }
      }

      return _MemberFinancialSummary(
        userId: memberId,
        name: user?.displayName.isNotEmpty == true ? user!.displayName : 'Bilinmeyen Üye',
        email: user?.email,
        roleLabel: group.getUserRole(memberId) == 'admin' ? 'Admin' : 'Üye',
        paidTotal: paidTotal,
        shareTotal: shareTotal,
      );
    }).toList();
  }

  static Future<void> _ensureFontsLoaded() async {
    if (_regularFont != null && _boldFont != null) {
      return;
    }

    final fontData = await rootBundle.load(_fontAssetPath);
    _regularFont ??= pw.Font.ttf(fontData.buffer.asByteData());
    _boldFont ??= pw.Font.ttf(fontData.buffer.asByteData());
  }

  static Future<pw.Font> _getRegularFont() async {
    await _ensureFontsLoaded();
    return _regularFont!;
  }

  static Future<pw.Font> _getBoldFont() async {
    await _ensureFontsLoaded();
    return _boldFont!;
  }
}

class _MemberFinancialSummary {
  _MemberFinancialSummary({
    required this.userId,
    required this.name,
    required this.roleLabel,
    required this.paidTotal,
    required this.shareTotal,
    this.email,
  });

  final String userId;
  final String name;
  final String roleLabel;
  final double paidTotal;
  final double shareTotal;
  final String? email;

  double get netAmount => paidTotal - shareTotal;
}
