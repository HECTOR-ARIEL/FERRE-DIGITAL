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
- Si en el Excel del proveedor cambia la descripción, al importar aparece la lista **"¿Son el mismo producto con otro nombre?"**:
  - Muestra cada descripción nueva junto al producto anterior que se le parece (y que ya no viene en el Excel).
  - Vienen marcados los casi iguales; los dudosos (por ejemplo "PLOMADA 400GR" → "PLOMADA 500GR") vienen sin marcar.
  - Los marcados **reemplazan** al producto anterior: cambia la descripción del proveedor y el costo, y se conservan tu código, ganancia, foto, sector, stock e historial. Si no habías editado la descripción, también se actualiza la que se ve.
  - Los no marcados se crean como productos nuevos, como antes.
- El código del Excel se guarda como **código del proveedor** (no reemplaza tu código). Si un producto tiene guardado otro código del proveedor, no se sugiere: así no se confunde cuando el proveedor reutiliza un código para otro producto.
- La primera vez hay que ejecutar otra vez `supabase.sql` (crea la columna `cod_prov`). Hasta entonces no aparece la lista.

## Último código
- Al editar un producto **sin código**, al lado de "Código" aparece el último código cargado y el siguiente (por ejemplo "último código creado: A420 · siguiente: A421"). Tocando el siguiente se completa solo.

## Sectores
- Botón **Sectores** (pestaña Productos): crear, renombrar o borrar sectores. Al borrar uno, sus productos quedan "sin sector".
- Cada producto tiene su sector en la ficha. Para muchos a la vez: márcalos y usa **Mover a sector…** en la barra de abajo.
- En el catálogo, los clientes ven un botón por sector (solo los que tienen productos).
- Si los sectores no aparecen, ejecuta otra vez `supabase.sql` en Supabase.

## Importar cantidades (stock)
- Botón **Importar cantidades**: el Excel necesita una columna **Cantidad** (o Cant. / Unidades / Stock) y otra **Producto** (o Descripción) y/o **Código**.
- La cantidad se **suma** al stock actual (stock 10 + Excel 5 = 15). Antes de sumar muestra cuántos reconoció y cuáles no.
- Cada fila se reconoce por la descripción; si no coincide, por tu código.

## Anular un presupuesto (pestaña Historial)
- Si el cliente no se lleva algunos productos (o nada), pulsa **Anular** en ese presupuesto y marca cuáles (o **Todos**).
- Lo que se había descontado **vuelve al stock** (lo que había, no lo pedido: si pidió 25 y había 20, vuelven 20).
- Los anulados dejan de salir en el PDF, el total se recalcula y no se piden al proveedor. Si se anula todo, el PDF dice "PRESUPUESTO ANULADO".
- El presupuesto queda en el Historial, con la etiqueta "Anulado" o "X anulado(s)". Un producto ya anulado no se puede anular dos veces.
- Si ese presupuesto ya entró en un pedido enviado al proveedor, avisa: el stock se devuelve igual, pero lo ya pedido no cambia.
- **Eliminar** un presupuesto no devuelve stock: si el cliente no compró, usa **Anular**.
- La primera vez hay que ejecutar otra vez `supabase.sql` en Supabase (crea la función `anular_presupuesto`).

## Pedido al proveedor (pestaña Pedido)
- Suma lo vendido en los presupuestos **desde el último pedido enviado**: solo lo que se descontó del stock.
  Lo que faltó (pidieron más de lo que había) se ve en la columna "Faltó" pero **no se pide solo**: si lo quieres, escribe la cantidad a mano.
  Los productos anulados en el Historial no se cuentan.
- Productos por bulto (la descripción del proveedor dice "MINIMO 6", "MIN 10", "MINIMO 12 UNID"…): se piden bultos completos, y solo si el stock quedó por debajo de 5 (o de la mitad del bulto en los de 20 o más).
- Puedes cambiar cualquier cantidad antes de completar la nota.
- **Completar nota de pedido**: usa sola la **última nota que importaste** en "Importar Excel" (la de los precios actuales) y descarga una copia con las cantidades escritas en la columna "Cantidad", con el mismo formato. Al lado del botón dice qué nota se va a usar.
  - Cada vez que importas una nota nueva, reemplaza a la anterior. Así nunca se completa el pedido con una nota vieja.
  - **Usar otro archivo…** permite elegir otra a mano (avisa si no es la última importada).
  - La primera vez hay que ejecutar otra vez `supabase.sql` (crea la carpeta privada `notas`) y volver a importar la nota actual.
