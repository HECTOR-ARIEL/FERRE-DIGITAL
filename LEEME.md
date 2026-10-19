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

## Importar cantidades (stock)
- Botón **Importar cantidades**: el Excel necesita una columna **Cantidad** (o Cant. / Unidades / Stock) y otra **Producto** (o Descripción) y/o **Código**.
- La cantidad se **suma** al stock actual (stock 10 + Excel 5 = 15). Antes de sumar muestra cuántos reconoció y cuáles no.
- Cada fila se reconoce por la descripción; si no coincide, por tu código.

## Pedido al proveedor (pestaña Pedido)
- Suma todo lo vendido en los presupuestos **desde el último pedido enviado**: lo vendido + lo que faltó por falta de stock.
- Productos por bulto (la descripción del proveedor dice "MINIMO 6", "MIN 10", "MINIMO 12 UNID"…): se piden bultos completos, y solo si el stock quedó por debajo de 5 (o de la mitad del bulto en los de 20 o más).
- Puedes cambiar cualquier cantidad antes de completar la nota.
- **Completar nota de pedido**: eliges la nota del proveedor (.xlsx) y se descarga una copia con las cantidades escritas en la columna "Cantidad", con el mismo formato. El original no se toca.
- **Marcar pedido como enviado**: después de mandar la nota. El siguiente pedido cuenta desde ahí. Hazlo antes de borrar presupuestos del Historial.
- Cuando llega la mercadería: sube la misma nota completa en "Importar cantidades" para sumar el stock.
- La primera vez hay que ejecutar otra vez `supabase.sql` (crea la tabla de pedidos).

## Carrito del catálogo (pedidos web)
- La primera vez hay que ejecutar otra vez `supabase.sql` en Supabase (SQL Editor > Run). Crea la tabla `solicitudes` y la función `enviar_solicitud`.
- En el catálogo, cada producto con stock tiene **+ Agregar**. El botón **🛒 Carrito** (al lado del tema) muestra el pedido, el total estimado y pide nombre, teléfono y un comentario.
- Al enviarlo, el pedido queda guardado en Supabase y el stock queda **reservado**: se descuenta en ese momento y el catálogo lo muestra. El cliente puede además avisarte por WhatsApp con el detalle (número en `config.js` > `WHATSAPP`).
- En el panel, pestaña **Pedidos web**: el número rojo indica los pedidos nuevos (se revisa cada 30 s y avisa cuando llega uno).
  - **Pasar a presupuesto**: carga los productos en "Nuevo presupuesto" con el precio actual. Genera el PDF como siempre: se confirma la venta sin descontar dos veces (si cambias cantidades, se ajusta solo) y el pedido queda "Presupuestado".
  - **Editar cantidades**: en los pedidos nuevos, cada producto tiene − cantidad + y ✕ para quitarlo. Se guarda al instante y ajusta el stock reservado (si bajas, vuelve al stock; si subes, reserva lo que haya).
  - **Descartar**: devuelve al stock lo reservado y lo saca de la lista. Si lo recuperas desde "Descartados", vuelve a reservar lo que haya en stock.
  - El teléfono del cliente abre su WhatsApp para mandarle el presupuesto.

## Recuperar la contraseña del panel
- Configuración (una sola vez): en Supabase > Authentication > URL Configuration
  - **Site URL**: la dirección de tu panel, por ejemplo `https://hector-ariel.github.io/TU-REPO/admin.html`
  - **Redirect URLs** > Add URL: `https://hector-ariel.github.io/**`
- Si te olvidas la contraseña: en el inicio de sesión escribe tu email y toca **¿Olvidaste tu contraseña?**. Te llega un link por email (revisa Spam); al tocarlo, el panel te pide la contraseña nueva.
- El link vence en 1 hora y sirve una sola vez. Supabase gratis permite pocos emails por hora: si dice "espera unos minutos", espera.
- Plan B: en supabase.com > Authentication > Users, en tu usuario puedes enviarte el link ("Send password recovery") o cambiar la contraseña.

## Compra mínima (catálogo)
- En el catálogo ya no se ve la leyenda del proveedor "(MINIMO 12 UNIDADES)", "MIN 10", "(CAJA CERRADA 50 UNID)"…: el cliente ve el nombre limpio. En el panel y en el pedido al proveedor la descripción sigue completa.
- Cada producto tiene **Compra mínima** en su ficha: vacío = se vende por unidad; con número, el catálogo muestra "Compra mínima: X" y el carrito no deja pedir menos (al tocar "Agregar" pone directamente ese mínimo).
  - El botón **Usar el de la descripción (X)** copia el número que dice "MINIMO" o "CAJA CERRADA" en la descripción.
- Para muchos a la vez: marca los productos y en la barra de abajo elige **Compra mínima… > Según la descripción** o **Por unidad**.
- Filtro (junto a sectores): **Con compra mínima**, **Por unidad** o **Dicen MINIMO pero van por unidad** (para revisarlos).
- La primera vez hay que ejecutar otra vez `supabase.sql` en Supabase (crea la columna `minimo`). Hasta entonces, todos se venden por unidad.
