<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Stop extends Model
{
    protected $fillable = ['route_id', 'name', 'order', 'lat', 'lng'];

    protected function casts(): array
    {
        return [
            'lat' => 'decimal:7',
            'lng' => 'decimal:7',
        ];
    }

    public function route(): BelongsTo
    {
        return $this->belongsTo(BusRoute::class, 'route_id');
    }

    public function students(): HasMany
    {
        return $this->hasMany(Student::class, 'assigned_stop_id');
    }
}