- **Marcar pedido como enviado**: después de mandar la nota. El siguiente pedido cuenta desde ahí. Hazlo antes de borrar presupuestos del Historial.
  - Si en el Historial marcas para borrar presupuestos que todavía no se pidieron, el panel no los borra y te dice cuáles son (los anulados por completo sí se pueden borrar).
- Cuando llega la mercadería: sube la misma nota completa en "Importar cantidades" para sumar el stock (corregida con lo que llegó).
- La primera vez hay que ejecutar otra vez `supabase.sql` (crea la tabla de pedidos).

## Compra por cantidad fija y Plata a separar (pestaña Pedido)
- Para productos que se compran de a muchas unidades (bultos de fichas, canillas de a 100): en Productos > editar, activa **🔒 Compra por cantidad fija** y escribe de a cuántas se compra y cuándo avisar. La primera vez hay que ejecutar otra vez `supabase.sql`.
- Esos productos no entran en el pedido común. Cada venta suma a **Plata a separar** (unidades vendidas × costo actual), y la cuenta empieza en cero al activar el candado. Los pedidos web cuentan recién al pasarlos a presupuesto; los productos anulados se descuentan. Borrar el Historial no afecta la cuenta.
- Arriba de Pedido se ve cuánto se paga ahora al proveedor, cuánto se guarda para los bultos y el total a apartar.
- Cuando el stock llega al aviso, sale **Hay que pedir**. Se compra por el Excel aparte y se toca **Ya lo compré**: la cuenta vuelve a cero. El stock se suma con "Importar cantidades".

## Recepción (comparar lo pedido con lo que llegó)
- Se eligen dos Excel: **1** la nota de pedido que se le mandó al proveedor y **2** la misma nota corregida con lo que llegó (la que después se sube en "Importar cantidades").
- Muestra al momento qué llegó completo, qué llegó incompleto y qué no llegó. Los productos se reconocen por la descripción.
- **Plata a separar**: lo que falta multiplicado por el precio unitario de la nota (si la nota no trae precio, usa el costo del panel). Sirve para apartar esa plata y volver a pedirlo.
- Botones para copiar la lista de faltantes o mandarla por WhatsApp. También avisa si llegó algo que no estaba en el pedido.
- No guarda nada ni toca el stock: el stock se sigue sumando con "Importar cantidades".

## Carrito del catálogo (pedidos web)
- La primera vez hay que ejecutar otra vez `supabase.sql` en Supabase (SQL Editor > Run). Crea la tabla `solicitudes` y la función `enviar_solicitud`.
- En el catálogo, cada producto con stock tiene **+ Agregar**. El botón **🛒 Carrito** (al lado del tema) muestra el pedido, el total estimado y pide nombre, teléfono y un comentario.
- Al enviarlo, el pedido queda guardado en Supabase y el stock queda **reservado**: se descuenta en ese momento y el catálogo lo muestra. El cliente puede además avisarte por WhatsApp con el detalle (número en `config.js` > `WHATSAPP`).
- En el panel, pestaña **Pedidos web**: el número rojo indica los pedidos nuevos (se revisa cada 30 s y avisa cuando llega uno).
  - **Pasar a presupuesto**: carga los productos en "Nuevo presupuesto" con el precio actual. Genera el PDF como siempre: se confirma la venta sin descontar dos veces (si cambias cantidades, se ajusta solo) y el pedido queda "Presupuestado".
  - **Editar cantidades**: en los pedidos nuevos, cada producto tiene − cantidad + y ✕ para quitarlo. Se guarda al instante y ajusta el stock reservado (si bajas, vuelve al stock; si subes, reserva lo que haya).
  - **Descartar**: devuelve al stock lo reservado y lo saca de la lista. Si lo recuperas desde "Descartados", vuelve a reservar lo que haya en stock.
  - El teléfono del cliente abre su WhatsApp para mandarle el presupuesto.

