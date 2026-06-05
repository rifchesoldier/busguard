<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\AttendanceLog;
use App\Models\Bus;
use App\Models\BusRoute;
use App\Models\School;
use App\Models\SchoolClass;
use App\Models\Stop;
use App\Models\Student;
use App\Models\User;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\View\View;

class ResourceController extends Controller
{
    public function schools(): View
    {
        $schools = School::with('admin')->when($this->schoolId(), fn ($q, $id) => $q->where('id', $id))->get();

        return view('admin.schools.index', compact('schools'));
    }

    public function storeSchool(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'name' => 'required|string',
            'city' => 'required|string',
            'address' => 'nullable|string',
        ]);
        School::create($data);

        return back()->with('success', 'École créée avec succès.');
    }

    public function buses(): View
    {
        $buses = Bus::with(['driver', 'school'])
            ->when($this->schoolId(), fn ($q, $id) => $q->where('school_id', $id))
            ->get();
        $schools = School::when($this->schoolId(), fn ($q, $id) => $q->where('id', $id))->get();
        $drivers = User::where('role', 'driver')
            ->when($this->schoolId(), fn ($q, $id) => $q->where('school_id', $id))
            ->get();

        return view('admin.buses.index', compact('buses', 'schools', 'drivers'));
    }

    public function storeBus(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'school_id' => 'required|exists:schools,id',
            'matricule' => 'required|string|unique:buses,matricule',
            'model' => 'nullable|string',
            'capacity' => 'required|integer|min:1',
            'driver_id' => 'nullable|exists:users,id',
        ]);

        $bus = Bus::create($data);
        if (! empty($data['driver_id'])) {
            $bus->drivers()->attach($data['driver_id']);
        }

        return back()->with('success', 'Bus ajouté avec succès.');
    }

    public function routes(): View
    {
        $routes = BusRoute::with(['bus', 'stops', 'school'])
            ->when($this->schoolId(), fn ($q, $id) => $q->where('school_id', $id))
            ->get();
        $buses = Bus::when($this->schoolId(), fn ($q, $id) => $q->where('school_id', $id))->get();
        $schools = School::when($this->schoolId(), fn ($q, $id) => $q->where('id', $id))->get();

        return view('admin.routes.index', compact('routes', 'buses', 'schools'));
    }

    public function storeRoute(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'bus_id' => 'required|exists:buses,id',
            'school_id' => 'required|exists:schools,id',
            'name' => 'required|string',
            'direction' => 'required|in:matin,soir',
            'stop_names' => 'required|array|min:1',
            'stop_lats' => 'required|array',
            'stop_lngs' => 'required|array',
        ]);

        $route = BusRoute::create([
            'bus_id' => $data['bus_id'],
            'school_id' => $data['school_id'],
            'name' => $data['name'],
            'direction' => $data['direction'],
        ]);

        foreach ($data['stop_names'] as $i => $name) {
            Stop::create([
                'route_id' => $route->id,
                'name' => $name,
                'order' => $i + 1,
                'lat' => $data['stop_lats'][$i],
                'lng' => $data['stop_lngs'][$i],
            ]);
        }

        return back()->with('success', 'Itinéraire créé avec succès.');
    }

    public function students(): View
    {
        $students = Student::with(['parent', 'bus', 'stop', 'school'])
            ->when($this->schoolId(), fn ($q, $id) => $q->where('school_id', $id))
            ->get();
        $schools = School::when($this->schoolId(), fn ($q, $id) => $q->where('id', $id))->get();
        $buses = Bus::when($this->schoolId(), fn ($q, $id) => $q->where('school_id', $id))->get();
        $parents = User::where('role', 'parent')->get();

        return view('admin.students.index', compact('students', 'schools', 'buses', 'parents'));
    }

    public function storeStudent(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'first_name' => 'required|string',
            'last_name' => 'required|string',
            'school_id' => 'required|exists:schools,id',
            'class_name' => 'nullable|string',
            'parent_id' => 'nullable|exists:users,id',
            'assigned_bus_id' => 'nullable|exists:buses,id',
            'assigned_stop_id' => 'nullable|exists:stops,id',
        ]);

        Student::create($data);

        return back()->with('success', 'Élève inscrit avec succès.');
    }

    public function drivers(): View
    {
        $drivers = User::where('role', 'driver')
            ->when($this->schoolId(), fn ($q, $id) => $q->where('school_id', $id))
            ->with('drivenBuses')
            ->get();
        $schools = School::when($this->schoolId(), fn ($q, $id) => $q->where('id', $id))->get();

        return view('admin.drivers.index', compact('drivers', 'schools'));
    }

    public function storeDriver(Request $request): RedirectResponse
    {
        $data = $request->validate([
            'name' => 'required|string',
            'email' => 'required|email|unique:users,email',
            'phone' => 'nullable|string',
            'school_id' => 'required|exists:schools,id',
            'password' => 'required|min:8',
        ]);

        User::create([
            ...$data,
            'role' => 'driver',
            'password' => Hash::make($data['password']),
        ]);

        return back()->with('success', 'Chauffeur créé. Identifiants envoyés par email/SMS.');
    }

    public function attendance(): View
    {
        $logs = AttendanceLog::with(['student', 'bus', 'stop', 'driver'])
            ->when($this->schoolId(), fn ($q, $id) => $q->whereHas('student', fn ($s) => $s->where('school_id', $id)))
            ->latest('recorded_at')
            ->paginate(30);

        return view('admin.attendance.index', compact('logs'));
    }

    private function schoolId(): ?int
    {
        $user = Auth::user();

        return $user->role === 'admin' ? $user->school_id : null;
    }
}
