<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Bus;
use App\Models\Student;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class NotificationController extends Controller
{
    public function trafficAlert(Request $request): JsonResponse
    {
        abort_unless($request->user()->role === 'driver', 403);

        $data = $request->validate([
            'bus_id' => 'required|exists:buses,id',
            'type' => 'required|in:embouteillage,accident,panne',
            'resolved' => 'sometimes|boolean',
        ]);

        $bus = Bus::findOrFail($data['bus_id']);
        $bus->update([
            'traffic_alert' => ($data['resolved'] ?? false) ? null : $data['type'],
        ]);

        $parents = Student::where('assigned_bus_id', $bus->id)
            ->with('parent')
            ->get()
            ->pluck('parent')
            ->filter()
            ->unique('id');

        $message = ($data['resolved'] ?? false)
            ? "Le trafic est redevenu normal sur le Bus {$bus->matricule}."
            : "Alerte : {$data['type']} sur le trajet du Bus {$bus->matricule}. Retard possible.";

        $this->sendFcmToUsers($parents, 'Alerte trafic', $message, [
            'type' => 'traffic',
            'bus_id' => (string) $bus->id,
        ]);

        return response()->json(['message' => 'Notification envoyée.', 'traffic_alert' => $bus->traffic_alert]);
    }

    public function attendanceAlert(Request $request): JsonResponse
    {
        abort_unless(in_array($request->user()->role, ['driver', 'admin'], true), 403);

        $data = $request->validate([
            'student_id' => 'required|exists:students,id',
            'type' => 'required|in:absent,arrived,anomalie',
            'wrong_bus' => 'nullable|string',
        ]);

        $student = Student::with('parent', 'bus')->findOrFail($data['student_id']);
        $parent = $student->parent;

        if (! $parent?->fcm_token) {
            return response()->json(['message' => 'Parent sans token FCM.']);
        }

        $messages = [
            'absent' => "Votre enfant {$student->first_name} a été signalé absent à l'arrêt ce matin.",
            'arrived' => "Votre enfant {$student->first_name} est arrivé à l'école.",
            'anomalie' => "Votre enfant {$student->first_name} est dans le Bus {$data['wrong_bus']} au lieu du Bus {$student->bus?->matricule}.",
        ];

        $this->sendFcmToUsers(collect([$parent]), 'BusGuard', $messages[$data['type']], [
            'type' => $data['type'],
            'student_id' => (string) $student->id,
        ]);

        return response()->json(['message' => 'Notification envoyée au parent.']);
    }

    private function sendFcmToUsers($users, string $title, string $body, array $data = []): void
    {
        $serverKey = config('services.fcm.server_key');

        if (! $serverKey) {
            Log::info("FCM [simulation] {$title}: {$body}", $data);

            return;
        }

        foreach ($users as $user) {
            if (! $user?->fcm_token) {
                continue;
            }

            Http::withHeaders([
                'Authorization' => "key={$serverKey}",
                'Content-Type' => 'application/json',
            ])->post('https://fcm.googleapis.com/fcm/send', [
                'to' => $user->fcm_token,
                'notification' => ['title' => $title, 'body' => $body],
                'data' => $data,
            ]);
        }
    }
}