## Aviso por Telegram (pedidos web)
Cada pedido nuevo del carrito te llega como mensaje de Telegram, aunque tengas el panel cerrado: cliente, teléfono, productos (avisa los que no tenían stock), total y nota.
Una sola vez:
1. **Crear el bot**: en Telegram busca **@BotFather**, escríbele `/newbot`, elige un nombre (por ejemplo "Pedidos DEC") y un usuario que termine en `bot`. Te da una **clave** larga, del estilo `123456789:AAH...`. No se la pases a nadie.
2. **Háblale a tu bot**: ábrelo (el link que te da BotFather) y mándale cualquier mensaje, por ejemplo "hola".
3. **Tu número de chat**: abre en el navegador `https://api.telegram.org/botTU_CLAVE/getUpdates` (cambia `TU_CLAVE` por la clave, sin espacios). Busca `"chat":{"id":` y copia el número que sigue (por ejemplo `123456789`).
   - Si sale `"result":[]`, mándale otro mensaje al bot y recarga la página.
4. Ejecuta otra vez `supabase.sql` en Supabase (SQL Editor > Run).
5. En el SQL Editor, pega esto con tus datos y pulsa Run:
   ```sql
   insert into telegram(token, chat_id) values ('TU_CLAVE', 'TU_NUMERO_DE_CHAT')
   on conflict (id) do update set token = excluded.token, chat_id = excluded.chat_id;
   select probar_telegram();
   ```
   Te tiene que llegar "✅ Aviso de pedidos web activado". Si no llega, revisa la clave y el número y vuelve a ejecutarlo.

- La clave queda guardada solo en Supabase: **no la pongas en `config.js` ni en ningún archivo de GitHub**.
- Si Telegram falla, el pedido se guarda igual (solo se pierde ese aviso) y lo ves en Pedidos web como siempre.
- **Para que le llegue a varias personas**: crea un grupo de Telegram, agrega el bot, escribe algo en el grupo y repite el paso 3: el número del grupo empieza con `-`. Úsalo en el paso 5.
- **Para apagar los avisos**: `delete from telegram;` en el SQL Editor.

## Mosquiteros (pestaña Mosquiteros)
Cotizador de mosquiteros corredizos de una hoja (Módena, A30, A40, Rotonda, Herrero), con PDF para el cliente y su propio historial. No toca el stock, el Historial ni el Pedido de la ferretería.
- La primera vez: ejecuta otra vez `supabase.sql` (crea las tablas `mosq_config` y `mosq_presupuestos`) y pulsa **Precios de mosquiteros** para cargar los costos:
  barras de 6 m de perfil marco, travesaño y tope, cada una con su precio en blanco brillante, negro y bronce colonial; rollo de tejido (1,20 × 30 m); rollo de burlete (100 m); escuadra; tornillo del marco;
  tornillo del travesaño; patín superior e inferior; % de ganancia; corte de sierra y despunte (en mm).
- Arriba: **cliente, teléfono y dirección** (salen en el PDF).
- **Las medidas se cargan en milímetros** (1500 × 2000). Si escribes en metros (1,50) también lo entiende. En la lista y el PDF salen en metros.
- Cada mosquitero: ubicación, línea, **color** (el dibujo se pinta de ese color y sale en el PDF), **ancho de la ventana entera** y alto (el mosquitero cubre una hoja: la mitad del ancho), cantidad,
  travesaño (al marcar "Lleva travesaño" aparece debajo la cantidad de travesaños, hasta 6, y sus alturas en mm separadas por espacio; vacío = repartidos parejo) y tope (se marca solo, salvo en Herrero; debajo se elige cuántos topes, por ejemplo 2). Al costado se ve el dibujo y los materiales.
- **Suplemento de alto**: al corredizo se le suman automáticamente unos mm al alto (6 mm de fábrica; se cambia en "Precios de mosquiteros") para que entre en las guías. Se usa para cortar y cobrar el perfil, el tejido y el burlete, pero en el PDF sale el alto medido (por ejemplo 2000 mm). El fijo y el tope de repuesto no lo llevan.
- **Puerta-ventana rebatible (PVR)**: se cotiza con la medida tal cual (sin dividir, sin suplemento de alto y sin patines). Dos modelos:
  **Lateral + bisagras** (suma un lateral del alto) y **Marco en C + bisagras** (suma lateral izquierdo, parte superior y lateral derecho; abajo no lleva). Se elige la cantidad de bisagras tipo libro (4 de fábrica). Siempre lleva al menos un travesaño, al medio salvo que se escriba otra altura. No lleva tope. El **marco en C** suma 2 escuadras y 4 tornillos de marco (las dos esquinas de arriba). **Pasador** opcional (tilde "Lleva pasador"), con su precio en "Precios de mosquiteros".
  El contramarco es el mismo perfil del marco: se cobra con el precio del marco del color y se corta de las mismas barras. En "Precios de mosquiteros" se carga la **bisagra tipo libro** (c/u).
