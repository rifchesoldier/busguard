@extends('admin.layouts.app')
@section('title', 'Itinéraires')
@section('content')
<div class="mb-8"><h1 class="font-display text-3xl font-bold">Itinéraires & Arrêts</h1></div>
<div class="grid lg:grid-cols-3 gap-6">
    <div class="glass rounded-3xl p-6">
        <h2 class="font-display font-semibold mb-4">Nouvel itinéraire</h2>
        <form method="POST" action="{{ route('admin.routes.store') }}" class="space-y-3" id="routeForm">
            @csrf
            <select name="school_id" required class="w-full px-4 py-3 rounded-xl border border-dusk/10">
                @foreach($schools as $s)<option value="{{ $s->id }}">{{ $s->name }}</option>@endforeach
            </select>
            <select name="bus_id" required class="w-full px-4 py-3 rounded-xl border border-dusk/10">
                @foreach($buses as $b)<option value="{{ $b->id }}">{{ $b->matricule }}</option>@endforeach
            </select>
            <input name="name" placeholder="Nom de la route" required class="w-full px-4 py-3 rounded-xl border border-dusk/10">
            <select name="direction" class="w-full px-4 py-3 rounded-xl border border-dusk/10">
                <option value="matin">Matin (aller école)</option>
                <option value="soir">Soir (retour)</option>
            </select>
            <div id="stops" class="space-y-2">
                <div class="stop-row grid grid-cols-3 gap-2">
                    <input name="stop_names[]" placeholder="Arrêt" required class="col-span-1 px-3 py-2 rounded-lg border text-sm">
                    <input name="stop_lats[]" placeholder="Lat" value="14.7167" required class="px-3 py-2 rounded-lg border text-sm">
                    <input name="stop_lngs[]" placeholder="Lng" value="-17.4677" required class="px-3 py-2 rounded-lg border text-sm">
                </div>
            </div>
            <button type="button" onclick="addStop()" class="text-sm text-terracotta font-medium">+ Ajouter un arrêt</button>
            <button class="w-full py-3 rounded-xl bg-gradient-to-r from-terracotta to-gold text-white font-semibold">Créer</button>
        </form>
    </div>
    <div class="lg:col-span-2 space-y-4">
        @foreach($routes as $route)
        <div class="glass rounded-2xl p-5">
            <div class="flex justify-between items-start mb-3">
                <div>
                    <h3 class="font-display font-bold">{{ $route->name }}</h3>
                    <p class="text-sm text-dusk/60">Bus {{ $route->bus->matricule }} · {{ ucfirst($route->direction) }}</p>
                </div>
                <span class="px-3 py-1 rounded-full bg-gold/20 text-gold text-xs font-medium">{{ $route->stops->count() }} arrêts</span>
            </div>
            <div class="flex flex-wrap gap-2">
                @foreach($route->stops as $stop)
                <span class="px-3 py-1.5 rounded-full bg-white/80 text-xs border border-dusk/10">{{ $stop->order }}. {{ $stop->name }}</span>
                @endforeach
            </div>
        </div>
        @endforeach
    </div>
</div>
<script>
function addStop() {
    const div = document.createElement('div');
    div.className = 'stop-row grid grid-cols-3 gap-2';
    div.innerHTML = `<input name="stop_names[]" placeholder="Arrêt" required class="col-span-1 px-3 py-2 rounded-lg border text-sm">
        <input name="stop_lats[]" placeholder="Lat" required class="px-3 py-2 rounded-lg border text-sm">
        <input name="stop_lngs[]" placeholder="Lng" required class="px-3 py-2 rounded-lg border text-sm">`;
    document.getElementById('stops').appendChild(div);
}
</script>
@endsection
