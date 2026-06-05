<?php

use App\Http\Controllers\Admin\AuthController;
use App\Http\Controllers\Admin\DashboardController;
use App\Http\Controllers\Admin\ResourceController;
use Illuminate\Support\Facades\Route;

Route::get('/', fn () => redirect()->route('admin.login'));

Route::prefix('admin')->name('admin.')->group(function () {
    Route::middleware('guest')->group(function () {
        Route::get('/login', [AuthController::class, 'showLogin'])->name('login');
        Route::post('/login', [AuthController::class, 'login']);
    });

    Route::middleware(['auth', 'role:admin,superadmin'])->group(function () {
        Route::post('/logout', [AuthController::class, 'logout'])->name('logout');
        Route::get('/dashboard', [DashboardController::class, 'index'])->name('dashboard');

        Route::get('/schools', [ResourceController::class, 'schools'])->name('schools');
        Route::post('/schools', [ResourceController::class, 'storeSchool'])->name('schools.store');

        Route::get('/buses', [ResourceController::class, 'buses'])->name('buses');
        Route::post('/buses', [ResourceController::class, 'storeBus'])->name('buses.store');

        Route::get('/routes', [ResourceController::class, 'routes'])->name('routes');
        Route::post('/routes', [ResourceController::class, 'storeRoute'])->name('routes.store');

        Route::get('/students', [ResourceController::class, 'students'])->name('students');
        Route::post('/students', [ResourceController::class, 'storeStudent'])->name('students.store');

        Route::get('/drivers', [ResourceController::class, 'drivers'])->name('drivers');
        Route::post('/drivers', [ResourceController::class, 'storeDriver'])->name('drivers.store');

        Route::get('/attendance', [ResourceController::class, 'attendance'])->name('attendance');
    });
});
