<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Password;

class UserController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        abort_unless($request->user()->isAdmin(), 403);

        $query = User::query();

        if ($request->role) {
            $query->where('role', $request->role);
        }

        if ($request->user()->role === 'admin') {
            $query->where('school_id', $request->user()->school_id);
        }

        return response()->json($query->get());
    }

    public function store(Request $request): JsonResponse
    {
        abort_unless($request->user()->isAdmin(), 403);

        $data = $request->validate([
            'name' => 'required|string',
            'email' => 'required|email|unique:users,email',
            'phone' => 'nullable|string',
            'password' => ['required', Password::defaults()],
            'role' => 'required|in:driver,admin,parent',
            'school_id' => 'nullable|exists:schools,id',
        ]);

        $user = User::create([
            ...$data,
            'school_id' => $data['school_id'] ?? $request->user()->school_id,
        ]);

        return response()->json($user, 201);
    }

    public function show(User $user): JsonResponse
    {
        return response()->json($user->load(['school', 'drivenBuses']));
    }

    public function update(Request $request, User $user): JsonResponse
    {
        abort_unless($request->user()->isAdmin(), 403);

        $data = $request->validate([
            'name' => 'sometimes|string',
            'phone' => 'nullable|string',
            'is_active' => 'sometimes|boolean',
            'password' => ['sometimes', Password::defaults()],
        ]);

        if (isset($data['password'])) {
            $data['password'] = Hash::make($data['password']);
        }

        $user->update($data);

        return response()->json($user);
    }

    public function destroy(Request $request, User $user): JsonResponse
    {
        abort_unless($request->user()->isAdmin(), 403);
        $user->update(['is_active' => false]);

        return response()->json(['message' => 'Utilisateur désactivé.']);
    }
}
