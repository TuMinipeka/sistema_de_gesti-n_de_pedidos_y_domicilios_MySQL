# Sistema de Gestión de Pizzería y Domicilios

Base de datos relacional en **MySQL** para gestionar el proceso completo de venta
de pizzas y domicilios: clientes, catálogo de pizzas e ingredientes, pedidos,
repartidores y entregas.

## Estructura del proyecto

```
├── database.sql     -- Creación de la BD, tablas, llaves foráneas y datos de ejemplo (INSERT)
├── funciones.sql     -- Funciones almacenadas (CREATE FUNCTION) [pendiente]
├── triggers.sql       -- Triggers y procedimientos (CREATE TRIGGER / PROCEDURE) [pendiente]
├── vistas.sql          -- Vistas de reportes (CREATE VIEW) [pendiente]
├── consultas.sql        -- Consultas SQL complejas (JOIN, subconsultas, agregaciones) [pendiente]
└── README.md
```

> Los archivos `funciones.sql`, `triggers.sql`, `vistas.sql` y `consultas.sql`
> se dejaron con la cabecera y el listado de lo que deben contener según los
> requerimientos del proyecto; su desarrollo queda a cargo del autor.

## 1. Descripción del proyecto

El sistema permite:

- Registrar clientes y su historial de pedidos.
- Administrar el catálogo de pizzas y la relación con los ingredientes que las componen.
- Controlar el stock de ingredientes y su nivel mínimo permitido.
- Registrar pedidos con su detalle (una o varias pizzas por pedido), método de pago,
  estado y total.
- Asignar repartidores y gestionar los domicilios: hora de salida, hora de entrega,
  distancia y tarifa de envío aplicada según zona.
- Mantener un historial de cambios de precio de las pizzas (auditoría).

## 2. Corrección del diseño original

El archivo exportado desde drawSQL (`drawSQL-mysql-export-2026-07-14.sql`) tenía
errores que impedían su ejecución y comprometían la integridad de los datos.
Se corrigieron antes de generar `database.sql`:

| # | Problema original | Corrección aplicada |
|---|---|---|
| 1 | `ENUM('')` vacíos en `tamaño`, `tipo`, `metodo_pago` y `estado` | Se definieron los valores reales de cada enumeración |
| 2 | `DEFAULT '0, ≥ 0'`, `DEFAULT '≥ 1'`, `DEFAULT 'En kilómetros'` (texto descriptivo usado como valor por defecto, sintácticamente inválido) | Se reemplazaron por `DEFAULT` numéricos correctos y `CHECK` constraints donde aplica |
| 3 | Relaciones foráneas invertidas: `pizzas → pizza_ingredientes`, `repartidores → domicilios`, `ingredientes → pizza_ingredientes`, `pedidos → detalle_pedido` | Se corrigió la dirección: las tablas "hijas" (`pizza_ingredientes`, `domicilios`, `detalle_pedido`) referencian a las tablas "padre" |
| 4 | `pizza_ingredientes.id_pizza` con `AUTO_INCREMENT` (siendo una llave foránea) y la PK real sin autoincremento | `id_pizza_ingrediente` es ahora la PK autoincremental; `id_pizza` e `id_ingrediente` son FKs normales |
| 5 | Faltaban FKs: `detalle_pedido → pedidos`, `domicilios → pedidos`, `domicilios → repartidores` | Se agregaron todas las relaciones necesarias |
| 6 | Tipos de datos inconsistentes entre PK y FK (`BIGINT` vs `INT`, `UNSIGNED` faltante) | Se unificaron todos los identificadores como `INT UNSIGNED` |
| 7 | Sin charset UTF-8, columnas obligatorias sin `NOT NULL` | Base de datos creada con `utf8mb4`; se agregaron `NOT NULL` a los campos requeridos por el negocio |

## 3. Tablas y relaciones

