<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class BusRoute extends Model
{
    protected $table = 'bus_routes';

    protected $fillable = [
        'bus_id', 'school_id', 'name', 'direction',
        'scheduled_start', 'is_active',
    ];

    protected function casts(): array
    {
        return [
            'scheduled_start' => 'datetime:H:i',
            'is_active' => 'boolean',
        ];
    }

    public function bus(): BelongsTo
    {
        return $this->belongsTo(Bus::class);
    }

    public function school(): BelongsTo
    {
        return $this->belongsTo(School::class);
    }

    public function stops(): HasMany
    {
        return $this->hasMany(Stop::class, 'route_id')->orderBy('order');
    }
}
