# Puesta en marcha (todo gratis)

## 1. Supabase (la base de datos)
1. Crea un proyecto en supabase.com.
2. Ve a SQL Editor, pega el contenido de `supabase.sql` y pulsa Run.
3. Authentication > Users > Add user: crea tu usuario (email y contraseña).
4. Authentication > Sign In / Providers: desactiva "Allow new users to sign up", para que nadie más pueda registrarse.
5. Project Settings > API: copia la Project URL y la clave `anon public`, y pégalas en `config.js`.

## 2. GitHub Pages (la web)
1. Crea un repositorio nuevo y sube todos los archivos de esta carpeta.
2. Settings > Pages > Deploy from a branch > main, carpeta / (root).
3. Tu catálogo para clientes: `https://TU-USUARIO.github.io/TU-REPO/`
4. Tu panel de presupuestos: `.../admin.html` (inicia sesión con tu usuario).

## 3. Instalar en el teléfono o el ordenador
Abre `admin.html` y usa "Instalar" (Chrome/Edge) o "Añadir a pantalla de inicio" (Safari/Chrome móvil).

## Excel
Primera fila con las columnas: `codigo`, `nombre`, `precio` y, opcionalmente, `stock`.
Si el código ya existe se actualiza; si no, se crea. Sin columna `stock`, el stock actual no se toca.
