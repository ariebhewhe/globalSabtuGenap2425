import 'package:flutter/material.dart';

enum OrderDirection { asc, desc }

class OrderOptionsDropdown extends StatefulWidget {
  final List<String> orderFields;
  final String? defaultOrderField;
  final OrderDirection? defaultOrderDirection;
  final void Function(String orderBy, OrderDirection direction) onApplySort;
  final String buttonLabel;

  OrderOptionsDropdown({
    Key? key,
    required this.orderFields,
    this.defaultOrderField,
    this.defaultOrderDirection,
    required this.onApplySort,
    this.buttonLabel = 'Sort',
  }) : assert(orderFields.isNotEmpty, 'orderFields must not be empty'),
       super(key: key);

  @override
  State<OrderOptionsDropdown> createState() => _OrderOptionsDropdownState();
}

class _OrderOptionsDropdownState extends State<OrderOptionsDropdown> {
  late String selectedOrderField;
  late String selectedOrderDirection;

  @override
  void initState() {
    super.initState();
    selectedOrderField = widget.defaultOrderField ?? widget.orderFields.first;
    selectedOrderDirection =
        widget.defaultOrderDirection?.name ?? OrderDirection.desc.name;
  }

  @override
  Widget build(BuildContext context) {
    final orderDirections = OrderDirection.values.map((e) => e.name).toList();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            DropdownButton<String>(
              value: selectedOrderField,
              items:
                  widget.orderFields
                      .map(
                        (field) => DropdownMenuItem(
                          value: field,
                          child: Text(
                            field[0].toUpperCase() + field.substring(1),
                          ),
                        ),
                      )
                      .toList(),
              onChanged: (newField) {
                if (newField != null) {
                  setState(() => selectedOrderField = newField);
                }
              },
            ),
            const SizedBox(width: 16),
            DropdownButton<String>(
              value: selectedOrderDirection,
              items:
                  orderDirections
                      .map(
                        (direction) => DropdownMenuItem(
                          value: direction,
                          child: Text(direction.toUpperCase()),
                        ),
                      )
                      .toList(),
              onChanged: (newDirection) {
                if (newDirection != null) {
                  setState(() => selectedOrderDirection = newDirection);
                }
              },
            ),
          ],
        ),
        ElevatedButton(
          onPressed: () {
            final direction = OrderDirection.values.firstWhere(
              (e) => e.name == selectedOrderDirection,
              orElse: () => OrderDirection.desc,
            );
            widget.onApplySort(selectedOrderField, direction);
          },
          child: Text(widget.buttonLabel),
        ),
      ],
    );
  }
}