- **Fijo**: con la tilde marcada, la medida que escribes es la del mosquitero y se cotiza tal cual (no se divide) y no lleva patines. En el PDF sale "Mosquitero fijo … medida A × B".
- Lleva: perfil de marco (contorno), 4 escuadras, 8 tornillos, burlete en todo el contorno, 2 patines arriba y 2 abajo y el tejido (media hoja × alto).
  Cada travesaño suma su perfil (va entre los dos laterales), 2 tornillos; y burlete arriba y abajo (2 × su largo por cada travesaño); cada tope, un perfil del alto (el tope no lleva burlete).
- **Solo tope (repuesto)**: en "Qué se cotiza" se elige "Solo tope" para cotizar únicamente el perfil del tope (por ejemplo, para una ventana que se le rompió): línea, color, alto en mm y cantidad. En el PDF sale "Tope de mosquitero línea … — alto 2 m". Si el tejido no entra en el rollo de 1,20 m, avisa.
- **El perfil se cobra por metro usado**: precio de la barra ÷ 6 m × los metros que lleva cada mosquitero (no se cobra la barra entera).
  Debajo de la lista está la tabla **Perfilería del presupuesto** (solo en pantalla): por cada perfil (marco, travesaño, tope) y color, los mm que se usan en todo el presupuesto, cuántas barras de 6 m comprar (con sierra y despunte) y cuánto sobra. El contramarco del rebatible cuenta dentro del marco.
- **Abertura**: ventana, puerta-ventana o puerta-ventana rebatible. Cada renglón lleva un código: **V1, V2…** (ventanas), **PV1, PV2…** (puerta-ventanas), **PVR1…** (rebatibles) y **T1…** (topes de repuesto); se ve en la lista y en el PDF.
- **PDF**: después del cliente va un saludo y un recuadro por renglón: arriba el código y la ubicación (por ejemplo "V1 — COCINA"); a la izquierda el dibujo con su color y las medidas en mm; a la derecha línea, color, medida de la ventana y de la hoja, travesaños y topes; abajo UDS, precio unitario y total. Al pie, "Página X de Y".
- **Vista previa**: abre el PDF en otra pestaña sin guardar el presupuesto (arriba dice "Vista previa (sin guardar)"). Si algo no está bien, se corrige en el formulario y se vuelve a ver.
- **Guardar y generar PDF**: primero lo guarda (con número) y después saca el PDF. Cada mosquitero sale con la medida de la ventana (ancho total × alto), cantidad, precio y subtotal, el total y, si cargas **Colocación**, el total con colocación. Si no hay colocación, dice "Colocación: No incluida". Junto al total va el recuadro "Toma de medidas y envío incluidos". Al final van los **Términos y condiciones** (plazo de entrega y formas de pago). Tus costos y la ganancia no aparecen.
- **Presupuestos de mosquiteros guardados** (abajo): lista con número, fecha, cliente, teléfono, dirección y total, con buscador. **Abrir** lo carga para verlo, cambiarlo o volver a sacar el PDF (al guardarlo otra vez se actualiza el mismo número). Si los precios cambiaron desde que se guardó, avisa cuánto daba antes y cuánto da ahora. ✕ lo borra.
- **Nuevo presupuesto** empieza uno en blanco (si el actual tiene cambios sin guardar, pregunta antes). Arriba se ve si el presupuesto está guardado o tiene cambios sin guardar.

## Copia de seguridad
- Botón **Copia de seguridad** (pestaña Productos): descarga un Excel `copia-Distribuidor-DEC-AAAA-MM-DD.xlsx` con una hoja por tema:
  **Productos** (código, descripción, costo, ganancia, precio, stock, sector, compra mínima, si está oculto o en la papelera),
  **Historial** (cada presupuesto con sus productos, lo que faltó y lo anulado), **Pedidos web**, **Pedidos al proveedor** y **Sectores**.
- Supabase gratis no deja descargar copias de la base: este archivo es tu respaldo. Hazla una vez por semana (por ejemplo el lunes, antes de limpiar el Historial) y guárdala también fuera de la computadora (Google Drive, pendrive).
- La copia guarda los datos, pero no los restaura con un clic. Si hiciera falta recuperar algo: los productos, costos y stock se pueden volver a cargar con "Importar Excel" e "Importar cantidades"; el resto se recupera desde el archivo.

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
