import 'package:flutter/material.dart';

import '../../../core/utils/validators.dart';
import '../../../core/widgets/animations.dart';
import '../../../core/widgets/common.dart';
import '../../catalog/presentation/pickers.dart';
import '../domain/pharmacy.dart';

/// Shared "register your pharmacy / hospital" form.
class FacilityApplyForm extends StatefulWidget {
  const FacilityApplyForm({super.key, required this.kind, required this.onSubmit, this.withDescription = false});

  final String kind; // "pharmacy" | "hospital"
  final Future<void> Function(FacilityApplication) onSubmit;
  final bool withDescription;

  @override
  State<FacilityApplyForm> createState() => _FacilityApplyFormState();
}

class _FacilityApplyFormState extends State<FacilityApplyForm> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _desc = TextEditingController();
  String? _area;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _address, _phone, _desc]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await widget.onSubmit(FacilityApplication(
        name: _name.text,
        areaId: _area!,
        address: _address.text,
        phone: _phone.text,
        description: _desc.text,
      ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fields = <Widget>[
      Text('Tell us about your ${widget.kind}. Our team reviews every request before it goes live.', style: Theme.of(context).textTheme.bodyMedium),
      TextFormField(controller: _name, textCapitalization: TextCapitalization.words, decoration: InputDecoration(labelText: '${widget.kind[0].toUpperCase()}${widget.kind.substring(1)} name', prefixIcon: const Icon(Icons.storefront_outlined)), validator: (v) => v == null || v.trim().length < 3 ? 'Enter the name' : null),
      AreaPicker(onChanged: (_, a) => _area = a),
      TextFormField(controller: _address, decoration: const InputDecoration(labelText: 'Street address', prefixIcon: Icon(Icons.place_outlined)), validator: (v) => Validators.required(v, 'Address')),
      TextFormField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone_outlined))),
      if (widget.withDescription) TextFormField(controller: _desc, maxLines: 3, decoration: const InputDecoration(labelText: 'Description (services, departments)', alignLabelWithHint: true)),
    ];
    return Form(
      key: _form,
      child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 32), children: [
        for (var i = 0; i < fields.length; i++) Padding(padding: const EdgeInsets.only(bottom: 14), child: fields[i].entrance(i)),
        PrimaryButton(label: 'Send request', icon: Icons.send_rounded, busy: _busy, onPressed: _submit).entrance(fields.length),
      ]),
    );
  }
}
