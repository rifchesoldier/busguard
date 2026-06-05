<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\BusRoute;
use App\Models\Stop;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class RouteController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = BusRoute::with(['stops', 'bus', 'school']);

        if ($request->user()->role === 'admin') {
            $query->where('school_id', $request->user()->school_id);
        }

        return response()->json($query->get());
    }

    public function store(Request $request): JsonResponse
    {
        abort_unless($request->user()->isAdmin(), 403);

        $data = $request->validate([
            'bus_id' => 'required|exists:buses,id',
            'school_id' => 'required|exists:schools,id',
            'name' => 'required|string',
            'direction' => 'required|in:matin,soir',
            'scheduled_start' => 'nullable|date_format:H:i',
            'stops' => 'required|array|min:1',
            'stops.*.name' => 'required|string',
            'stops.*.order' => 'required|integer',
            'stops.*.lat' => 'required|numeric',
            'stops.*.lng' => 'required|numeric',
        ]);

        return DB::transaction(function () use ($data) {
            $route = BusRoute::create(collect($data)->except('stops')->toArray());

            foreach ($data['stops'] as $stop) {
                Stop::create([
                    'route_id' => $route->id,
                    'name' => $stop['name'],
                    'order' => $stop['order'],
                    'lat' => $stop['lat'],
                    'lng' => $stop['lng'],
                ]);
            }

            return response()->json($route->load('stops'), 201);
        });
    }

    public function show(BusRoute $route): JsonResponse
    {
        return response()->json($route->load(['stops', 'bus']));
    }

    public function update(Request $request, BusRoute $route): JsonResponse
    {
        abort_unless($request->user()->isAdmin(), 403);
        $route->update($request->validate([
            'name' => 'sometimes|string',
            'direction' => 'sometimes|in:matin,soir',
            'is_active' => 'sometimes|boolean',
        ]));

        return response()->json($route);
    }

    public function destroy(Request $request, BusRoute $route): JsonResponse
    {
        abort_unless($request->user()->isAdmin(), 403);
        $route->update(['is_active' => false]);

        return response()->json(['message' => 'Route désactivée.']);
    }
}
