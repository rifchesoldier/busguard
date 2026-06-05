<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\School;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SchoolController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = School::with(['admin', 'classes', 'buses']);

        if ($request->user()->role === 'admin') {
            $query->where('id', $request->user()->school_id);
        }

        return response()->json($query->get());
    }

    public function store(Request $request): JsonResponse
    {
        $this->authorizeAdmin($request);

        $data = $request->validate([
            'name' => 'required|string',
            'city' => 'nullable|string',
            'address' => 'nullable|string',
            'lat' => 'nullable|numeric',
            'lng' => 'nullable|numeric',
            'admin_id' => 'nullable|exists:users,id',
        ]);

        $school = School::create($data);

        return response()->json($school, 201);
    }

    public function show(School $school): JsonResponse
    {
        return response()->json($school->load(['classes', 'buses.driver', 'students']));
    }

    public function update(Request $request, School $school): JsonResponse
    {
        $this->authorizeAdmin($request);
        $school->update($request->validate([
            'name' => 'sometimes|string',
            'city' => 'sometimes|string',
            'address' => 'nullable|string',
            'is_active' => 'sometimes|boolean',
        ]));

        return response()->json($school);
    }

    public function destroy(Request $request, School $school): JsonResponse
    {
        $this->authorizeAdmin($request);
        $school->update(['is_active' => false]);

        return response()->json(['message' => 'École désactivée.']);
    }

    private function authorizeAdmin(Request $request): void
    {
        abort_unless($request->user()->isAdmin(), 403);
    }
}
