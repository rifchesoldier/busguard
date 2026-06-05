<?php

namespace Database\Seeders;

use App\Models\AttendanceLog;
use App\Models\Bus;
use App\Models\BusRoute;
use App\Models\School;
use App\Models\SchoolClass;
use App\Models\Stop;
use App\Models\Student;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class BusGuardSeeder extends Seeder
{
    public function run(): void
    {
        $superAdmin = User::create([
            'name' => 'Super Admin BusGuard',
            'email' => 'admin@busguard.sn',
            'password' => Hash::make('BusGuard2024!'),
            'role' => 'superadmin',
            'two_factor_enabled' => false,
            'privacy_consent' => true,
        ]);

        $schoolAdmin = User::create([
            'name' => 'Admin École Les Almadies',
            'email' => 'ecole@busguard.sn',
            'password' => Hash::make('BusGuard2024!'),
            'role' => 'admin',
            'two_factor_enabled' => false,
            'privacy_consent' => true,
        ]);

        $school = School::create([
            'name' => 'École Internationale Les Almadies',
            'city' => 'Dakar',
            'address' => 'Route des Almadies, Dakar',
            'lat' => 14.7392,
            'lng' => -17.5123,
            'admin_id' => $schoolAdmin->id,
            'available_classes' => ['CP', 'CE1', 'CE2', 'CM1', 'CM2'],
        ]);

        $schoolAdmin->update(['school_id' => $school->id]);

        SchoolClass::create(['school_id' => $school->id, 'name' => 'CM2 A', 'level' => 'CM2']);

        $driver = User::create([
            'name' => 'Moussa Diop',
            'email' => 'chauffeur@busguard.sn',
            'phone' => '+221771234567',
            'password' => Hash::make('BusGuard2024!'),
            'role' => 'driver',
            'school_id' => $school->id,
            'privacy_consent' => true,
        ]);

        $parent = User::create([
            'name' => 'Fatou Ndiaye',
            'email' => 'parent@busguard.sn',
            'phone' => '+221771234568',
            'password' => Hash::make('BusGuard2024!'),
            'role' => 'parent',
            'privacy_consent' => true,
        ]);

        $bus = Bus::create([
            'school_id' => $school->id,
            'matricule' => 'DK-1234-AB',
            'model' => 'Toyota Coaster',
            'capacity' => 35,
            'driver_id' => $driver->id,
            'status' => 'idle',
            'last_lat' => 14.7167,
            'last_lng' => -17.4677,
            'last_position_at' => now(),
        ]);

        $bus->drivers()->attach($driver->id);

        $route = BusRoute::create([
            'bus_id' => $bus->id,
            'school_id' => $school->id,
            'name' => 'Ligne Almadies — Plateau',
            'direction' => 'matin',
            'scheduled_start' => '07:00',
        ]);

        $stops = [
            ['name' => 'Arrêt VDN Mermoz', 'order' => 1, 'lat' => 14.7100, 'lng' => -17.4700],
            ['name' => 'Arrêt Sicap Liberté', 'order' => 2, 'lat' => 14.7200, 'lng' => -17.4600],
            ['name' => 'Arrêt Plateau', 'order' => 3, 'lat' => 14.7300, 'lng' => -17.4500],
        ];

        $firstStop = null;
        foreach ($stops as $stopData) {
            $stop = Stop::create([...$stopData, 'route_id' => $route->id]);
            $firstStop ??= $stop;
        }

        $student = Student::create([
            'first_name' => 'Aminata',
            'last_name' => 'Ndiaye',
            'school_id' => $school->id,
            'class_name' => 'CM2 A',
            'parent_id' => $parent->id,
            'assigned_bus_id' => $bus->id,
            'assigned_stop_id' => $firstStop->id,
            'current_status' => 'en_attente',
        ]);

        AttendanceLog::create([
            'student_id' => $student->id,
            'bus_id' => $bus->id,
            'stop_id' => $firstStop->id,
            'date' => now()->subDay()->toDateString(),
            'status' => 'present',
            'recorded_by_driver_id' => $driver->id,
            'recorded_at' => now()->subDay()->setTime(7, 15),
        ]);
    }
}
