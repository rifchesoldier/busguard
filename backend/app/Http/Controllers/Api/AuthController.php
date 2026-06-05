<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Password;

class AuthController extends Controller
{
    public function registerParent(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            'phone' => 'nullable|string|max:20',
            'password' => ['required', Password::defaults()],
            'privacy_consent' => 'accepted',
            'firebase_uid' => 'nullable|string|unique:users,firebase_uid',
        ]);

        $user = User::create([
            'name' => $data['name'],
            'email' => $data['email'],
            'phone' => $data['phone'] ?? null,
            'password' => $data['password'],
            'role' => 'parent',
            'firebase_uid' => $data['firebase_uid'] ?? null,
            'privacy_consent' => true,
        ]);

        $token = $user->createToken('mobile')->plainTextToken;

        return response()->json([
            'user' => $user,
            'token' => $token,
        ], 201);
    }

    public function login(Request $request): JsonResponse
    {
        $data = $request->validate([
            'email' => 'required|email',
            'password' => 'required',
        ]);

        $user = User::where('email', $data['email'])->first();

        if (! $user || ! Hash::check($data['password'], $user->password) || ! $user->is_active) {
            return response()->json(['message' => 'Identifiants invalides.'], 401);
        }

        $token = $user->createToken('mobile')->plainTextToken;

        return response()->json(['user' => $user, 'token' => $token]);
    }

    public function firebaseSync(Request $request): JsonResponse
    {
        $data = $request->validate([
            'firebase_uid' => 'required|string',
            'email' => 'required|email',
            'name' => 'required|string',
            'role' => 'in:parent,driver',
        ]);

        $user = User::updateOrCreate(
            ['firebase_uid' => $data['firebase_uid']],
            [
                'email' => $data['email'],
                'name' => $data['name'],
                'role' => $data['role'] ?? 'parent',
                'password' => Hash::make(str()->random(32)),
            ]
        );

        $token = $user->createToken('firebase')->plainTextToken;

        return response()->json(['user' => $user, 'token' => $token]);
    }

    public function me(Request $request): JsonResponse
    {
        return response()->json($request->user()->load(['school', 'children.bus', 'drivenBuses']));
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(['message' => 'Déconnecté.']);
    }

    public function updateFcmToken(Request $request): JsonResponse
    {
        $data = $request->validate(['fcm_token' => 'required|string']);
        $request->user()->update(['fcm_token' => $data['fcm_token']]);

        return response()->json(['message' => 'Token FCM mis à jour.']);
    }

    public function deleteAccount(Request $request): JsonResponse
    {
        $user = $request->user();
        $user->children()->update(['parent_id' => null]);
        $user->tokens()->delete();
        $user->delete();

        return response()->json(['message' => 'Compte supprimé conformément au droit à l\'oubli.']);
    }
}
