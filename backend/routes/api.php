<?php

use App\Http\Controllers\Api\AttendanceController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\BusController;
use App\Http\Controllers\Api\EtaController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\RouteController;
use App\Http\Controllers\Api\SchoolController;
use App\Http\Controllers\Api\StatsController;
use App\Http\Controllers\Api\StudentController;
use App\Http\Controllers\Api\UserController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    Route::post('/auth/register-parent', [AuthController::class, 'registerParent']);
    Route::post('/auth/login', [AuthController::class, 'login']);
    Route::post('/auth/firebase-sync', [AuthController::class, 'firebaseSync']);

    Route::middleware('auth:sanctum')->group(function () {
        Route::post('/auth/logout', [AuthController::class, 'logout']);
        Route::get('/auth/me', [AuthController::class, 'me']);
        Route::put('/auth/fcm-token', [AuthController::class, 'updateFcmToken']);
        Route::delete('/auth/account', [AuthController::class, 'deleteAccount']);

        Route::apiResource('schools', SchoolController::class);
        Route::apiResource('buses', BusController::class);
        Route::apiResource('routes', RouteController::class);
        Route::apiResource('students', StudentController::class);
        Route::apiResource('users', UserController::class);

        Route::get('/students/parent/mine', [StudentController::class, 'myChildren']);
        Route::post('/students/{student}/assign-bus', [StudentController::class, 'assignBus']);

        Route::get('/attendance', [AttendanceController::class, 'index']);
        Route::post('/attendance', [AttendanceController::class, 'store']);
        Route::get('/attendance/export', [AttendanceController::class, 'export']);
        Route::get('/attendance/history/{student}', [AttendanceController::class, 'studentHistory']);

        Route::get('/eta/{bus}', [EtaController::class, 'calculate']);
        Route::get('/directions/route/points', [EtaController::class, 'route']); // AVANT {bus}
        Route::get('/directions/{bus}', [EtaController::class, 'directions']);
        Route::get('/stats', [StatsController::class, 'index']);
        Route::post('/notifications/traffic', [NotificationController::class, 'trafficAlert']);
        Route::post('/notifications/attendance', [NotificationController::class, 'attendanceAlert']);
    });
});
