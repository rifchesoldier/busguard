import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/student_model.dart';
import '../../services/auth_service.dart';
import '../../services/firebase_service.dart';

class DriverAttendanceScreen extends StatefulWidget {
  const DriverAttendanceScreen({super.key});

  @override
  State<DriverAttendanceScreen> createState() => _DriverAttendanceScreenState();
}

class _DriverAttendanceScreenState extends State<DriverAttendanceScreen> {
  final _firebase = FirebaseService();
  List<StudentModel> _students = [];
  final List<Map<String, dynamic>> _pendingQueue = [];
  bool _online = true;
  String? _currentStop;

  @override
  void initState() {
    super.initState();
    _loadStudents();
    Connectivity().onConnectivityChanged.listen((r) {
      final online = !r.contains(ConnectivityResult.none);
      if (online && _pendingQueue.isNotEmpty) _syncQueue();
      if (mounted) setState(() => _online = online);
    });
  }

  Future<void> _loadStudents() async {
    final api = context.read<AuthService>().api;
    try {
      final buses = await api.myBuses();
      if (buses.isEmpty) return;
      final bus = buses.first;
      final res = await api.getStudentsForBus(bus.id);
      if (mounted) setState(() => _students = res);
    } catch (_) {
      if (mounted) {
        setState(() {
          _students = [
            const StudentModel(id: '1', firstName: 'Aminata', lastName: 'Ndiaye', className: 'CM2 A', stopName: 'VDN Mermoz', busId: '1'),
          ];
        });
      }
    }
  }

  Future<void> _mark(StudentModel student, String status) async {
    final auth = context.read<AuthService>();
    final busId = student.busId ?? '1';

    if (!_online) {
      _pendingQueue.add({'student_id': student.id, 'bus_id': busId, 'status': status});
      setState(() {});
      return;
    }

    await auth.api.recordAttendance(studentId: student.id, busId: busId, status: status);
    final fbStatus = status == 'present' ? 'a_bord' : (status == 'absent' ? 'absent' : 'a_bord');
    await _firebase.updateStudentStatus(student.id, fbStatus);

    setState(() {
      _students = _students.map((s) {
        if (s.id == student.id) {
          return StudentModel(
            id: s.id,
            firstName: s.firstName,
            lastName: s.lastName,
            className: s.className,
            stopName: s.stopName,
            busId: s.busId,
            status: status == 'present' ? StudentStatus.aBord : StudentStatus.absent,
          );
        }
        return s;
      }).toList();
    });
  }

  Future<void> _syncQueue() async {
    final auth = context.read<AuthService>();
    for (final item in List.from(_pendingQueue)) {
      await auth.api.recordAttendance(
        studentId: item['student_id'],
        busId: item['bus_id'],
        status: item['status'],
      );
      _pendingQueue.remove(item);
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feuille de présence'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (_online ? BgColors.success : BgColors.gold).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(_online ? Icons.wifi : Icons.wifi_off, size: 16, color: _online ? BgColors.success : BgColors.gold),
                const SizedBox(width: 6),
                Text(_online ? 'En ligne' : 'Hors-ligne (${_pendingQueue.length})', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [BgColors.terracotta.withValues(alpha: 0.1), BgColors.gold.withValues(alpha: 0.1)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.place_rounded, color: BgColors.terracotta),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Arrêt actuel', style: GoogleFonts.dmSans(fontSize: 12, color: BgColors.dusk.withValues(alpha: 0.6))),
                      Text(_currentStop ?? 'Arrêt VDN Mermoz', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _students.length,
              itemBuilder: (_, i) {
                final s = _students[i];
                final isPresent = s.status == StudentStatus.aBord;
                final isAbsent = s.status == StudentStatus.absent;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BgTheme.glassCard(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: BgColors.sage.withValues(alpha: 0.2),
                            child: Text(s.firstName[0], style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.fullName, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 17)),
                                Text(s.className ?? '', style: GoogleFonts.dmSans(fontSize: 13, color: BgColors.dusk.withValues(alpha: 0.6))),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _BigButton(
                              label: 'PRÉSENT',
                              icon: Icons.check_circle_rounded,
                              color: BgColors.success,
                              selected: isPresent,
                              onTap: () => _mark(s, 'present'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _BigButton(
                              label: 'ABSENT',
                              icon: Icons.cancel_rounded,
                              color: BgColors.danger,
                              selected: isAbsent,
                              onTap: () => _mark(s, 'absent'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BigButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _BigButton({required this.label, required this.icon, required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: selected ? 1 : 0.3), width: selected ? 2 : 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? Colors.white : color, size: 28),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 13, color: selected ? Colors.white : color)),
          ],
        ),
      ),
    );
  }
}
