<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('schools', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('city')->default('Dakar');
            $table->string('address')->nullable();
            $table->decimal('lat', 10, 7)->nullable();
            $table->decimal('lng', 10, 7)->nullable();
            $table->json('available_classes')->nullable();
            $table->foreignId('admin_id')->nullable()->constrained('users')->nullOnDelete();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        Schema::table('users', function (Blueprint $table) {
            $table->foreign('school_id')->references('id')->on('schools')->nullOnDelete();
        });

        Schema::create('school_classes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('school_id')->constrained()->cascadeOnDelete();
            $table->string('name');
            $table->string('level')->nullable();
            $table->timestamps();
        });

        Schema::create('buses', function (Blueprint $table) {
            $table->id();
            $table->foreignId('school_id')->constrained()->cascadeOnDelete();
            $table->string('matricule')->unique();
            $table->string('model')->nullable();
            $table->unsignedSmallInteger('capacity')->default(40);
            $table->foreignId('driver_id')->nullable()->constrained('users')->nullOnDelete();
            $table->enum('status', ['idle', 'en_route', 'arrived', 'signal_perdu'])->default('idle');
            $table->decimal('last_lat', 10, 7)->nullable();
            $table->decimal('last_lng', 10, 7)->nullable();
            $table->timestamp('last_position_at')->nullable();
            $table->string('traffic_alert')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        Schema::create('bus_driver', function (Blueprint $table) {
            $table->id();
            $table->foreignId('bus_id')->constrained()->cascadeOnDelete();
            $table->foreignId('driver_id')->constrained('users')->cascadeOnDelete();
            $table->timestamps();
            $table->unique(['bus_id', 'driver_id']);
        });

        Schema::create('bus_routes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('bus_id')->constrained()->cascadeOnDelete();
            $table->foreignId('school_id')->constrained()->cascadeOnDelete();
            $table->string('name');
            $table->enum('direction', ['matin', 'soir']);
            $table->time('scheduled_start')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        Schema::create('stops', function (Blueprint $table) {
            $table->id();
            $table->foreignId('route_id')->constrained('bus_routes')->cascadeOnDelete();
            $table->string('name');
            $table->unsignedSmallInteger('order');
            $table->decimal('lat', 10, 7);
            $table->decimal('lng', 10, 7);
            $table->timestamps();
        });

        Schema::create('students', function (Blueprint $table) {
            $table->id();
            $table->string('first_name');
            $table->string('last_name');
            $table->foreignId('school_id')->constrained()->cascadeOnDelete();
            $table->foreignId('class_id')->nullable()->constrained('school_classes')->nullOnDelete();
            $table->string('class_name')->nullable();
            $table->foreignId('parent_id')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('assigned_bus_id')->nullable()->constrained('buses')->nullOnDelete();
            $table->foreignId('assigned_stop_id')->nullable()->constrained('stops')->nullOnDelete();
            $table->enum('current_status', ['en_attente', 'a_bord', 'arrive', 'absent'])->default('en_attente');
            $table->string('photo_url')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        Schema::create('attendance_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('student_id')->constrained()->cascadeOnDelete();
            $table->foreignId('bus_id')->constrained()->cascadeOnDelete();
            $table->foreignId('stop_id')->nullable()->constrained()->nullOnDelete();
            $table->date('date');
            $table->enum('status', ['present', 'absent', 'anomalie']);
            $table->foreignId('recorded_by_driver_id')->constrained('users')->cascadeOnDelete();
            $table->text('notes')->nullable();
            $table->timestamp('recorded_at');
            $table->timestamps();
            $table->index(['date', 'student_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('attendance_logs');
        Schema::dropIfExists('students');
        Schema::dropIfExists('stops');
        Schema::dropIfExists('bus_routes');
        Schema::dropIfExists('bus_driver');
        Schema::dropIfExists('buses');
        Schema::dropIfExists('school_classes');
        Schema::table('users', function (Blueprint $table) {
            $table->dropForeign(['school_id']);
        });
        Schema::dropIfExists('schools');
    }
};
