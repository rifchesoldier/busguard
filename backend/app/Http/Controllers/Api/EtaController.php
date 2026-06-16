<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Bus;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Http;

class EtaController extends Controller
{
    public function route(): JsonResponse
    {
        $lat1 = request('origin_lat');
        $lng1 = request('origin_lng');
        $lat2 = request('dest_lat');
        $lng2 = request('dest_lng');

        if (! $lat1 || ! $lng1 || ! $lat2 || ! $lng2) {
            return response()->json(['error' => 'Coordonnées manquantes.'], 422);
        }

        $apiKey = config('services.google_maps.key');
        if (! $apiKey) {
            return response()->json(['error' => 'Clé API non configurée.'], 500);
        }

        $response = Http::get('https://maps.googleapis.com/maps/api/directions/json', [
            'origin'      => "{$lat1},{$lng1}",
            'destination' => "{$lat2},{$lng2}",
            'mode'        => 'driving',
            'language'    => 'fr',
            'key'         => $apiKey,
        ]);

        $data = $response->json();

        if (($data['status'] ?? '') !== 'OK') {
            return response()->json(['error' => $data['status'] ?? 'Directions non disponibles.'], 422);
        }

        $overviewPolyline = $data['routes'][0]['overview_polyline']['points'] ?? null;

        return response()->json([
            'polyline' => $overviewPolyline,
            'summary'  => $data['routes'][0]['summary'] ?? null,
        ]);
    }

    public function directions(Bus $bus): JsonResponse
    {
        if (! $bus->last_lat || ! $bus->last_lng) {
            return response()->json(['error' => 'Position GPS indisponible.'], 422);
        }

        $school = $bus->school;
        if (! $school?->lat || ! $school?->lng) {
            return response()->json(['error' => 'Destination non configurée.'], 422);
        }

        $apiKey = config('services.google_maps.key');

        if (! $apiKey) {
            return response()->json(['error' => 'Clé API non configurée.'], 500);
        }

        $response = Http::get('https://maps.googleapis.com/maps/api/directions/json', [
            'origin'      => "{$bus->last_lat},{$bus->last_lng}",
            'destination' => "{$school->lat},{$school->lng}",
            'mode'        => 'driving',
            'language'    => 'fr',
            'key'         => $apiKey,
        ]);

        $data = $response->json();

        if (($data['status'] ?? '') !== 'OK') {
            return response()->json(['error' => $data['status'] ?? 'Directions non disponibles.'], 422);
        }

        // On retourne uniquement la polyline encodée (légère)
        $overviewPolyline = $data['routes'][0]['overview_polyline']['points'] ?? null;

        return response()->json([
            'polyline' => $overviewPolyline,
            'summary'  => $data['routes'][0]['summary'] ?? null,
        ]);
    }

    public function calculate(Bus $bus): JsonResponse
    {
        if (! $bus->last_lat || ! $bus->last_lng) {
            return response()->json(['eta_minutes' => null, 'message' => 'Position GPS indisponible.']);
        }

        $school = $bus->school;
        if (! $school?->lat || ! $school?->lng) {
            return response()->json(['eta_minutes' => null, 'message' => 'Destination non configurée.']);
        }

        $apiKey = config('services.google_maps.key');

        if (! $apiKey) {
            $distance = $this->haversine(
                (float) $bus->last_lat, (float) $bus->last_lng,
                (float) $school->lat, (float) $school->lng
            );
            $etaMinutes = max(1, (int) round($distance / 0.5));

            return response()->json([
                'eta_minutes' => $etaMinutes,
                'source' => 'estimated',
                'distance_km' => round($distance, 2),
            ]);
        }

        $response = Http::get('https://maps.googleapis.com/maps/api/distancematrix/json', [
            'origins' => "{$bus->last_lat},{$bus->last_lng}",
            'destinations' => "{$school->lat},{$school->lng}",
            'departure_time' => 'now',
            'traffic_model' => 'best_guess',
            'key' => $apiKey,
        ]);

        $element = $response->json('rows.0.elements.0');

        if (($element['status'] ?? '') !== 'OK') {
            return response()->json(['eta_minutes' => null, 'message' => 'ETA non disponible.']);
        }

        $seconds = $element['duration_in_traffic']['value'] ?? $element['duration']['value'];

        return response()->json([
            'eta_minutes' => (int) ceil($seconds / 60),
            'source' => 'google_maps',
            'distance_text' => $element['distance']['text'] ?? null,
        ]);
    }

    private function haversine(float $lat1, float $lng1, float $lat2, float $lng2): float
    {
        $r = 6371;
        $dLat = deg2rad($lat2 - $lat1);
        $dLng = deg2rad($lng2 - $lng1);
        $a = sin($dLat / 2) ** 2 + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * sin($dLng / 2) ** 2;

        return $r * 2 * atan2(sqrt($a), sqrt(1 - $a));
    }
}
