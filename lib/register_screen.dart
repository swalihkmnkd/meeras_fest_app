import 'package:flutter/material.dart';
import 'package:meeras_fest_app/register_provider.dart';
import 'package:provider/provider.dart';
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 30,),
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Text("Register Programs",style: TextStyle(color: Color(0xff1F2937),fontWeight: FontWeight.bold,fontSize: 18),),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Text("Add participants for your team",style: TextStyle(color: Color(0xff6B7280),fontWeight: FontWeight.w400,fontSize: 12),),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: StudentEntryForm(),
            ),
          ),
        ],
      ),
    );
  }
}


// =====================================================================
// 2. UI (StatelessWidget) — reads state via Provider/Consumer
// =====================================================================
class StudentEntryForm extends StatelessWidget {
  const StudentEntryForm({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch only where needed; the whole card is cheap enough to rebuild here.
    final provider = context.watch<StudentEntryProvider>();

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ---- Student Name (Autocomplete text field) ----
          const _FieldLabel('Student Name'),
          const SizedBox(height: 8),
          _NameAutocomplete(provider: provider),

          const SizedBox(height: 20),

          // ---- Category & Program (Dropdowns) ----
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DropdownField(
                  label: 'Category',
                  hint: 'Select category',
                  value: provider.selectedCategory,
                  items: provider.categoryOptions,
                  onChanged: provider.setCategory,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _DropdownField(
                  label: 'Program',
                  hint: 'Select program',
                  value: provider.selectedProgram,
                  items: provider.programOptions,
                  onChanged: provider.setProgram,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ---- Add to List button ----
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final error = provider.addToList();
                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error)),
                  );
                }
              },
              icon: const Icon(Icons.add, size: 12,),
              label: const Text(
                'Add to List',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A2E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// 3. Small stateless helper widgets
// =====================================================================

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF4B5563),
      ),
    );
  }
}

/// Shared box styling (border, radius, background) used by the
/// name field and the two dropdowns so they look consistent.
class _BoxWrapper extends StatelessWidget {
  final Widget child;
  const _BoxWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4E4EA)),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

/// Text field with autocomplete suggestions, reading/writing via the provider.
class _NameAutocomplete extends StatelessWidget {
  final StudentEntryProvider provider;
  const _NameAutocomplete({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<String>.empty();
        }
        return provider.nameSuggestions.where((option) => option
            .toLowerCase()
            .contains(textEditingValue.text.toLowerCase()));
      },
      onSelected: provider.setName,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        controller.addListener(() {
          if (provider.nameController.text != controller.text) {
            provider.nameController.text = controller.text;
          }
        });
        return _BoxWrapper(
          child: TextField(style: TextStyle(fontSize: 12),
            controller: controller,
            focusNode: focusNode,
            decoration: const InputDecoration(
              hintText: 'Enter full name',
              hintStyle: TextStyle(fontSize: 12,color: Color(0xff9CA3AF)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 0),
            ),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220, maxWidth: 320),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    title: Text(option,style: TextStyle(fontSize: 12,),),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Reusable dropdown field styled like the design (label + boxed field).
class _DropdownField extends StatelessWidget {
  final String label;
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        const SizedBox(height: 8),
        _BoxWrapper(
          child: DropdownButtonHideUnderline(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: DropdownButton<String>(
                style: TextStyle(fontSize: 12,color: Colors.black),
                value: value,
                isExpanded: true,
                hint: Text(
                  hint,
                  style: TextStyle(color: Color(0xff9CA3AF), fontSize: 12),
                ),
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                items: items
                    .map(
                      (item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(item, style: const TextStyle(fontSize: 12)),
                  ),
                )
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

