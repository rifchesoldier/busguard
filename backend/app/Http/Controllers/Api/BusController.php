<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Bus;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class BusController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $query = Bus::with(['driver'])->where(function($q) {
            $q->where('is_active', true)->orWhereNull('is_active');
        });

        if ($user->role === 'admin') {
            $query->where('school_id', $user->school_id);
        } elseif ($user->role === 'driver') {
            $query->whereHas('drivers', fn ($q) => $q->where('user_id', $user->id));
        }
        // superadmin → tous les bus

        return response()->json($query->get());
    }

    public function store(Request $request): JsonResponse
    {
        abort_unless($request->user()->isAdmin(), 403);

        $data = $request->validate([
            'school_id' => 'required|exists:schools,id',
            'matricule' => 'required|string|unique:buses,matricule',
            'model' => 'nullable|string',
            'capacity' => 'nullable|integer|min:1',
            'driver_id' => 'nullable|exists:users,id',
        ]);

        $bus = Bus::create(array_merge($data, ['is_active' => true]));

        if (! empty($data['driver_id'])) {
            $bus->drivers()->attach($data['driver_id']);
        }

        return response()->json($bus->load('driver'), 201);
    }

    public function show(Bus $bus): JsonResponse
    {
        return response()->json($bus->load(['driver', 'routes.stops', 'students']));
    }

    public function update(Request $request, Bus $bus): JsonResponse
    {
        abort_unless($request->user()->isAdmin() || $request->user()->id === $bus->driver_id, 403);

        $data = $request->validate([
            'status' => 'sometimes|in:idle,en_route,arrived,signal_perdu',
            'last_lat' => 'sometimes|numeric',
            'last_lng' => 'sometimes|numeric',
            'traffic_alert' => 'nullable|string',
            'driver_id' => 'sometimes|nullable|exists:users,id',
            'model' => 'sometimes|nullable|string',
            'capacity' => 'sometimes|nullable|integer|min:1',
        ]);

        if (isset($data['last_lat'])) {
            $data['last_position_at'] = now();
        }

        $bus->update($data);

        return response()->json($bus);
    }

    public function destroy(Request $request, Bus $bus): JsonResponse
    {
        abort_unless($request->user()->isAdmin(), 403);
        $bus->update(['is_active' => false]);

        return response()->json(['message' => 'Bus désactivé.']);
    }
}
