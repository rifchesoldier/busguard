<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Student extends Model
{
    protected $fillable = [
        'first_name', 'last_name', 'school_id', 'class_id', 'class_name',
        'parent_id', 'assigned_bus_id', 'assigned_stop_id',
        'current_status', 'photo_url', 'is_active',
    ];

    public function school(): BelongsTo
    {
        return $this->belongsTo(School::class);
    }

    public function schoolClass(): BelongsTo
    {
        return $this->belongsTo(SchoolClass::class, 'class_id');
    }

    public function parent(): BelongsTo
    {
        return $this->belongsTo(User::class, 'parent_id');
    }

    public function bus(): BelongsTo
    {
        return $this->belongsTo(Bus::class, 'assigned_bus_id');
    }

    public function stop(): BelongsTo
    {
        return $this->belongsTo(Stop::class, 'assigned_stop_id');
    }

    public function attendanceLogs(): HasMany
    {
        return $this->hasMany(AttendanceLog::class);
    }

    public function getFullNameAttribute(): string
    {
        return "{$this->first_name} {$this->last_name}";
    }
}
