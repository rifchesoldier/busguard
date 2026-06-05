<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class School extends Model
{
    protected $fillable = [
        'name', 'city', 'address', 'lat', 'lng',
        'available_classes', 'admin_id', 'is_active',
    ];

    protected function casts(): array
    {
        return [
            'available_classes' => 'array',
            'is_active' => 'boolean',
            'lat' => 'decimal:7',
            'lng' => 'decimal:7',
        ];
    }

    public function admin(): BelongsTo
    {
        return $this->belongsTo(User::class, 'admin_id');
    }

    public function classes(): HasMany
    {
        return $this->hasMany(SchoolClass::class, 'school_id');
    }

    public function buses(): HasMany
    {
        return $this->hasMany(Bus::class);
    }

    public function students(): HasMany
    {
        return $this->hasMany(Student::class);
    }

    public function routes(): HasMany
    {
        return $this->hasMany(BusRoute::class, 'school_id');
    }
}
