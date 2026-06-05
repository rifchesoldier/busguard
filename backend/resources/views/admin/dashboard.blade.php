@extends('admin.layouts.app')

@section('title', 'Tableau de bord — BusGuard')

@section('content')
<div class="mb-8">
    <h1 class="font-display text-3xl font-bold text-ink">Tableau de bord</h1>
    <p class="text-dusk/70 mt-1">Vue d'ensemble du réseau de transport scolaire</p>
</div>

<div class="grid grid-cols-2 lg:grid-cols-3 xl:grid-cols-6 gap-4 mb-8">
    @foreach([
        ['label' => 'Écoles', 'value' => $stats['schools'], 'icon' => '🏫', 'color' => 'terracotta'],
        ['label' => 'Bus', 'value' => $stats['buses'], 'icon' => '🚌', 'color' => 'gold'],
        ['label' => 'Élèves', 'value' => $stats['students'], 'icon' => '👧', 'color' => 'sage'],
        ['label' => 'Chauffeurs', 'value' => $stats['drivers'], 'icon' => '👨‍✈️', 'color' => 'dusk'],
        ['label' => 'En route', 'value' => $stats['active_buses'], 'icon' => '📍', 'color' => 'terracotta'],
        ['label' => 'Présents aujourd\'hui', 'value' => $stats['today_presences'], 'icon' => '✅', 'color' => 'sage'],
    ] as $stat)
    <div class="stat-card rounded-2xl p-5 shadow-sm border border-white/80 hover:shadow-md transition">
        <div class="text-2xl mb-2">{{ $stat['icon'] }}</div>
        <div class="font-display text-3xl font-bold text-{{ $stat['color'] }}">{{ $stat['value'] }}</div>
        <div class="text-sm text-dusk/60 mt-1">{{ $stat['label'] }}</div>
    </div>
    @endforeach
</div>

<div class="grid lg:grid-cols-2 gap-6">
    <div class="glass rounded-3xl p-6 shadow-sm">
        <h2 class="font-display text-xl font-semibold mb-4">🚌 Bus en circulation</h2>
        @forelse($activeBuses as $bus)
        <div class="flex items-center justify-between py-3 border-b border-dusk/10 last:border-0">
            <div>
                <span class="font-semibold">{{ $bus->matricule }}</span>
                <span class="text-sm text-dusk/60 ml-2">{{ $bus->school->name ?? '' }}</span>
            </div>
            <span class="px-3 py-1 rounded-full text-xs font-medium {{ $bus->status === 'signal_perdu' ? 'bg-red-100 text-red-700' : 'bg-sage/20 text-sage' }}">
                {{ $bus->status === 'signal_perdu' ? 'Signal perdu' : 'En route' }}
            </span>
        </div>
        @empty
        <p class="text-dusk/50 py-8 text-center">Aucun bus en circulation actuellement</p>
        @endforelse
    </div>

    <div class="glass rounded-3xl p-6 shadow-sm">
        <h2 class="font-display text-xl font-semibold mb-4">📋 Dernières présences</h2>
        @forelse($recentLogs as $log)
        <div class="flex items-center justify-between py-3 border-b border-dusk/10 last:border-0">
            <div>
                <span class="font-medium">{{ $log->student->first_name }} {{ $log->student->last_name }}</span>
                <span class="text-xs text-dusk/50 block">{{ $log->recorded_at->format('d/m H:i') }}</span>
            </div>
            <span class="px-3 py-1 rounded-full text-xs font-medium {{ $log->status === 'present' ? 'bg-sage/20 text-sage' : ($log->status === 'absent' ? 'bg-red-100 text-red-600' : 'bg-gold/20 text-gold') }}">
                {{ ucfirst($log->status) }}
            </span>
        </div>
        @empty
        <p class="text-dusk/50 py-8 text-center">Aucune présence enregistrée</p>
        @endforelse
    </div>
</div>
@endsection
