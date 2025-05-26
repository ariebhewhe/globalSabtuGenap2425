import 'package:flutter/material.dart';
import 'package:jamal/core/theme/app_theme.dart';
import 'package:jamal/core/utils/enums.dart';
import 'package:jamal/data/models/restaurant_table_model.dart';

class RestaurantTableTile extends StatelessWidget {
  final RestaurantTableModel restaurantTable;
  final VoidCallback? onTap;

  const RestaurantTableTile({
    super.key,
    required this.restaurantTable,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardTheme = context.cardTheme;
    final textStyles = context.textStyles;
    final isDarkMode = context.isDarkMode;

    final Color availableColor =
        isDarkMode ? Colors.green.shade300 : Colors.green.shade600;
    final Color unavailableColor =
        isDarkMode ? Colors.red.shade300 : Colors.red.shade700;
    final Color statusColor =
        restaurantTable.isAvailable ? availableColor : unavailableColor;

    return Card(
      margin:
          cardTheme.margin ??
          const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            cardTheme.shape is RoundedRectangleBorder
                ? (cardTheme.shape as RoundedRectangleBorder).borderRadius
                    .resolve(Directionality.of(context))
                : BorderRadius.circular(8.0), // Default border radius
        splashColor: (isDarkMode ? AppTheme.primaryDark : AppTheme.primaryLight)
            .withOpacity(0.1),
        highlightColor: (isDarkMode
                ? AppTheme.primaryDark
                : AppTheme.primaryLight)
            .withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Icon Section
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: (isDarkMode ? AppTheme.bgAltDark : AppTheme.bgAltLight)
                      .withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: statusColor.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.table_restaurant_rounded,
                  size: 32,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 16),

              // Details Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Meja ${restaurantTable.tableNumber}',
                      style: textStyles.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color:
                            isDarkMode
                                ? AppTheme.textPrimaryDark
                                : AppTheme.textPrimaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.people_alt_rounded,
                          size: 14,
                          color:
                              isDarkMode
                                  ? AppTheme.textTertiaryDark
                                  : AppTheme.textTertiaryLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Kapasitas: ${restaurantTable.capacity} orang',
                          style: textStyles.bodySmall?.copyWith(
                            color:
                                isDarkMode
                                    ? AppTheme.textSecondaryDark
                                    : AppTheme.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          restaurantTable.location.icon,
                          size: 14,
                          color:
                              isDarkMode
                                  ? AppTheme.textTertiaryDark
                                  : AppTheme.textTertiaryLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Lokasi: ${restaurantTable.location.displayName}',
                          style: textStyles.bodySmall?.copyWith(
                            color:
                                isDarkMode
                                    ? AppTheme.textSecondaryDark
                                    : AppTheme.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Chip(
                      avatar: Icon(
                        restaurantTable.isAvailable
                            ? Icons.check_circle_outline_rounded
                            : Icons.highlight_off_rounded,
                        color: Colors.white70, // Warna icon di dalam chip
                        size: 16,
                      ),
                      label: Text(
                        restaurantTable.isAvailable
                            ? 'Tersedia'
                            : 'Tidak Tersedia',
                        style: textStyles.labelSmall?.copyWith(
                          color: Colors.white, // Warna teks di dalam chip
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      backgroundColor: statusColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 2.0,
                      ),
                      labelPadding: const EdgeInsets.only(
                        left: 4.0,
                        right: 6.0,
                      ), // Adjust padding for label and icon
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ),

              // Arrow Icon if onTap is available
              if (onTap != null) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color:
                      isDarkMode
                          ? AppTheme.textMutedDark
                          : AppTheme.textMutedLight,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