| Tabla | Descripción | Relaciones |
|---|---|---|
| `clientes` | Datos de contacto de cada cliente | 1 cliente → N pedidos |
| `pizzas` | Catálogo de pizzas (nombre, tamaño, precio, tipo) | 1 pizza → N pizza_ingredientes, N detalle_pedido, N historial_precios |
| `ingredientes` | Insumos con control de stock | 1 ingrediente → N pizza_ingredientes |
| `pizza_ingredientes` | Tabla puente N:M entre `pizzas` e `ingredientes`, con la cantidad usada de cada insumo | FK a `pizzas` y a `ingredientes` |
| `repartidores` | Personal de reparto, zona asignada y disponibilidad | 1 repartidor → N domicilios |
| `tarifas_envio` | Costo de envío según zona y rango de distancia | 1 tarifa → N domicilios |
| `pedidos` | Encabezado del pedido (cliente, fecha, método de pago, estado, total) | FK a `clientes`; 1 pedido → N detalle_pedido; 1 pedido → 1 domicilio |
| `detalle_pedido` | Pizzas y cantidades que componen cada pedido | FK a `pedidos` y a `pizzas` |
| `domicilios` | Datos de la entrega: repartidor, tarifa, horarios y distancia | FK a `pedidos` (1:1), `repartidores` y `tarifas_envio` |
| `historial_precios` | Auditoría de cambios de precio en `pizzas` | FK a `pizzas` |

### Diagrama de relaciones (resumen)

```
clientes 1───N pedidos 1───N detalle_pedido N───1 pizzas
                 │                                  │
                 1                                  1
                 │                                  N
             domicilios                    pizza_ingredientes
              │      │                              N
              N      N                               │
      repartidores  tarifas_envio               ingredientes

pizzas 1───N historial_precios
```

## 4. Ejemplos de consultas

Ejemplos ilustrativos de cómo se relacionan las tablas (el set completo de
consultas requeridas se desarrolla en `consultas.sql`):

```sql
-- Pedidos de un cliente con el detalle de pizzas solicitadas
SELECT c.nombre, p.id_pedido, p.fecha_hora, pz.nombre AS pizza, dp.cantidad
FROM pedidos p
JOIN clientes c ON c.id_cliente = p.id_cliente
JOIN detalle_pedido dp ON dp.id_pedido = p.id_pedido
JOIN pizzas pz ON pz.id_pizza = dp.id_pizza
WHERE c.id_cliente = 1;

-- Ingredientes de una pizza específica
SELECT pz.nombre AS pizza, i.nombre AS ingrediente, pi.cantidad_usada
FROM pizza_ingredientes pi
JOIN pizzas pz ON pz.id_pizza = pi.id_pizza
JOIN ingredientes i ON i.id_ingrediente = pi.id_ingrediente
WHERE pz.id_pizza = 1;

-- Estado de un domicilio con su repartidor y tarifa
SELECT p.id_pedido, r.nombre AS repartidor, t.zona, d.distancia, t.costo_envio
FROM domicilios d
JOIN pedidos p ON p.id_pedido = d.id_pedido
JOIN repartidores r ON r.id_repartidor = d.id_repartidor
JOIN tarifas_envio t ON t.id_tarifa = d.id_tarifa;
```

## 5. Instrucciones para ejecutar el script

### Requisitos
- MySQL 8.x o MariaDB 10.11+ (soporte de `CHECK CONSTRAINT` y `utf8mb4`).
- Cliente `mysql` en línea de comandos o DBeaver.

### Desde la línea de comandos

```bash
mysql -u <usuario> -p --default-character-set=utf8mb4 < database.sql
```

> Importante: usar `--default-character-set=utf8mb4` (o configurarlo en el
> cliente) para que los nombres con tildes (`tamaño`, `dirección`, etc.) se
> inserten correctamente.

Una vez creada la base y las tablas, ejecutar en este orden los demás scripts
cuando estén desarrollados:

```bash
mysql -u <usuario> -p pizzeria_db --default-character-set=utf8mb4 < funciones.sql
mysql -u <usuario> -p pizzeria_db --default-character-set=utf8mb4 < triggers.sql
mysql -u <usuario> -p pizzeria_db --default-character-set=utf8mb4 < vistas.sql
mysql -u <usuario> -p pizzeria_db --default-character-set=utf8mb4 < consultas.sql
```

### Desde DBeaver

