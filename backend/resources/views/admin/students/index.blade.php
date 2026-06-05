@extends('admin.layouts.app')
@section('title', 'Élèves')
@section('content')
<div class="mb-8"><h1 class="font-display text-3xl font-bold">Élèves</h1></div>
<div class="grid lg:grid-cols-3 gap-6">
    <div class="glass rounded-3xl p-6">
        <h2 class="font-display font-semibold mb-4">Inscrire un élève</h2>
        <form method="POST" action="{{ route('admin.students.store') }}" class="space-y-3">
            @csrf
            <input name="first_name" placeholder="Prénom" required class="w-full px-4 py-3 rounded-xl border border-dusk/10">
            <input name="last_name" placeholder="Nom" required class="w-full px-4 py-3 rounded-xl border border-dusk/10">
            <select name="school_id" required class="w-full px-4 py-3 rounded-xl border border-dusk/10">
                @foreach($schools as $s)<option value="{{ $s->id }}">{{ $s->name }}</option>@endforeach
            </select>
            <input name="class_name" placeholder="Classe (ex: CM2 A)" class="w-full px-4 py-3 rounded-xl border border-dusk/10">
            <select name="parent_id" class="w-full px-4 py-3 rounded-xl border border-dusk/10">
                <option value="">— Parent —</option>
                @foreach($parents as $p)<option value="{{ $p->id }}">{{ $p->name }}</option>@endforeach
            </select>
            <select name="assigned_bus_id" class="w-full px-4 py-3 rounded-xl border border-dusk/10">
                <option value="">— Bus —</option>
                @foreach($buses as $b)<option value="{{ $b->id }}">{{ $b->matricule }}</option>@endforeach
            </select>
            <button class="w-full py-3 rounded-xl bg-gradient-to-r from-terracotta to-gold text-white font-semibold">Inscrire</button>
        </form>
    </div>
    <div class="lg:col-span-2 glass rounded-3xl p-6">
        <table class="w-full text-sm">
            <thead><tr class="text-left text-dusk/60 border-b border-dusk/10">
                <th class="pb-3">Élève</th><th class="pb-3">Classe</th><th class="pb-3">Bus</th><th class="pb-3">Statut</th>
            </tr></thead>
            <tbody>
            @foreach($students as $student)
            <tr class="border-b border-dusk/5">
                <td class="py-3 font-medium">{{ $student->first_name }} {{ $student->last_name }}</td>
                <td class="py-3 text-dusk/70">{{ $student->class_name ?? '—' }}</td>
                <td class="py-3">{{ $student->bus->matricule ?? '—' }}</td>
                <td class="py-3"><span class="px-2 py-1 rounded-full text-xs bg-sage/20 text-sage">{{ str_replace('_', ' ', $student->current_status) }}</span></td>
            </tr>
            @endforeach
            </tbody>
        </table>
    </div>
</div>
@endsection
