# 🍕 Descripción del examen

La Pizzería Don Piccolo desea mejorar el control de sus pedidos.

Cada pedido incluye información del cliente, las pizzas solicitadas, la fecha del pedido, el método de pago y el estado (pendiente, en preparación, entregado, cancelado).

Actualmente, el gerente necesita consultar, validar y actualizar los pedidos de manera más eficiente.

### 📖 Sobre el Examen

Tu tarea consiste en diseñar y consultar datos del módulo de pedidos para optimiza-r la gestión diaria de órdenes y estados.


Objetivo del examen
Modelar correctamente la tabla de pedidos, relacionarla con clientes y pizzas, y crear consultas SQL funcionales que permitan obtener información útil para la toma de decisiones.

## Estructura del proyecto

```
├── database.sql       -- Creación de la BD, tablas, llaves foráneas y datos de ejemplo
├── funciones.sql      -- Funciones almacenadas y procedimiento (CREATE FUNCTION / PROCEDURE)
├── triggers.sql       -- Triggers de auditoría y automatización (CREATE TRIGGER)
├── vistas.sql         -- Vistas de reportes (CREATE VIEW)
├── consultas.sql      -- Consultas SQL complejas (JOIN, subconsultas, agregaciones)
├── README.md
└── examen.md
```

Consultas implementadas:

# 1 Marcar repartidor como "No disponible" al asignarle un domicilio

```sql
DELIMITER $$
CREATE TRIGGER trg_repartidor_no_disponible
AFTER INSERT ON domicilios
FOR EACH ROW
BEGIN
    UPDATE repartidores
    SET estado = 'No disponible'
    WHERE id_repartidor = NEW.id_repartidor;
END$$
DELIMITER ;
```

# 2  Tendencia Detalle pizzas favoritas + Ingresos generados
```sql

SELECT
    p.nombre,
    p.tamaño,
    p.tipo,
    p.precio_base, 
    SUM(dp.cantidad) AS total_vendida,
    SUM(dp.subtotal) AS total_ingresos
FROM pizzas p
INNER JOIN detalle_pedido dp
    ON p.id_pizza = dp.id_pizza
GROUP BY
    p.id_pizza,
    p.nombre
ORDER BY total_vendida DESC;
```

# 3 Filtro de datos del cliente en caso de emergencia

```sql
SELECT
    c.nombre AS cliente,
    c.telefono,
    c.direccion,
    c.correo_electronico
FROM clientes c
WHERE c.nombre LIKE '%Carlos Ramir%';
```


# 4 Clientes que mas gastaron mas dinero en una pizza con un monto de 30000

```sql
SELECT
    c.nombre,
    pi.nombre AS pizza,
    SUM(p.total) AS total_gastado,
    p.metodo_pago
FROM clientes c
INNER JOIN pedidos p
    ON c.id_cliente = p.id_cliente
INNER JOIN pizzas pi
	ON p.id_cliente = pi.id_pizza
GROUP BY
    c.id_cliente,
    c.nombre
HAVING SUM(p.total) > 33000
ORDER BY total_gastado DESC;
```