1. Crear una nueva conexión MySQL/MariaDB.
2. En las propiedades de conexión, verificar que el charset sea `utf8mb4`.
3. Abrir `database.sql` y ejecutar el script completo (`Execute SQL Script`,
   no solo la sentencia bajo el cursor).
4. Repetir con `funciones.sql`, `triggers.sql`, `vistas.sql` y `consultas.sql`
   una vez estén completos.

## 6. Funciones, Procedimiento, Triggers, Vistas y Consultas

A continuación se documentan todos los objetos de base de datos y consultas
implementados para cumplir con los requerimientos funcionales del proyecto.

### 6.1 Funciones almacenadas (`funciones.sql`)

#### `fn_calcular_total_pedido`

Calcula el total final de un pedido sumando el subtotal de las pizzas
(`detalle_pedido.subtotal`) más el costo de envío del domicilio asociado
(`tarifas_envio.costo_envio`), y aplica el 19 % de IVA sobre esa suma.
El resultado se retorna como `DECIMAL(10,2)`.

- **Parámetro:** `p_id_pedido INT`
- **Uso:** Invocada automáticamente por el procedimiento
  `sp_entregar_pedido` al marcar un pedido como entregado.
- **Contribución:** Automatiza el cálculo del total con IVA y envío,
  eliminando errores manuales y garantizando facturación correcta.

#### `fn_ganancia_neta_diaria`

Calcula la ganancia neta de un día específico restando a los ingresos
por pedidos entregados (`pedidos.total`) el costo de los ingredientes
consumidos en esos pedidos. Obtiene el costo de ingredientes mediante
la relación `detalle_pedido` → `pizza_ingredientes` → `ingredientes`,
multiplicando cantidad usada por costo unitario.

- **Parámetro:** `p_fecha DATE`
- **Retorno:** `DECIMAL(10,2)`
- **Contribución:** Proporciona una métrica financiera clave para la
  toma de decisiones, permitiendo conocer la rentabilidad real por día.

### 6.2 Procedimiento almacenado (`funciones.sql`)

#### `sp_entregar_pedido`

Marca un pedido como `'Entregado'` y actualiza su campo `total`
invocando a `fn_calcular_total_pedido` con el identificador del pedido.

- **Parámetro:** `p_id_pedido INT`
- **Contribución:** Encapsula la lógica de cierre de un pedido
  (cambio de estado + cálculo del total) en una sola operación
  transaccional, asegurando consistencia entre el estado y el valor
  final registrado.

### 6.3 Triggers (`triggers.sql`)

#### `trg_actualizar_stock_ingredientes`

- **Evento:** `AFTER INSERT` sobre `detalle_pedido`.
- **Función:** Por cada línea de detalle insertada, descuenta del
  stock de `ingredientes` la cantidad de cada insumo utilizado
  (`pizza_ingredientes.cantidad_usada × detalle_pedido.cantidad`).
- **Contribución:** Mantiene el inventario actualizado en tiempo real
  sin intervención manual, asegurando que el stock refleje
  fielmente las ventas realizadas.

#### `trg_historial_precios`

- **Evento:** `AFTER UPDATE` sobre `pizzas`.
- **Función:** Cuando cambia el `precio_base` de una pizza, inserta
  automáticamente un registro en `historial_precios` con el precio
  anterior, el nuevo precio y la fecha/hora del cambio.
- **Contribución:** Proporciona una pista de auditoría completa para
  rastrear modificaciones de precios, requerimiento indispensable
  para reportes financieros y control interno.

#### `trg_repartidor_disponible`

- **Evento:** `AFTER UPDATE` sobre `domicilios`.
- **Función:** Cuando se registra la `hora_entrega` en un domicilio
  (pasando de `NULL` a un valor), cambia el estado del repartidor
  asignado a `'Disponible'` en la tabla `repartidores`.
- **Contribución:** Automatiza la gestión de disponibilidad del
  personal de reparto, permitiendo asignar nuevos envíos sin
  necesidad de actualización manual.

### 6.4 Vistas (`vistas.sql`)

#### `vw_resumen_pedidos_clientes`

