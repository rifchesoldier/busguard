@extends('admin.layouts.app')
@section('title', 'Historique des présences')
@section('content')
<div class="flex justify-between items-center mb-8">
    <div><h1 class="font-display text-3xl font-bold">Présences</h1><p class="text-dusk/70">Historique consultable — conservation 1 an</p></div>
    <a href="/api/v1/attendance/export" class="px-5 py-2.5 rounded-xl bg-ink text-white text-sm font-medium hover:bg-dusk transition">Export CSV</a>
</div>
<div class="glass rounded-3xl p-6">
    <table class="w-full text-sm">
        <thead><tr class="text-left text-dusk/60 border-b border-dusk/10">
            <th class="pb-3">Date</th><th class="pb-3">Élève</th><th class="pb-3">Bus</th><th class="pb-3">Arrêt</th><th class="pb-3">Statut</th><th class="pb-3">Heure</th>
        </tr></thead>
        <tbody>
        @foreach($logs as $log)
        <tr class="border-b border-dusk/5 hover:bg-white/40">
            <td class="py-3">{{ $log->date->format('d/m/Y') }}</td>
            <td class="py-3 font-medium">{{ $log->student->first_name }} {{ $log->student->last_name }}</td>
            <td class="py-3">{{ $log->bus->matricule }}</td>
            <td class="py-3">{{ $log->stop->name ?? '—' }}</td>
            <td class="py-3">
                <span class="px-2 py-1 rounded-full text-xs font-medium
                    @if($log->status === 'present') bg-sage/20 text-sage
                    @elseif($log->status === 'absent') bg-red-100 text-red-600
                    @else bg-gold/20 text-gold @endif">{{ ucfirst($log->status) }}</span>
            </td>
            <td class="py-3 text-dusk/60">{{ $log->recorded_at->format('H:i') }}</td>
        </tr>
        @endforeach
        </tbody>
    </table>
    <div class="mt-4">{{ $logs->links() }}</div>
</div>
@endsection
