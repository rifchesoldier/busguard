@extends('admin.layouts.app')
@section('title', 'Écoles')
@section('content')
<div class="flex justify-between items-center mb-8">
    <div><h1 class="font-display text-3xl font-bold">Écoles</h1><p class="text-dusk/70">Gérer les établissements scolaires</p></div>
</div>
<div class="grid lg:grid-cols-3 gap-6">
    <div class="glass rounded-3xl p-6">
        <h2 class="font-display font-semibold mb-4">Nouvelle école</h2>
        <form method="POST" action="{{ route('admin.schools.store') }}" class="space-y-4">
            @csrf
            <input name="name" placeholder="Nom de l'école" required class="w-full px-4 py-3 rounded-xl border border-dusk/10">
            <input name="city" placeholder="Ville" value="Dakar" required class="w-full px-4 py-3 rounded-xl border border-dusk/10">
            <input name="address" placeholder="Adresse" class="w-full px-4 py-3 rounded-xl border border-dusk/10">
            <button class="w-full py-3 rounded-xl bg-gradient-to-r from-terracotta to-gold text-white font-semibold">Créer</button>
        </form>
    </div>
    <div class="lg:col-span-2 glass rounded-3xl p-6">
        <div class="space-y-3">
            @foreach($schools as $school)
            <div class="flex items-center justify-between p-4 rounded-2xl bg-white/60 border border-white">
                <div>
                    <h3 class="font-semibold">{{ $school->name }}</h3>
                    <p class="text-sm text-dusk/60">{{ $school->city }} — {{ $school->address }}</p>
                </div>
                <span class="px-3 py-1 rounded-full text-xs {{ $school->is_active ? 'bg-sage/20 text-sage' : 'bg-red-100 text-red-600' }}">{{ $school->is_active ? 'Active' : 'Inactive' }}</span>
            </div>
            @endforeach
        </div>
    </div>
</div>
@endsection
