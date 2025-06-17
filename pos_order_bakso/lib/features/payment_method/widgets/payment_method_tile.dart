import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jamal/core/theme/app_theme.dart';
import 'package:jamal/core/utils/enums.dart';
import 'package:jamal/data/models/payment_method_model.dart';

class PaymentMethodTile extends StatelessWidget {
  final PaymentMethodModel paymentMethod;
  final VoidCallback? onTap;
  final void Function()? onLongPress;

  const PaymentMethodTile({
    super.key,
    required this.paymentMethod,
    this.onTap,
    this.onLongPress,
  });

  String _formatCurrency(double amount) {
    final format = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return format.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final cardTheme = context.cardTheme;
    final textStyles = context.textStyles;
    final isDarkMode = context.isDarkMode;

    Widget logoWidget;
    if (paymentMethod.logo != null && paymentMethod.logo!.isNotEmpty) {
      logoWidget = CachedNetworkImage(
        // Ganti Image.network menjadi CachedNetworkImage
        imageUrl: paymentMethod.logo!,
        width: 50,
        height: 50,
        fit: BoxFit.contain,
        placeholder:
            (context, url) => Center(
              // Ganti loadingBuilder menjadi placeholder
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDarkMode ? AppTheme.primaryDark : AppTheme.primaryLight,
                ),
                // Tidak perlu value untuk placeholder di CachedNetworkImage versi terbaru,
                // tapi jika menggunakan versi lama atau ingin menampilkan progress yang lebih detail,
                // Anda bisa menggunakan progressIndicatorBuilder.
                // Untuk contoh ini, CircularProgressIndicator sederhana sudah cukup.
              ),
            ),
        errorWidget:
            (context, url, error) => Icon(
              // Ganti errorBuilder menjadi errorWidget
              Icons.payment_rounded,
              size: 40,
              color:
                  isDarkMode
                      ? AppTheme.textSecondaryDark
                      : AppTheme.textSecondaryLight,
            ),
      );
    } else {
      logoWidget = Icon(
        Icons.account_balance_wallet_rounded,
        size: 40,
        color:
            isDarkMode
                ? AppTheme.textSecondaryDark
                : AppTheme.textSecondaryLight,
      );
    }

    return Card(
      child: InkWell(
        onLongPress: onLongPress,
        onTap: onTap,
        borderRadius:
            cardTheme.shape is RoundedRectangleBorder
                ? (cardTheme.shape as RoundedRectangleBorder).borderRadius
                    as BorderRadius?
                : BorderRadius.circular(12),
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
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: (isDarkMode ? AppTheme.bgAltDark : AppTheme.bgAltLight)
                      .withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: logoWidget,
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      paymentMethod.name,
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
                    if (paymentMethod.description != null &&
                        paymentMethod.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        paymentMethod.description!,
                        style: textStyles.bodySmall?.copyWith(
                          color:
                              isDarkMode
                                  ? AppTheme.textTertiaryDark
                                  : AppTheme.textTertiaryLight,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    _buildAmountInfo(
                      context,
                      'Min:',
                      _formatCurrency(paymentMethod.minimumAmount),
                      isDarkMode
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondaryLight,
                    ),
                    const SizedBox(width: 8),
                    _buildAmountInfo(
                      context,
                      'Max:',
                      _formatCurrency(paymentMethod.maximumAmount),
                      isDarkMode
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondaryLight,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Type: ${paymentMethod.paymentMethodType.name}',
                      style: textStyles.labelSmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color:
                            isDarkMode
                                ? AppTheme.textMutedDark
                                : AppTheme.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ),

              if (onTap != null)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color:
                      isDarkMode
                          ? AppTheme.textMutedDark
                          : AppTheme.textMutedLight,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountInfo(
    BuildContext context,
    String label,
    String value,
    Color valueColor,
  ) {
    final textStyles = context.textStyles;
    final isDarkMode = context.isDarkMode;
    return RichText(
      text: TextSpan(
        style: textStyles.bodySmall?.copyWith(
          color:
              isDarkMode
                  ? AppTheme.textTertiaryDark
                  : AppTheme.textTertiaryLight,
        ),
        children: <TextSpan>[
          TextSpan(text: '$label '),
          TextSpan(
            text: value,
            style: TextStyle(fontWeight: FontWeight.w600, color: valueColor),
          ),
        ],
      ),
    );
  }
}
