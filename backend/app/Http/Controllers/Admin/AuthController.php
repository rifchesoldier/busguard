<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\View\View;

class AuthController extends Controller
{
    public function showLogin(): View
    {
        return view('admin.auth.login');
    }

    public function login(Request $request): RedirectResponse
    {
        $credentials = $request->validate([
            'email' => 'required|email',
            'password' => 'required',
            'two_factor_code' => 'nullable|string',
        ]);

        if (! Auth::attempt(['email' => $credentials['email'], 'password' => $credentials['password']], $request->boolean('remember'))) {
            return back()->withErrors(['email' => 'Identifiants incorrects.'])->onlyInput('email');
        }

        $user = Auth::user();

        if (! $user->isAdmin() || ! $user->is_active) {
            Auth::logout();

            return back()->withErrors(['email' => 'Accès réservé aux administrateurs.']);
        }

        if ($user->two_factor_enabled) {
            $code = $credentials['two_factor_code'] ?? '';
            $expected = substr(hash('sha256', $user->two_factor_secret.config('app.key')), 0, 6);

            if ($code !== $expected) {
                Auth::logout();

                return back()->withErrors(['two_factor_code' => 'Code 2FA invalide.'])->onlyInput('email');
            }
        }

        $request->session()->regenerate();

        return redirect()->route('admin.dashboard');
    }

    public function logout(Request $request): RedirectResponse
    {
        Auth::logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect()->route('admin.login');
    }
}
