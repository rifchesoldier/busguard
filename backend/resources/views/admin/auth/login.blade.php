<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>BusGuard — Connexion Admin</title>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;600;700;800&family=DM+Sans:wght@400;500&display=swap" rel="stylesheet">
    <script src="https://cdn.tailwindcss.com"></script>
    <script>tailwind.config={theme:{extend:{fontFamily:{sans:['DM Sans'],display:['Outfit']},colors:{ink:'#1A1F3D',terracotta:'#E07A5F',gold:'#F4A261',cream:'#FDF8F3'}}}}</script>
</head>
<body class="min-h-screen flex items-center justify-center font-sans" style="background: linear-gradient(160deg, #1A1F3D 0%, #3D405B 40%, #E07A5F 100%);">
    <div class="absolute inset-0 overflow-hidden pointer-events-none">
        <div class="absolute top-20 left-10 w-72 h-72 bg-gold/20 rounded-full blur-3xl"></div>
        <div class="absolute bottom-10 right-10 w-96 h-96 bg-terracotta/20 rounded-full blur-3xl"></div>
    </div>

    <div class="relative w-full max-w-md mx-4">
        <div class="text-center mb-8">
            <div class="inline-flex w-16 h-16 rounded-3xl bg-gradient-to-br from-gold to-terracotta items-center justify-center shadow-2xl mb-4">
                <svg class="w-9 h-9 text-white" fill="currentColor" viewBox="0 0 24 24"><path d="M4 16c0 .88.39 1.67 1 2.22V20a1 1 0 001 1h1a1 1 0 001-1v-1h8v1a1 1 0 001 1h1a1 1 0 001-1v-1.78c.61-.55 1-1.34 1-2.22V6c0-3.5-3.58-4-8-4s-8 .5-8 4v10z"/></svg>
            </div>
            <h1 class="font-display text-4xl font-bold text-white">BusGuard</h1>
            <p class="text-white/70 mt-2">Portail d'administration scolaire</p>
        </div>

        <form method="POST" action="{{ route('admin.login') }}" class="bg-white/10 backdrop-blur-xl border border-white/20 rounded-3xl p-8 shadow-2xl">
            @csrf
            <div class="space-y-5">
                <div>
                    <label class="block text-sm font-medium text-white/80 mb-2">Email</label>
                    <input type="email" name="email" value="{{ old('email') }}" required
                        class="w-full px-4 py-3.5 rounded-2xl bg-white/10 border border-white/20 text-white placeholder-white/40 focus:outline-none focus:ring-2 focus:ring-gold/50">
                    @error('email')<p class="text-red-300 text-sm mt-1">{{ $message }}</p>@enderror
                </div>
                <div>
                    <label class="block text-sm font-medium text-white/80 mb-2">Mot de passe</label>
                    <input type="password" name="password" required
                        class="w-full px-4 py-3.5 rounded-2xl bg-white/10 border border-white/20 text-white placeholder-white/40 focus:outline-none focus:ring-2 focus:ring-gold/50">
                </div>
                <div>
                    <label class="block text-sm font-medium text-white/80 mb-2">Code 2FA (si activé)</label>
                    <input type="text" name="two_factor_code" maxlength="6" placeholder="000000"
                        class="w-full px-4 py-3.5 rounded-2xl bg-white/10 border border-white/20 text-white placeholder-white/40 focus:outline-none focus:ring-2 focus:ring-gold/50">
                    @error('two_factor_code')<p class="text-red-300 text-sm mt-1">{{ $message }}</p>@enderror
                </div>
                <button type="submit" class="w-full py-4 rounded-2xl bg-gradient-to-r from-gold to-terracotta text-ink font-display font-bold text-lg shadow-lg hover:shadow-xl hover:scale-[1.02] transition-all">
                    Se connecter
                </button>
            </div>
        </form>
        <p class="text-center text-white/50 text-sm mt-6">Transport scolaire sécurisé — Dakar, Sénégal</p>
    </div>
</body>
</html>
