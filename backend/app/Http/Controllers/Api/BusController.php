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
            $query->where(function($q) use ($user) {
                $q->where('driver_id', $user->id)
                  ->orWhereHas('drivers', fn ($dq) => $dq->where('user_id', $user->id));
            });
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

    public function updatePosition(Request $request, Bus $bus): JsonResponse
    {
        // Seul le chauffeur assigné à ce bus peut mettre à jour sa position
        $user = $request->user();
        $isAssigned = $user->id === $bus->driver_id
            || $bus->drivers()->where('user_id', $user->id)->exists();

        abort_unless($isAssigned || $user->isAdmin(), 403, 'Non autorisé à mettre à jour ce bus.');

        $data = $request->validate([
            'lat'    => 'required|numeric|between:-90,90',
            'lng'    => 'required|numeric|between:-180,180',
            'status' => 'sometimes|in:en_route,idle,arrived,signal_perdu',
        ]);

        $bus->update([
            'last_lat'         => $data['lat'],
            'last_lng'         => $data['lng'],
            'last_position_at' => now(),
            'status'           => $data['status'] ?? 'en_route',
        ]);

        // Réponse légère — le client n'a pas besoin de tout le modèle
        return response()->json([
            'ok'  => true,
            'lat' => $data['lat'],
            'lng' => $data['lng'],
            'ts'  => now()->toISOString(),
        ]);
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
