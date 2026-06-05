<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Bus extends Model
{
    protected $fillable = [
        'school_id', 'matricule', 'model', 'capacity', 'driver_id',
        'status', 'last_lat', 'last_lng', 'last_position_at',
        'traffic_alert', 'is_active',
    ];

    protected function casts(): array
    {
        return [
            'last_lat' => 'decimal:7',
            'last_lng' => 'decimal:7',
            'last_position_at' => 'datetime',
            'is_active' => 'boolean',
        ];
    }

    public function school(): BelongsTo
    {
        return $this->belongsTo(School::class);
    }

    public function driver(): BelongsTo
    {
        return $this->belongsTo(User::class, 'driver_id');
    }

    public function drivers(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'bus_driver', 'bus_id', 'driver_id');
    }

    public function routes(): HasMany
    {
        return $this->hasMany(BusRoute::class, 'bus_id');
    }

    public function students(): HasMany
    {
        return $this->hasMany(Student::class, 'assigned_bus_id');
    }
}
