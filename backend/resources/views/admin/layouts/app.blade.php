<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>@yield('title', 'BusGuard Admin')</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800&family=DM+Sans:ital,wght@0,400;0,500;0,700;1,400&display=swap" rel="stylesheet">
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
        tailwind.config = {
            theme: {
                extend: {
                    fontFamily: { sans: ['DM Sans', 'sans-serif'], display: ['Outfit', 'sans-serif'] },
                    colors: {
                        ink: '#1A1F3D',
                        terracotta: '#E07A5F',
                        sage: '#81B29A',
                        gold: '#F4A261',
                        cream: '#FDF8F3',
                        dusk: '#3D405B',
                    }
                }
            }
        }
    </script>
    <style>
        body { background: linear-gradient(135deg, #FDF8F3 0%, #F5EDE4 50%, #E8F0EC 100%); min-height: 100vh; }
        .glass { background: rgba(255,255,255,0.72); backdrop-filter: blur(20px); border: 1px solid rgba(255,255,255,0.8); }
        .sidebar-link { transition: all 0.2s ease; }
        .sidebar-link:hover, .sidebar-link.active { background: linear-gradient(90deg, rgba(224,122,95,0.15), transparent); border-left: 3px solid #E07A5F; }
        .stat-card { background: linear-gradient(145deg, #fff 0%, #FDF8F3 100%); }
        .pattern-bg { background-image: radial-gradient(circle at 20% 80%, rgba(244,162,97,0.08) 0%, transparent 50%), radial-gradient(circle at 80% 20%, rgba(129,178,154,0.1) 0%, transparent 50%); }
    </style>
</head>
<body class="font-sans text-ink pattern-bg">
    <div class="flex min-h-screen">
        <aside class="w-72 glass border-r border-white/60 hidden lg:flex flex-col fixed h-full z-20">
            <div class="p-6 border-b border-white/50">
                <div class="flex items-center gap-3">
                    <div class="w-11 h-11 rounded-2xl bg-gradient-to-br from-terracotta to-gold flex items-center justify-center shadow-lg shadow-terracotta/30">
                        <svg class="w-6 h-6 text-white" fill="currentColor" viewBox="0 0 24 24"><path d="M4 16c0 .88.39 1.67 1 2.22V20a1 1 0 001 1h1a1 1 0 001-1v-1h8v1a1 1 0 001 1h1a1 1 0 001-1v-1.78c.61-.55 1-1.34 1-2.22V6c0-3.5-3.58-4-8-4s-8 .5-8 4v10zm3.5 1c-.83 0-1.5-.67-1.5-1.5S6.67 14 7.5 14s1.5.67 1.5 1.5S8.33 17 7.5 17zm9 0c-.83 0-1.5-.67-1.5-1.5s.67-1.5 1.5-1.5 1.5.67 1.5 1.5-.67 1.5-1.5 1.5zm1.5-6H6V6h12v5z"/></svg>
                    </div>
                    <div>
                        <h1 class="font-display font-bold text-xl text-ink">BusGuard</h1>
                        <p class="text-xs text-dusk/60">Administration Dakar</p>
                    </div>
                </div>
            </div>
            <nav class="flex-1 p-4 space-y-1">
                @php $route = request()->route()->getName(); @endphp
                <a href="{{ route('admin.dashboard') }}" class="sidebar-link flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium {{ str_contains($route, 'dashboard') ? 'active text-terracotta' : 'text-dusk' }}">
                    <span>📊</span> Tableau de bord
                </a>
                <a href="{{ route('admin.schools') }}" class="sidebar-link flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium {{ str_contains($route, 'schools') ? 'active text-terracotta' : 'text-dusk' }}">
                    <span>🏫</span> Écoles
                </a>
                <a href="{{ route('admin.buses') }}" class="sidebar-link flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium {{ str_contains($route, 'buses') ? 'active text-terracotta' : 'text-dusk' }}">
                    <span>🚌</span> Bus
                </a>
                <a href="{{ route('admin.routes') }}" class="sidebar-link flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium {{ str_contains($route, 'routes') ? 'active text-terracotta' : 'text-dusk' }}">
                    <span>🗺️</span> Itinéraires
                </a>
                <a href="{{ route('admin.students') }}" class="sidebar-link flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium {{ str_contains($route, 'students') ? 'active text-terracotta' : 'text-dusk' }}">
                    <span>👧</span> Élèves
                </a>
                <a href="{{ route('admin.drivers') }}" class="sidebar-link flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium {{ str_contains($route, 'drivers') ? 'active text-terracotta' : 'text-dusk' }}">
                    <span>👨‍✈️</span> Chauffeurs
                </a>
                <a href="{{ route('admin.attendance') }}" class="sidebar-link flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium {{ str_contains($route, 'attendance') ? 'active text-terracotta' : 'text-dusk' }}">
                    <span>📋</span> Présences
                </a>
            </nav>
            <div class="p-4 border-t border-white/50">
                <form method="POST" action="{{ route('admin.logout') }}">
                    @csrf
                    <button class="w-full px-4 py-2.5 rounded-xl text-sm font-medium text-dusk hover:bg-red-50 hover:text-red-600 transition">Déconnexion</button>
                </form>
            </div>
        </aside>

        <main class="flex-1 lg:ml-72 p-6 lg:p-10">
            @if(session('success'))
                <div class="mb-6 px-5 py-4 rounded-2xl bg-sage/20 border border-sage/30 text-sage font-medium">{{ session('success') }}</div>
            @endif
            @yield('content')
        </main>
    </div>
</body>
</html>