Agrupa a los clientes con la cantidad de pedidos realizados y el
total acumulado gastado (`COUNT` y `SUM` sobre `pedidos`).

- **Columnas:** `id_cliente`, `nombre`, `cantidad_pedidos`,
  `total_gastado`.
- **Contribución:** Permite al negocio identificar clientes
  frecuentes y su valor económico, insumo para programas de
  fidelización y análisis de ventas.

#### `vw_desempeno_repartidores`

Muestra métricas de desempeño de cada repartidor: total de entregas
completadas y tiempo promedio del recorrido en minutos (diferencia
entre `hora_salida` y `hora_entrega` usando `TIMESTAMPDIFF`).

- **Columnas:** `id_repartidor`, `nombre`, `zona_asignada`,
  `total_entregas`, `tiempo_promedio_minutos`.
- **Contribución:** Facilita la evaluación del rendimiento de los
  repartidores y la eficiencia por zona, apoyando decisiones
  operativas y de asignación de rutas.

#### `vw_stock_bajo`

Lista los ingredientes cuyo stock actual es inferior al mínimo
permitido (`stock < stock_minimo`).

- **Columnas:** `id_ingrediente`, `nombre`, `stock`, `stock_minimo`,
  `costo_unitario`.
- **Contribución:** Alerta temprana para el área de compras sobre
  insumos próximos a agotarse, evitando rupturas de inventario que
  afecten la producción.

### 6.5 Consultas SQL implementadas (`consultas.sql`)

| # | Consulta | Descripción | Requerimiento |
|---|---|---|---|
| 1 | Pedidos por fecha | `JOIN` entre `clientes` y `pedidos` filtrado por rango de fechas (`BETWEEN`), ordenado por fecha. | Reportes temporales |
| 2 | Pizzas más vendidas | `JOIN` `pizzas` ↔ `detalle_pedido` con `SUM(cantidad)` y `ORDER BY` descendente. | Identificar productos estrella |
| 3 | Pedidos por repartidor | `JOIN` `repartidores` ↔ `domicilios` ↔ `pedidos`, ordenado por nombre y fecha. | Control de carga laboral |
| 4 | Tiempo promedio por zona | `AVG(TIMESTAMPDIFF)` agrupado por `zona_asignada` en entregas completadas. | Evaluar eficiencia operativa por zona |
| 5 | Clientes con gasto superior | `HAVING SUM(total) > 50000` tras agrupar por cliente. | Identificar clientes VIP |
| 6 | Búsqueda de pizza por nombre | `LIKE '%Queso%'` para filtrar catálogo. | Búsqueda rápida en el menú |
| 7 | Clientes frecuentes (subconsulta) | Subconsulta que obtiene clientes con más de 5 pedidos en un mes, y consulta externa que devuelve sus datos. | Detectar alta recurrencia |

## 7. Validación realizada

`database.sql` fue ejecutado y probado contra un servidor MariaDB 10.11:

- Las 10 tablas se crean sin errores.
- Los datos de ejemplo se insertan correctamente (5 clientes, 5 pizzas,
  6 ingredientes, 14 relaciones pizza-ingrediente, 3 repartidores,
  3 tarifas, 6 pedidos, 8 líneas de detalle, 4 domicilios y 2 registros
  de historial de precios).
- Las llaves foráneas apuntan en la dirección correcta (verificado contra
  `information_schema.KEY_COLUMN_USAGE`).
- Los `CHECK constraints` (stock ≥ 0, cantidad ≥ 1, distancia_max ≥ distancia_min)
  y las llaves foráneas rechazan correctamente datos inválidos.



  Entregables
Script de creación de base de datos y tablas (CREATE DATABASE / CREATE TABLE)
Relaciones con llaves foráneas (FOREIGN KEY)
Scripts con funciones, procedimientos y triggers (CREATE FUNCTION / PROCEDURE / TRIGGER)
Consultas SQL complejas (JOIN, subconsultas, operadores, agregaciones)
Vistas de reportes (CREATE VIEW)
Archivo README con:
Descripción del proyecto
Explicación de las tablas y relaciones
Ejemplos de consultas
Instrucciones para ejecutar el script