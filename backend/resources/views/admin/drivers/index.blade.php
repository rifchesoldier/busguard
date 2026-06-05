@extends('admin.layouts.app')
@section('title', 'Chauffeurs')
@section('content')
<div class="mb-8"><h1 class="font-display text-3xl font-bold">Chauffeurs</h1></div>
<div class="grid lg:grid-cols-3 gap-6">
    <div class="glass rounded-3xl p-6">
        <h2 class="font-display font-semibold mb-4">Créer un compte chauffeur</h2>
        <form method="POST" action="{{ route('admin.drivers.store') }}" class="space-y-3">
            @csrf
            <input name="name" placeholder="Nom complet" required class="w-full px-4 py-3 rounded-xl border border-dusk/10">
            <input name="email" type="email" placeholder="Email" required class="w-full px-4 py-3 rounded-xl border border-dusk/10">
            <input name="phone" placeholder="Téléphone" class="w-full px-4 py-3 rounded-xl border border-dusk/10">
            <select name="school_id" required class="w-full px-4 py-3 rounded-xl border border-dusk/10">
                @foreach($schools as $s)<option value="{{ $s->id }}">{{ $s->name }}</option>@endforeach
            </select>
            <input name="password" type="password" placeholder="Mot de passe temporaire" required class="w-full px-4 py-3 rounded-xl border border-dusk/10">
            <button class="w-full py-3 rounded-xl bg-gradient-to-r from-terracotta to-gold text-white font-semibold">Créer le compte</button>
        </form>
    </div>
    <div class="lg:col-span-2 grid gap-4">
        @foreach($drivers as $driver)
        <div class="glass rounded-2xl p-5 flex items-center gap-4">
            <div class="w-14 h-14 rounded-2xl bg-gradient-to-br from-sage to-ink flex items-center justify-center text-white text-2xl">👨‍✈️</div>
            <div class="flex-1">
                <h3 class="font-display font-bold">{{ $driver->name }}</h3>
                <p class="text-sm text-dusk/60">{{ $driver->email }} · {{ $driver->phone }}</p>
                <p class="text-xs text-dusk/50 mt-1">Bus: {{ $driver->drivenBuses->pluck('matricule')->join(', ') ?: 'Aucun' }}</p>
            </div>
        </div>
        @endforeach
    </div>
</div>
@endsection
