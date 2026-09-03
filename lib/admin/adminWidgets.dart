import 'package:flutter/material.dart';

import 'adminConstents.dart';

/// A white, elevated "3D" card wrapper reused across admin pages.
class AdminCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const AdminCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// A consistently styled text field used across the "Add / Edit" admin forms.
class AdminFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final int maxLines;
  final bool obscureText;

  const AdminFormField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: obscureText ? 1 : maxLines, // obscured fields must be single-line
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF6366F1)),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      ),
    );
  }
}

/// A labeled dropdown, used for "Category" pickers etc.
class AdminDropdownField extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const AdminDropdownField({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF6366F1)),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 14),
      ),
    );
  }
}

/// Chip-style gender / section selector (Boys / Girls / Mixed).
class GenderSelector extends StatelessWidget {
  final String? value;
  final ValueChanged<String> onChanged;

  const GenderSelector({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gender',
          style: TextStyle(color: Color(0xff6B7280), fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          children: kGenderOptions.map((g) {
            final selected = value == g;
            return ChoiceChip(
              label: Text(g),
              selected: selected,
              onSelected: (_) => onChanged(g),
              selectedColor: const Color(0xFF6366F1),
              labelStyle: TextStyle(
                color: selected ? Colors.white : const Color(0xff374151),
                fontWeight: FontWeight.w600,
              ),
              backgroundColor: const Color(0xFFF9FAFB),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: selected ? const Color(0xFF6366F1) : Colors.grey.shade300),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Two ordered dropdowns ("From class" -> "To class") for a Category's range.
class ClassRangeSelector extends StatelessWidget {
  final String? fromValue;
  final String? toValue;
  final ValueChanged<String?> onFromChanged;
  final ValueChanged<String?> onToChanged;

  const ClassRangeSelector({
    super.key,
    required this.fromValue,
    required this.toValue,
    required this.onFromChanged,
    required this.onToChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Class Range',
          style: TextStyle(color: Color(0xff6B7280), fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: AdminDropdownField(
                label: 'From Class',
                icon: Icons.first_page_rounded,
                value: fromValue,
                items: kClassOptions,
                onChanged: onFromChanged,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AdminDropdownField(
                label: 'To Class',
                icon: Icons.last_page_rounded,
                value: toValue,
                items: kClassOptions,
                onChanged: onToChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A gradient primary button used for form submissions.
class AdminSubmitButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;
  final Color color;

  const AdminSubmitButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.color = const Color(0xFF6366F1),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 6,
          shadowColor: color.withOpacity(0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: loading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        )
            : Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

/// Tappable, tactile "3D" dashboard card used for Quick Actions.
class AdminActionCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String count;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const AdminActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.count,
    required this.onTap,
  });

  @override
  State<AdminActionCard> createState() => _AdminActionCardState();
}

class _AdminActionCardState extends State<AdminActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        transform: Matrix4.identity()
          ..translate(0.0, _pressed ? 3.0 : 0.0),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              widget.color.withOpacity(0.95),
              widget.color.withOpacity(0.75),
            ],
          ),
          boxShadow: _pressed
              ? [
            BoxShadow(
              color: widget.color.withOpacity(0.35),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ]
              : [
            BoxShadow(
              color: widget.color.withOpacity(0.45),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
            const BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.icon,
                    color: Colors.white,
                    size: 15,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  widget.count,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),


            // Title
            Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),

            // Subtitle
            Text(
              widget.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tappable overview stat tile (Total Programs, Teams, Judges, etc).
class OverviewStatTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color backColor;
  final VoidCallback? onTap;

  const OverviewStatTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.backColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: backColor, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            Text(title, style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold)),
            Text(subtitle, style: const TextStyle(color: Color(0xff6B7280), fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

/// A row-style tile for list pages (category/program/judge/team) with edit + delete.
class AdminListTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData leadingIcon;
  final Color leadingColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AdminListTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.leadingIcon,
    required this.leadingColor,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: leadingColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(leadingIcon, color: leadingColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xff1F2937))),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Color(0xff6B7280), fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded, color: Color(0xFF6366F1), size: 20),
            tooltip: 'Edit',
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }
}

/// Simple empty-state placeholder for list pages with zero items.
class AdminEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const AdminEmptyState({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(icon, size: 46, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Color(0xff6B7280), fontSize: 13)),
        ],
      ),
    );
  }
}

/// Shows a consistent success AlertDialog, e.g. "Team added successfully".
Future<void> showAdminSuccessDialog(BuildContext context, {required String message}) {
  return showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)),
          SizedBox(width: 8),
          Text('Success'),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
      ],
    ),
  );
}

/// Shows a confirm-delete dialog; returns true if the user confirmed.
Future<bool> showAdminDeleteConfirm(BuildContext context, {required String itemName}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Delete this item?'),
      content: Text('This will permanently remove "$itemName".'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete', style: TextStyle(color: Color(0xFFEF4444))),
        ),
      ],
    ),
  );
  return result ?? false;
}