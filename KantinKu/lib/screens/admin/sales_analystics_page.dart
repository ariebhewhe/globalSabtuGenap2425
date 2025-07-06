import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:typed_data';
import 'package:fl_chart/fl_chart.dart';

class SalesAnalyticsPage extends StatefulWidget {
  const SalesAnalyticsPage({super.key});

  @override
  State<SalesAnalyticsPage> createState() => _SalesAnalyticsPageState();
}

class _SalesAnalyticsPageState extends State<SalesAnalyticsPage> with SingleTickerProviderStateMixin {
  final DatabaseReference _orderDatabase = FirebaseDatabase.instance.ref().child('orders');
  
  // Selected period (Day, Week, Month)
  String _selectedPeriod = 'Kustom';
  
  // Date filter data
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 13));
  DateTime _endDate = DateTime.now();
  
  // Sales data
  List<Map<String, dynamic>> _salesData = [];
  double _totalRevenue = 0;
  int _totalOrders = 0;
  bool _isLoading = true;
  
  // TabBar controller
  late TabController _tabController;
  
  // Status filters
  final List<String> _statusFilters = ['Semua', 'completed', 'processing', 'pending', 'cancelled'];
  String _selectedStatusFilter = 'Semua';
  
  // Logo for PDF
  late Future<Uint8List> _logoFuture;

  // For chart data
  List<FlSpot> _revenueSpots = [];
  double _maxY = 0;
  double _maxX = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSalesData();
    
    // Pre-load logo for PDF
    _logoFuture = _loadLogoForPdf();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  // Load logo for PDF
  Future<Uint8List> _loadLogoForPdf() async {
    try {
      final ByteData data = await rootBundle.load('assets/images/logo.png');
      return data.buffer.asUint8List();
    } catch (e) {
      // Return empty Uint8List if logo is not available
      return Uint8List(0);
    }
  }

  // Format currency in Rupiah
  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp',
      decimalDigits: 0,
    ).format(amount);
  }

  // Load sales data from Firebase
  Future<void> _loadSalesData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Reset data
      _salesData = [];
      _totalRevenue = 0;
      _totalOrders = 0;
      _revenueSpots = [];
      
      // Get order data
      final snapshot = await _orderDatabase.get();
      
      if (snapshot.value != null) {
        Map<dynamic, dynamic> orders = Map<dynamic, dynamic>.from(snapshot.value as Map);
        
        // Process order data
        Map<String, double> dailyRevenue = {};
        
        orders.forEach((key, value) {
          // Convert to usable map
          Map<String, dynamic> order = Map<String, dynamic>.from(value as Map);
          
          // Add order ID
          order['id'] = key;
          
          // Get order date
          DateTime orderDate = DateTime.parse(order['orderDate']);
          
          // Filter by period
          bool inPeriod = _isInSelectedPeriod(orderDate);
          
          // Filter by status
          bool statusMatch = _selectedStatusFilter == 'Semua' || 
                           order['status'] == _selectedStatusFilter;
          
          if (inPeriod && statusMatch) {
            // Calculate total order
            double orderTotal = 0;
            List<dynamic> items = order['items'] as List<dynamic>;
            
            for (var item in items) {
              orderTotal += (item['price'] as num) * (item['quantity'] as num);
            }
            
            // Add data to list
            order['total'] = orderTotal;
            _salesData.add(order);
            
            // Update totals
            _totalRevenue += orderTotal;
            _totalOrders++;
            
            // Group by date for chart data
            String dateKey = DateFormat('yyyy-MM-dd').format(orderDate);
            dailyRevenue[dateKey] = (dailyRevenue[dateKey] ?? 0) + orderTotal;
          }
        });
        
        // Sort data by date (newest first)
        _salesData.sort((a, b) => 
          DateTime.parse(b['orderDate']).compareTo(DateTime.parse(a['orderDate']))
        );
        
        // Prepare chart data
        List<String> dates = dailyRevenue.keys.toList()..sort();
        _maxY = 0;
        
        for (int i = 0; i < dates.length; i++) {
          double value = dailyRevenue[dates[i]] ?? 0;
          _revenueSpots.add(FlSpot(i.toDouble(), value));
          if (value > _maxY) _maxY = value;
        }
        
        _maxX = (dates.length - 1).toDouble();
        
        // Add padding to max Y
        _maxY = _maxY * 1.2;
      }
    } catch (e) {
      debugPrint('Error loading sales data: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saat memuat data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // Check if the date is within the selected period
  bool _isInSelectedPeriod(DateTime date) {
    // If using custom date filter
    if (_selectedPeriod == 'Kustom' && _startDate != null && _endDate != null) {
      return date.isAfter(_startDate.subtract(const Duration(days: 1))) && 
             date.isBefore(_endDate.add(const Duration(days: 1)));
    }
    
    DateTime now = DateTime.now();
    
    if (_selectedPeriod == 'Hari') {
      return date.year == now.year && 
             date.month == now.month && 
             date.day == now.day;
    } else if (_selectedPeriod == 'Minggu') {
      // Beginning of week (Monday) and end of week (Sunday)
      DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      startOfWeek = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      
      DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));
      endOfWeek = DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59);
      
      return date.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) && 
             date.isBefore(endOfWeek.add(const Duration(seconds: 1)));
    } else if (_selectedPeriod == 'Bulan') {
      return date.year == now.year && date.month == now.month;
    }
    
    return true;
  }

  // Open date picker to select start and end dates
  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2022),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFDC793B),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _selectedPeriod = 'Kustom';
      });
      
      // Reload data with new dates
      _loadSalesData();
    }
  }
  
  // Group sales data by date
  Map<String, List<Map<String, dynamic>>> _groupDataByDate() {
    Map<String, List<Map<String, dynamic>>> groupedData = {};
    
    for (var order in _salesData) {
      DateTime orderDate = DateTime.parse(order['orderDate']);
      String dateKey = DateFormat('yyyy-MM-dd').format(orderDate);
      
      if (!groupedData.containsKey(dateKey)) {
        groupedData[dateKey] = [];
      }
      
      groupedData[dateKey]!.add(order);
    }
    
    return groupedData;
  }
  
  // Group sales data by product
  Map<String, Map<String, dynamic>> _groupDataByProduct() {
    Map<String, Map<String, dynamic>> productData = {};
    
    for (var order in _salesData) {
      List<dynamic> items = order['items'] as List<dynamic>;
      
      for (var item in items) {
        String productName = item['name'];
        int quantity = item['quantity'] as int;
        double price = (item['price'] as num).toDouble();
        double total = price * quantity;
        
        if (!productData.containsKey(productName)) {
          productData[productName] = {
            'name': productName,
            'quantity': 0,
            'total': 0.0,
          };
        }
        
        productData[productName]!['quantity'] = productData[productName]!['quantity'] + quantity;
        productData[productName]!['total'] = productData[productName]!['total'] + total;
      }
    }
    
    return productData;
  }

  // Generate PDF sales report
  Future<Uint8List> _generateSalesReport() async {
    final pdf = pw.Document();
    final logo = await _logoFuture;
    
    // Create document header
    final headerStyle = pw.TextStyle(
      fontSize: 18, 
      fontWeight: pw.FontWeight.bold
    );
    
    final subHeaderStyle = pw.TextStyle(
      fontSize: 14,
      fontWeight: pw.FontWeight.bold
    );
    
    final bodyStyle = pw.TextStyle(fontSize: 10);
    final tableHeaderStyle = pw.TextStyle(
      fontSize: 10, 
      fontWeight: pw.FontWeight.bold
    );
    
    // Create header for the report
    pw.Widget header() => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('LAPORAN PENJUALAN', style: headerStyle),
                pw.SizedBox(height: 5),
                pw.Text(
                  _selectedPeriod == 'Kustom' 
                      ? 'Periode: ${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}'
                      : 'Periode: $_selectedPeriod',
                  style: subHeaderStyle
                ),
                pw.SizedBox(height: 5),
                pw.Text('Tanggal Cetak: ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}'),
              ],
            ),
            if (logo.isNotEmpty)
              pw.Image(
                pw.MemoryImage(logo),
                width: 60,
                height: 60,
              ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Divider(),
        pw.SizedBox(height: 10),
      ],
    );
    
    // Sales summary
    pw.Widget summarySection() => pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Total Penjualan:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 5),
              pw.Text(_formatCurrency(_totalRevenue), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Jumlah Pesanan:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 5),
              pw.Text('$_totalOrders pesanan', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Rata-rata Pesanan:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 5),
              pw.Text(
                _totalOrders > 0 
                    ? _formatCurrency(_totalRevenue / _totalOrders)
                    : 'Rp0', 
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)
              ),
            ],
          ),
        ],
      ),
    );
    
    // Create orders table
    pw.Widget ordersTable() {
      return pw.Table(
        border: pw.TableBorder.all(color: PdfColors.black),
        columnWidths: {
          0: const pw.FlexColumnWidth(1),
          1: const pw.FlexColumnWidth(2),
          2: const pw.FlexColumnWidth(1.5),
          3: const pw.FlexColumnWidth(1.5),
          4: const pw.FlexColumnWidth(1.5),
        },
        children: [
          // Table header
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey300),
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text('No', style: tableHeaderStyle, textAlign: pw.TextAlign.center),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text('ID Pesanan', style: tableHeaderStyle),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text('Tanggal', style: tableHeaderStyle),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text('Status', style: tableHeaderStyle),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text('Total', style: tableHeaderStyle, textAlign: pw.TextAlign.right),
              ),
            ],
          ),
          
          // Rows
          ..._salesData.asMap().entries.map((entry) {
            int idx = entry.key;
            var order = entry.value;
            String orderId = order['id'].toString();
            DateTime orderDate = DateTime.parse(order['orderDate']);
            String status = order['status'];
            double total = order['total'];
            
            return pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text('${idx + 1}', style: bodyStyle, textAlign: pw.TextAlign.center),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text('#${orderId.substring(0, min(8, orderId.length))}', style: bodyStyle),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(DateFormat('dd/MM/yyyy HH:mm').format(orderDate), style: bodyStyle),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(_getStatusText(status), style: bodyStyle),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(_formatCurrency(total), style: bodyStyle, textAlign: pw.TextAlign.right),
                ),
              ],
            );
          }).toList(),
        ],
      );
    }
    
    // Create top products table
    pw.Widget topProductsTable() {
      var productData = _groupDataByProduct();
      var sortedProducts = productData.values.toList()
        ..sort((a, b) => (b['total'] as double).compareTo(a['total'] as double));
      
      return pw.Table(
        border: pw.TableBorder.all(color: PdfColors.black),
        columnWidths: {
          0: const pw.FlexColumnWidth(1),
          1: const pw.FlexColumnWidth(4),
          2: const pw.FlexColumnWidth(1.5),
          3: const pw.FlexColumnWidth(2),
        },
        children: [
          // Table header
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey300),
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text('No', style: tableHeaderStyle, textAlign: pw.TextAlign.center),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text('Nama Produk', style: tableHeaderStyle),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text('Jml Terjual', style: tableHeaderStyle, textAlign: pw.TextAlign.center),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text('Total', style: tableHeaderStyle, textAlign: pw.TextAlign.right),
              ),
            ],
          ),
          
          // Rows
          ...sortedProducts.asMap().entries.map((entry) {
            int idx = entry.key;
            var product = entry.value;
            
            return pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text('${idx + 1}', style: bodyStyle, textAlign: pw.TextAlign.center),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(product['name'], style: bodyStyle),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text('${product['quantity']}', style: bodyStyle, textAlign: pw.TextAlign.center),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(_formatCurrency(product['total']), style: bodyStyle, textAlign: pw.TextAlign.right),
                ),
              ],
            );
          }).toList(),
        ],
      );
    }
    
    // Create PDF pages
    // Page 1: General Information and Summary
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) => header(),
        build: (pw.Context context) => [
          summarySection(),
          pw.SizedBox(height: 20),
          pw.Text('Detail Pesanan', style: subHeaderStyle),
          pw.SizedBox(height: 10),
          ordersTable(),
        ],
      )
    );
    
    // Page 2: Top Products
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) => header(),
        build: (pw.Context context) => [
          pw.Text('Produk Terlaris', style: subHeaderStyle),
          pw.SizedBox(height: 10),
          topProductsTable(),
        ],
      )
    );
    
    return pdf.save();
  }
  
  // Show PDF preview
  Future<void> _previewPdf() async {
    final Uint8List pdfBytes = await _generateSalesReport();
    
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('Preview Laporan'),
              backgroundColor: const Color(0xFFDC793B),
              foregroundColor: Colors.white,
              actions: [
                IconButton(
                  icon: const Icon(Icons.print),
                  onPressed: () async {
                    await Printing.layoutPdf(
                      onLayout: (PdfPageFormat format) => pdfBytes,
                      name: 'laporan_penjualan_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.save_alt),
                  onPressed: () async {
                    await Printing.sharePdf(
                      bytes: pdfBytes,
                      filename: 'laporan_penjualan_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
                    );
                  },
                ),
              ],
            ),
            body: PdfPreview(
              build: (format) => pdfBytes,
              allowPrinting: true,
              allowSharing: true,
              canChangePageFormat: false,
              canChangeOrientation: false,
              initialPageFormat: PdfPageFormat.a4,
            ),
          ),
        ),
      );
    }
  }
  
  // Get status text from status code
  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Menunggu';
      case 'processing':
        return 'Diproses';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return 'Unknown';
    }
  }
  
  // Get status color from status code
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

           
               // Corrected build method with proper structure and indentation
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0.5,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFDC793B),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFDC793B),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Ringkasan'),
            Tab(text: 'Detail Pesanan'),
            Tab(text: 'Produk Terlaris'),
          ],
        ),
      ),
    ),
    body: _isLoading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFDC793B)))
        : Column(
            children: [
              // Filter section
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      offset: const Offset(0, 1),
                      blurRadius: 3,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Period selection
                    Row(
                      children: [
                        const Text(
                          'Periode:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildPeriodButton('Hari', Icons.today),
                                const SizedBox(width: 8),
                                _buildPeriodButton('Minggu', Icons.date_range),
                                const SizedBox(width: 8),
                                _buildPeriodButton('Bulan', Icons.calendar_month),
                                const SizedBox(width: 8),
                                _buildPeriodButton('Kustom', Icons.calendar_today),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    // Date range display
                    if (_selectedPeriod == 'Kustom')
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month, size: 16, color: Color(0xFFDC793B)),
                            const SizedBox(width: 8),
                            Text(
                              '${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const Spacer(),
                            InkWell(
                              onTap: () => _selectDateRange(context),
                              borderRadius: BorderRadius.circular(4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDC793B).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.edit, size: 14, color: Color(0xFFDC793B)),
                                    SizedBox(width: 4),
                                    Text(
                                      'Ubah',
                                      style: TextStyle(
                                        color: Color(0xFFDC793B),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 12),
                    
                    // Status filters
                    Row(
                      children: [
                        const Text(
                          'Status:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _statusFilters.map((status) {
                                Color chipColor = status == 'Semua'
                                    ? const Color(0xFFDC793B)
                                    : _getStatusColor(status);
                                    
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text(
                                      status == 'Semua' ? status : _getStatusText(status),
                                      style: TextStyle(
                                        color: _selectedStatusFilter == status
                                            ? Colors.white
                                            : chipColor,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                    ),
                                    selected: _selectedStatusFilter == status,
                                    backgroundColor: Colors.transparent,
                                    selectedColor: chipColor,
                                    side: BorderSide(
                                      color: chipColor,
                                      width: 1,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    onSelected: (selected) {
                                      if (selected) {
                                        setState(() {
                                          _selectedStatusFilter = status;
                                        });
                                        _loadSalesData();
                                      }
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Summary cards
              _buildSummaryCards(),
              
              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSummaryTab(),
                    _buildOrdersTab(),
                    _buildProductsTab(),
                  ],
                ),
              ),
            ],
          ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _previewPdf,
          backgroundColor: const Color(0xFFDC793B),
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text('Laporan PDF'),
        ),
      );
    }


  // Build period selection button
  Widget _buildPeriodButton(String period, IconData icon) {
    bool isSelected = _selectedPeriod == period;
    
    return OutlinedButton(
      onPressed: () {
        setState(() {
          _selectedPeriod = period;
        });
        
        if (period == 'Kustom') {
          _selectDateRange(context);
        } else {
          _loadSalesData();
        }
      },
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? const Color(0xFFDC793B) : Colors.transparent,
        side: BorderSide(
          color: isSelected ? const Color(0xFFDC793B) : Colors.grey.shade300,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : Colors.grey,
          ),
          const SizedBox(width: 6),
          Text(
            period,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  // Build summary cards
  Widget _buildSummaryCards() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'Total Pendapatan',
                  value: _formatCurrency(_totalRevenue),
                  icon: Icons.monetization_on,
                  color: const Color(0xFF12B76A),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Jumlah Pesanan',
                  value: '$_totalOrders Pesanan',
                  icon: Icons.shopping_cart,
                  color: const Color(0xFF2E90FA),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'Nilai Rata-rata',
                  value: _totalOrders > 0 ? _formatCurrency(_totalRevenue / _totalOrders) : 'Rp0',
                  icon: Icons.insights,
                  color: const Color(0xFF9E77ED),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Produk Terjual',
                  value: _getTotalProductsSold().toString(),
                  icon: Icons.inventory_2,
                  color: const Color(0xFFF79009),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // Calculate total products sold
  int _getTotalProductsSold() {
    int total = 0;
    
    for (var order in _salesData) {
      List<dynamic> items = order['items'] as List<dynamic>;
      for (var item in items) {
        total += item['quantity'] as int;
      }
    }
    
    return total;
  }
  
  // Build summary card
  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _selectedPeriod == 'Hari' ? Icons.today :
                      _selectedPeriod == 'Minggu' ? Icons.date_range :
                      _selectedPeriod == 'Bulan' ? Icons.calendar_month :
                      Icons.calendar_today,
                      size: 12,
                      color: Colors.grey.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _selectedPeriod,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  // Build summary tab
  Widget _buildSummaryTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Revenue chart
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Grafik Pendapatan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 200,
                    child: _revenueSpots.isNotEmpty
                        ? LineChart(_createLineChartData())
                        : const Center(
                            child: Text(
                              'Tidak ada data untuk ditampilkan',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Status distribution
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Distribusi Status Pesanan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 180,
                    child: _buildStatusDistributionChart(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Create line chart data
  LineChartData _createLineChartData() {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: _maxY / 5,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: max(1, _maxX / 5),
            getTitlesWidget: (value, meta) {
              if (value % 1 != 0 || value < 0 || value > _maxX) {
                return const SizedBox.shrink();
              }
              
              final Map<String, List<Map<String, dynamic>>> groupedData = _groupDataByDate();
              final dates = groupedData.keys.toList()..sort();
              
              if (value.toInt() >= dates.length) {
                return const SizedBox.shrink();
              }
              
              final dateStr = dates[value.toInt()];
              final date = DateTime.parse(dateStr);
              
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  DateFormat('dd/MM').format(date),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: _maxY / 5,
            reservedSize: 60,
            getTitlesWidget: (value, meta) {
              if (value == 0) {
                return const SizedBox.shrink();
              }
              
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(
                  _formatCompactCurrency(value),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: false,
      ),
      minX: 0,
      maxX: _maxX,
      minY: 0,
      maxY: _maxY,
      lineBarsData: [
        LineChartBarData(
          spots: _revenueSpots,
          isCurved: true,
          gradient: const LinearGradient(
            colors: [Color(0xFFDC793B), Color(0xFFEE9B57)],
          ),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: false,
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                const Color(0xFFDC793B).withOpacity(0.2),
                const Color(0xFFEE9B57).withOpacity(0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }
  
  // Format currency in compact form
  String _formatCompactCurrency(double amount) {
    if (amount >= 1000000) {
      return 'Rp${(amount / 1000000).toStringAsFixed(1)}jt';
    } else if (amount >= 1000) {
      return 'Rp${(amount / 1000).toStringAsFixed(1)}rb';
    } else {
      return 'Rp${amount.toInt()}';
    }
  }
  
  // Build status distribution chart
  Widget _buildStatusDistributionChart() {
    // Count orders by status
    Map<String, int> statusCount = {};
    
    for (var order in _salesData) {
      String status = order['status'];
      statusCount[status] = (statusCount[status] ?? 0) + 1;
    }
    
    if (statusCount.isEmpty) {
      return const Center(
        child: Text(
          'Tidak ada data untuk ditampilkan',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    
    // Prepare pie chart sections
    List<PieChartSectionData> sections = [];
    
    statusCount.forEach((status, count) {
      final Color color = _getStatusColor(status);
      final double percentage = count / _totalOrders * 100;
      
      sections.add(
        PieChartSectionData(
          color: color,
          value: count.toDouble(),
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    });
    
    // Status legend
    final List<Widget> legend = statusCount.entries.map((entry) {
      final status = entry.key;
      final count = entry.value;
      final Color color = _getStatusColor(status);
      
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _getStatusText(status),
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(width: 4),
            Text(
              '($count)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }).toList();
    
    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 30,
              sections: sections,
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {},
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: legend,
        ),
      ],
    );
  }
  
  // Build orders tab
  Widget _buildOrdersTab() {
    if (_salesData.isEmpty) {
      return const Center(
        child: Text(
          'Tidak ada data pesanan untuk ditampilkan',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _salesData.length,
      itemBuilder: (context, index) {
        final order = _salesData[index];
        final String orderId = order['id'];
        final DateTime orderDate = DateTime.parse(order['orderDate']);
        final String status = order['status'];
        final double total = order['total'];
        final List<dynamic> items = order['items'] as List<dynamic>;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ExpansionTile(
            title: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pesanan #${orderId.substring(0, min(8, orderId.length))}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd MMM yyyy, HH:mm').format(orderDate),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatCurrency(total),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _getStatusText(status),
                        style: TextStyle(
                          color: _getStatusColor(status),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'Detail Produk:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...items.map((item) {
                      final String name = item['name'];
                      final int quantity = item['quantity'];
                      final double price = (item['price'] as num).toDouble();
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            Text(
                              '$quantity x ${_formatCurrency(price)}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              _formatCurrency(price * quantity),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatCurrency(total),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFFDC793B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  // Build products tab
  Widget _buildProductsTab() {
    // Group by product
    final productData = _groupDataByProduct();
    
    if (productData.isEmpty) {
      return const Center(
        child: Text(
          'Tidak ada data produk untuk ditampilkan',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    
    // Sort products by total revenue
    final sortedProducts = productData.values.toList()
      ..sort((a, b) => (b['total'] as double).compareTo(a['total'] as double));
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedProducts.length,
      itemBuilder: (context, index) {
        final product = sortedProducts[index];
        final String name = product['name'];
        final int quantity = product['quantity'];
        final double total = product['total'];
        
        // Calculate percentage of total revenue
        final double percentage = _totalRevenue > 0 ? (total / _totalRevenue) * 100 : 0;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$quantity terjual',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatCurrency(total),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFFDC793B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${percentage.toStringAsFixed(1)}% dari total pendapatan',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Rata-rata: ${_formatCurrency(total / quantity)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFDC793B)),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}