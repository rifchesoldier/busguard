<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AttendanceLog extends Model
{
    protected $fillable = [
        'student_id', 'bus_id', 'stop_id', 'date', 'status',
        'recorded_by_driver_id', 'notes', 'recorded_at',
    ];

    protected function casts(): array
    {
        return [
            'date' => 'date',
            'recorded_at' => 'datetime',
        ];
    }

    public function student(): BelongsTo
    {
        return $this->belongsTo(Student::class);
    }

    public function bus(): BelongsTo
    {
        return $this->belongsTo(Bus::class);
    }

    public function stop(): BelongsTo
    {
        return $this->belongsTo(Stop::class);
    }

    public function driver(): BelongsTo
    {
        return $this->belongsTo(User::class, 'recorded_by_driver_id');
    }
}
