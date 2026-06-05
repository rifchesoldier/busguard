<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\AttendanceLog;
use App\Models\Bus;
use App\Models\School;
use App\Models\Student;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\View\View;

class DashboardController extends Controller
{
    public function index(): View
    {
        $user = Auth::user();
        $schoolFilter = $user->role === 'admin' ? $user->school_id : null;

        $stats = [
            'schools' => School::when($schoolFilter, fn ($q) => $q->where('id', $schoolFilter))->count(),
            'buses' => Bus::when($schoolFilter, fn ($q) => $q->where('school_id', $schoolFilter))->count(),
            'students' => Student::when($schoolFilter, fn ($q) => $q->where('school_id', $schoolFilter))->count(),
            'drivers' => User::where('role', 'driver')
                ->when($schoolFilter, fn ($q) => $q->where('school_id', $schoolFilter))
                ->count(),
            'active_buses' => Bus::when($schoolFilter, fn ($q) => $q->where('school_id', $schoolFilter))
                ->where('status', 'en_route')->count(),
            'today_presences' => AttendanceLog::whereDate('date', today())
                ->where('status', 'present')
                ->when($schoolFilter, fn ($q) => $q->whereHas('student', fn ($s) => $s->where('school_id', $schoolFilter)))
                ->count(),
        ];

        $recentLogs = AttendanceLog::with(['student', 'bus'])
            ->when($schoolFilter, fn ($q) => $q->whereHas('student', fn ($s) => $s->where('school_id', $schoolFilter)))
            ->latest('recorded_at')
            ->limit(8)
            ->get();

        $activeBuses = Bus::with(['driver', 'school'])
            ->when($schoolFilter, fn ($q) => $q->where('school_id', $schoolFilter))
            ->whereIn('status', ['en_route', 'signal_perdu'])
            ->get();

        return view('admin.dashboard', compact('stats', 'recentLogs', 'activeBuses'));
    }
}
