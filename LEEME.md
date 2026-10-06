# Puesta en marcha (todo gratis)

## 1. Supabase (la base de datos)
1. Crea un proyecto en supabase.com.
2. Ve a SQL Editor, pega el contenido de `supabase.sql` y pulsa Run.
   - Si ya lo habías ejecutado antes, vuelve a ejecutarlo: actualiza la base sin borrar tus productos
     (el precio que tenían pasa a ser el **costo**, con 0 % de ganancia).
3. Authentication > Users > Add user: crea tu usuario (email y contraseña).
4. Authentication > Sign In / Providers: desactiva "Allow new users to sign up", para que nadie más pueda registrarse.
5. Project Settings > API: copia la Project URL y la clave `anon public`, y pégalas en `config.js`.
   En `config.js` también puedes cambiar el nombre del negocio y el símbolo de moneda.

## 2. GitHub Pages (la web)
1. Crea un repositorio nuevo y sube todos los archivos de esta carpeta.
2. Settings > Pages > Deploy from a branch > main, carpeta / (root).
3. Catálogo para clientes: `https://TU-USUARIO.github.io/TU-REPO/`
4. Panel de administración: botón **Administrar** del catálogo (o `.../admin.html`).

## 3. Instalar en el teléfono o el ordenador
Abre `admin.html` y usa "Instalar" (Chrome/Edge) o "Añadir a pantalla de inicio" (Safari/Chrome móvil).

## Cómo funcionan los precios
- **Costo**: el precio que viene en el Excel.
- **Ganancia %**: la pones tú, por producto o a muchos a la vez (filtra con el buscador y pulsa "Aplicar").
- **Precio venta** = costo + ganancia. Es el que ve el cliente. Si escribes el precio de venta a mano, se calcula la ganancia.
- Los visitantes del catálogo nunca ven tu costo ni tu ganancia.

## Excel
Primera fila con las columnas: `descripcion` y `precio` (el costo) y, opcionalmente, `stock`.
(También se aceptan `nombre`/`producto` en lugar de `descripcion`, y `costo` en lugar de `precio`.)

Cada producto se reconoce por su **descripción original del Excel**, no por el código:
- Si la descripción ya existe, se actualiza el costo (y el stock si viene). Tu código, descripción editada, ganancia e imagen se mantienen.
- Si no existe, se crea con el % de ganancia indicado en "Ganancia para productos nuevos".
- Si cambias la descripción en el panel, el producto sigue vinculado a su fila del Excel.
- Si en el Excel del proveedor cambia la descripción, se creará como producto nuevo.

## Sectores
- Botón **Sectores** (pestaña Productos): crear, renombrar o borrar sectores. Al borrar uno, sus productos quedan "sin sector".
- Cada producto tiene su sector en la ficha. Para muchos a la vez: márcalos y usa **Mover a sector…** en la barra de abajo.
- En el catálogo, los clientes ven un botón por sector (solo los que tienen productos).
- Si los sectores no aparecen, ejecuta otra vez `supabase.sql` en Supabase.
