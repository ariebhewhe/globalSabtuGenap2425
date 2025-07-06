  import 'package:flutter/material.dart';
  import 'package:intl/intl.dart';
  import 'package:pdf/pdf.dart';
  import 'package:pdf/widgets.dart' as pw;
  import 'package:printing/printing.dart';
  import 'package:path_provider/path_provider.dart';
  import 'dart:io';

  class PdfService {
    // Generate and print PDF report
    Future<void> generateAndPrintPdf({
      required String selectedPeriod,
      required DateTime now,
      required int totalOrders,
      required int completedOrders,
      required int cancelledOrders,
      required double totalSales,
      required Map<String, Map<String, dynamic>> itemSales,
    }) async {
      final pdf = pw.Document();
      
      // Define period text and date range
      String periodText = selectedPeriod == 'day' 
          ? 'Hari Ini' 
          : (selectedPeriod == 'week' ? 'Minggu Ini' : 'Bulan Ini');
      
      String dateRangeText = _getDateRangeText(selectedPeriod, now);
      
      // Add content to PDF
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Center(
                  child: pw.Text(
                    'Laporan Analisis Penjualan',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text(
                    dateRangeText,
                    style: const pw.TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                
                // Summary Statistics
                pw.Text(
                  'Ringkasan Penjualan',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _buildPdfStatBox('Total Pesanan', '$totalOrders'),
                    _buildPdfStatBox('Pesanan Selesai', '$completedOrders'),
                    _buildPdfStatBox('Pesanan Dibatalkan', '$cancelledOrders'),
                  ],
                ),
                pw.SizedBox(height: 10),
                _buildPdfStatBox('Total Pendapatan', 'Rp ${NumberFormat("#,###").format(totalSales)}'),
                pw.SizedBox(height: 20),
                
                // Popular Items
                pw.Text(
                  'Menu Terlaris',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                _buildPdfPopularItemsTable(itemSales),
                pw.SizedBox(height: 20),
                
                // Footer
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text(
                    'Laporan Dibuat pada ${DateFormat('d MMMM yyyy, HH:mm').format(DateTime.now())}',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
      
      // Open the PDF file for preview and printing
      await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save());
    }
    
    // Get formatted date range text based on period
    String _getDateRangeText(String period, DateTime now) {
      if (period == 'day') {
        return DateFormat('d MMMM yyyy').format(now);
      } else if (period == 'week') {
        int daysToSubtract = (now.weekday - 1) % 7;
        DateTime startDate = DateTime(now.year, now.month, now.day - daysToSubtract);
        DateTime endDate = DateTime(startDate.year, startDate.month, startDate.day + 6);
        return '${DateFormat('d MMM').format(startDate)} - ${DateFormat('d MMM yyyy').format(endDate)}';
      } else { // month
        DateTime startDate = DateTime(now.year, now.month, 1);
        DateTime endDate = DateTime(now.year, now.month + 1, 0);
        return '${DateFormat('d').format(startDate)} - ${DateFormat('d MMMM yyyy').format(endDate)}';
      }
    }
    
    // Build a stat box for the PDF
    pw.Widget _buildPdfStatBox(String label, String value) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: const pw.TextStyle(
                fontSize: 12,
                color: PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
    
    // Build popular items table for the PDF
    pw.Widget _buildPdfPopularItemsTable(Map<String, Map<String, dynamic>> itemSales) {
      // Sort items by sales amount
      var sortedItems = itemSales.entries.toList()
        ..sort((a, b) => (b.value['sales'] as double).compareTo(a.value['sales'] as double));
      
      // Take top 5 items
      var topItems = sortedItems.take(5).toList();
      
      return pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300),
        children: [
          // Header row
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey200),
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(
                  'Menu',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(
                  'Terjual',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(
                  'Pendapatan',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
            ],
          ),
          // Data rows
          if (topItems.isEmpty)
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text('Tidak ada data'),
                ),
                pw.SizedBox(),
                pw.SizedBox(),
              ],
            )
          else
            ...topItems.map((item) {
              return pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(item.key),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text('${item.value['count']}'),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      'Rp ${NumberFormat("#,###").format(item.value['sales'])}',
                    ),
                  ),
                ],
              );
            }).toList(),
        ],
      );
    }
    
    // Save PDF to file (optional method that could be added)
    Future<File> savePdfToFile(pw.Document pdf, String fileName) async {
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/$fileName.pdf');
      await file.writeAsBytes(await pdf.save());
      return file;
    }
  }