<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Bus;
use App\Models\Student;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class StatsController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $schoolId = $user->school_id;
        $isSuperAdmin = $user->role === 'superadmin';

        // ── Bus ──────────────────────────────────────────────────────────
        $busQuery = Bus::where('is_active', true);
        if (!$isSuperAdmin && $schoolId) {
            $busQuery->where('school_id', $schoolId);
        }
        $totalBuses = $busQuery->count();

        // ── Élèves ───────────────────────────────────────────────────────
        $studentQuery = Student::where('is_active', true);
        if (!$isSuperAdmin && $schoolId) {
            $studentQuery->where('school_id', $schoolId);
        }
        $totalStudents     = $studentQuery->count();
        $assignedStudents  = (clone $studentQuery)->whereNotNull('assigned_bus_id')->count();
        $unassignedStudents = $totalStudents - $assignedStudents;

        // ── Parents ayant inscrit au moins un enfant ─────────────────────
        $parentQuery = User::where('role', 'parent')
            ->whereHas('children', function ($q) use ($isSuperAdmin, $schoolId) {
                if (!$isSuperAdmin && $schoolId) {
                    $q->where('school_id', $schoolId);
                }
            });
        $totalParents = $parentQuery->count();

        // ── Chauffeurs ───────────────────────────────────────────────────
        $driverQuery = User::where('role', 'driver')->where('is_active', true);
        if (!$isSuperAdmin && $schoolId) {
            $driverQuery->where('school_id', $schoolId);
        }
        $totalDrivers = $driverQuery->count();

        return response()->json([
            'buses'              => $totalBuses,
            'students_total'     => $totalStudents,
            'students_assigned'  => $assignedStudents,
            'students_unassigned'=> $unassignedStudents,
            'parents'            => $totalParents,
            'drivers'            => $totalDrivers,
        ]);
    }
}
