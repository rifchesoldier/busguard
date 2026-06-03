import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/child.dart';
import '../utils/theme.dart';
import '../widgets/child_card.dart';

class ChildrenScreen extends StatefulWidget {
  const ChildrenScreen({super.key});

  @override
  State<ChildrenScreen> createState() => _ChildrenScreenState();
}

class _ChildrenScreenState extends State<ChildrenScreen> {
  List<Child> _children = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await SupabaseService.getMyChildren();
    if (mounted) setState(() { _children = list; _loading = false; });
  }

  Future<void> _showAddDialog() async {
    final name = TextEditingController();
    final grade = TextEditingController();
    final school = TextEditingController();
    final stop = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ajouter un enfant'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Nom complet')),
            TextField(controller: grade, decoration: const InputDecoration(labelText: 'Classe')),
            TextField(controller: school, decoration: const InputDecoration(labelText: 'École')),
            TextField(controller: stop, decoration: const InputDecoration(labelText: 'Arrêt')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ajouter')),
        ],
      ),
    );
    if (ok == true && name.text.isNotEmpty) {
      final uid = Supabase.instance.client.auth.currentUser!.id;
      await SupabaseService.addChild(Child(
        id: '', parentId: uid, fullName: name.text,
        grade: grade.text, school: school.text, stopName: stop.text,
      ));
      _load();
    }
  }

  Future<void> _delete(String id) async {
    await SupabaseService.deleteChild(id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes enfants')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.yellow,
        onPressed: _showAddDialog,
        child: const Icon(Icons.add, color: AppColors.navy),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _children.isEmpty
              ? const Center(child: Text('Aucun enfant enregistré'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _children.length,
                  itemBuilder: (_, i) => ChildCard(
                    child: _children[i],
                    onDelete: () => _delete(_children[i].id),
                  ),
                ),
    );
  }
}
