// Buat file baru: lib/features/admin/view/debug_overdue_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:perpusglo/features/borrow/data/borrow_repository.dart';
import '../../borrow/providers/borrow_provider.dart';

class DebugOverduePage extends ConsumerWidget {
  const DebugOverduePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overdueCheckAsync = ref.watch(debugOverdueCheckProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Overdue Books'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(debugOverdueCheckProvider),
          ),
          IconButton(
            icon: const Icon(Icons.update),
            onPressed: () {
              ref.read(checkOverdueBooksProvider.future).then((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Overdue status updated')),
                );
                ref.refresh(debugOverdueCheckProvider);
                ref.refresh(userBorrowHistoryProvider);
              });
            },
            tooltip: 'Update overdue status',
          ),
        ],
      ),
      body: overdueCheckAsync.when(
        data: (overdueBooks) {
          if (overdueBooks.isEmpty) {
            return const Center(child: Text('No overdue books found'));
          }

          return ListView.builder(
            itemCount: overdueBooks.length,
            itemBuilder: (context, index) {
              final book = overdueBooks[index];
              final dateFormat = DateFormat('dd MMM yyyy');

              return Card(
                margin: const EdgeInsets.all(8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Book: ${book['bookTitle']}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('Borrow ID: ${book['borrowId']}'),
                      Text('Due Date: ${dateFormat.format(book['dueDate'])}'),
                      const Divider(),
                      Text('Days Late: ${book['daysLate']}',
                          style: const TextStyle(color: Colors.red)),
                      Text('Calculated Fine: Rp ${book['calculatedFine']}',
                          style: const TextStyle(color: Colors.red)),
                      const Divider(),
                      Text('Current Status: ${book['currentStatus']}'),
                      Text('Current Fine: Rp ${book['currentFine']}'),
                      const SizedBox(height: 16),
                      // Di debug_overdue_page.dart
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            // Force update this specific borrow using the public method
                            await ref
                                .read(borrowRepositoryProvider)
                                .updateBorrowStatusToOverdue(
                                  book['borrowId'],
                                  book['calculatedFine'],
                                );

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Status updated to overdue')),
                              );
                              ref.refresh(debugOverdueCheckProvider);
                              ref.refresh(userBorrowHistoryProvider);
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        },
                        child: const Text('Force Update to Overdue'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Panggil periodical check
          ref.read(checkOverdueBooksProvider.future).then((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Overdue status check completed')),
            );
            ref.refresh(debugOverdueCheckProvider);
          });
        },
        child: const Icon(Icons.schedule),
        tooltip: 'Run overdue check',
      ),
    );
  }
}