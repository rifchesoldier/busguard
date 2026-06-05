@extends('admin.layouts.app')
@section('title', 'Bus')
@section('content')
<div class="mb-8"><h1 class="font-display text-3xl font-bold">Bus</h1></div>
<div class="grid lg:grid-cols-3 gap-6">
    <div class="glass rounded-3xl p-6">
        <h2 class="font-display font-semibold mb-4">Ajouter un bus</h2>
        <form method="POST" action="{{ route('admin.buses.store') }}" class="space-y-3">
            @csrf
            <select name="school_id" required class="w-full px-4 py-3 rounded-xl border border-dusk/10">
                @foreach($schools as $s)<option value="{{ $s->id }}">{{ $s->name }}</option>@endforeach
            </select>
            <input name="matricule" placeholder="Immatriculation" required class="w-full px-4 py-3 rounded-xl border border-dusk/10">
            <input name="model" placeholder="Modèle" class="w-full px-4 py-3 rounded-xl border border-dusk/10">
            <input name="capacity" type="number" value="40" placeholder="Capacité" class="w-full px-4 py-3 rounded-xl border border-dusk/10">
            <select name="driver_id" class="w-full px-4 py-3 rounded-xl border border-dusk/10">
                <option value="">— Chauffeur —</option>
                @foreach($drivers as $d)<option value="{{ $d->id }}">{{ $d->name }}</option>@endforeach
            </select>
            <button class="w-full py-3 rounded-xl bg-gradient-to-r from-terracotta to-gold text-white font-semibold">Ajouter</button>
        </form>
    </div>
    <div class="lg:col-span-2 grid gap-4">
        @foreach($buses as $bus)
        <div class="glass rounded-2xl p-5 flex items-center justify-between">
            <div class="flex items-center gap-4">
                <div class="w-12 h-12 rounded-2xl bg-gradient-to-br from-ink to-dusk flex items-center justify-center text-white text-xl">🚌</div>
                <div>
                    <h3 class="font-display font-bold text-lg">{{ $bus->matricule }}</h3>
                    <p class="text-sm text-dusk/60">{{ $bus->school->name }} · {{ $bus->driver->name ?? 'Sans chauffeur' }}</p>
                </div>
            </div>
            <span class="px-3 py-1.5 rounded-full text-xs font-medium
                @if($bus->status === 'en_route') bg-sage/20 text-sage
                @elseif($bus->status === 'signal_perdu') bg-red-100 text-red-600
                @else bg-dusk/10 text-dusk @endif">
                {{ ucfirst(str_replace('_', ' ', $bus->status)) }}
            </span>
        </div>
        @endforeach
    </div>
</div>
@endsection
