<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Student;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class StudentController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = Student::with(['parent', 'bus', 'stop', 'school']);

        if ($request->user()->role === 'admin') {
            $query->where('school_id', $request->user()->school_id);
        }

        return response()->json($query->get());
    }

    public function myChildren(Request $request): JsonResponse
    {
        $children = $request->user()->children()
            ->with(['bus', 'stop', 'school'])
            ->where('is_active', true)
            ->get();

        return response()->json($children);
    }

    public function store(Request $request): JsonResponse
    {
        $user = $request->user();

        // Un parent peut inscrire son propre enfant
        if ($user->role === 'parent') {
            $data = $request->validate([
                'first_name' => 'required|string',
                'last_name'  => 'required|string',
                'school_id'  => 'required|exists:schools,id',
                'class_name' => 'nullable|string',
            ]);
            $student = Student::create([
                ...$data,
                'parent_id'      => $user->id,
                'current_status' => 'en_attente',
            ]);
            return response()->json($student, 201);
        }

        abort_unless($user->isAdmin(), 403);

        $data = $request->validate([
            'first_name' => 'required|string',
            'last_name'  => 'required|string',
            'school_id'  => 'required|exists:schools,id',
            'class_id'   => 'nullable|exists:school_classes,id',
            'class_name' => 'nullable|string',
            'parent_id'  => 'nullable|exists:users,id',
        ]);

        $student = Student::create($data);

        return response()->json($student, 201);
    }

    public function assignBus(Request $request, Student $student): JsonResponse
    {
        abort_unless($request->user()->isAdmin(), 403);

        $data = $request->validate([
            'assigned_bus_id' => 'required|exists:buses,id',
            'assigned_stop_id' => 'required|exists:stops,id',
        ]);

        $student->update($data);

        return response()->json($student->load(['bus', 'stop', 'parent']));
    }

    public function show(Student $student): JsonResponse
    {
        return response()->json($student->load(['parent', 'bus', 'stop', 'school']));
    }

    public function update(Request $request, Student $student): JsonResponse
    {
        $user = $request->user();

        if ($user->role === 'parent') {
            abort_unless($student->parent_id === $user->id, 403);
            $student->update($request->validate([
                'photo_url' => 'nullable|string',
            ]));
        } else {
            abort_unless($user->isAdmin() || $user->role === 'driver', 403);
            $student->update($request->validate([
                'current_status' => 'sometimes|in:en_attente,a_bord,arrive,absent',
                'assigned_bus_id' => 'sometimes|nullable|exists:buses,id',
                'assigned_stop_id' => 'sometimes|nullable|exists:stops,id',
            ]));
        }

        return response()->json($student);
    }

    public function destroy(Request $request, Student $student): JsonResponse
    {
        abort_unless($request->user()->isAdmin(), 403);
        $student->update(['is_active' => false]);

        return response()->json(['message' => 'Élève désactivé.']);
    }
}
