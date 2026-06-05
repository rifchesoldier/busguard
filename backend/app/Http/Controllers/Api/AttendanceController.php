<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AttendanceLog;
use App\Models\Student;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\StreamedResponse;

class AttendanceController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = AttendanceLog::with(['student', 'bus', 'stop', 'driver'])
            ->when($request->date, fn ($q) => $q->whereDate('date', $request->date))
            ->when($request->bus_id, fn ($q) => $q->where('bus_id', $request->bus_id));

        if ($request->user()->role === 'admin') {
            $query->whereHas('student', fn ($q) => $q->where('school_id', $request->user()->school_id));
        }

        return response()->json($query->latest('recorded_at')->paginate(50));
    }

    public function store(Request $request): JsonResponse
    {
        abort_unless(in_array($request->user()->role, ['driver', 'admin'], true), 403);

        $data = $request->validate([
            'student_id' => 'required|exists:students,id',
            'bus_id' => 'required|exists:buses,id',
            'stop_id' => 'nullable|exists:stops,id',
            'status' => 'required|in:present,absent,anomalie',
            'notes' => 'nullable|string',
        ]);

        $statusMap = [
            'present' => 'a_bord',
            'absent' => 'absent',
            'anomalie' => 'a_bord',
        ];

        $log = AttendanceLog::create([
            ...$data,
            'date' => now()->toDateString(),
            'recorded_by_driver_id' => $request->user()->id,
            'recorded_at' => now(),
        ]);

        Student::where('id', $data['student_id'])->update([
            'current_status' => $statusMap[$data['status']],
        ]);

        return response()->json($log->load(['student', 'stop']), 201);
    }

    public function studentHistory(Student $student): JsonResponse
    {
        $logs = $student->attendanceLogs()
            ->with(['bus', 'stop'])
            ->where('date', '>=', now()->subYear())
            ->latest('recorded_at')
            ->get();

        return response()->json($logs);
    }

    public function export(Request $request): StreamedResponse
    {
        abort_unless($request->user()->isAdmin(), 403);

        $logs = AttendanceLog::with(['student', 'bus', 'stop'])
            ->when($request->date_from, fn ($q) => $q->whereDate('date', '>=', $request->date_from))
            ->when($request->date_to, fn ($q) => $q->whereDate('date', '<=', $request->date_to))
            ->get();

        return response()->streamDownload(function () use ($logs) {
            $handle = fopen('php://output', 'w');
            fputcsv($handle, ['Date', 'Élève', 'Bus', 'Arrêt', 'Statut', 'Heure']);

            foreach ($logs as $log) {
                fputcsv($handle, [
                    $log->date->format('Y-m-d'),
                    $log->student->full_name,
                    $log->bus->matricule,
                    $log->stop?->name ?? '-',
                    $log->status,
                    $log->recorded_at->format('H:i'),
                ]);
            }
            fclose($handle);
        }, 'presences_'.now()->format('Y-m-d').'.csv');
    }
}
