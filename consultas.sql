USE proyecto_piccolo;

-- Clientes con pedidos entre dos fechas
SELECT
    c.id_cliente,
    c.nombre,
    p.id_pedido,
    p.fecha_hora,
    p.total
FROM clientes c
INNER JOIN pedidos p
    ON c.id_cliente = p.id_cliente
WHERE DATE(p.fecha_hora) BETWEEN '2026-07-01' AND '2026-07-05'
ORDER BY p.fecha_hora;

-- Pizzas más vendidas
SELECT
    p.nombre,
    SUM(dp.cantidad) AS total_vendida
FROM pizzas p
INNER JOIN detalle_pedido dp
    ON p.id_pizza = dp.id_pizza
GROUP BY
    p.id_pizza,
    p.nombre
ORDER BY total_vendida DESC;

-- pedidos por repartidor
SELECT
    r.nombre AS repartidor,
    p.id_pedido,
    p.fecha_hora,
    p.estado
FROM repartidores r
INNER JOIN domicilios d
    ON r.id_repartidor = d.id_repartidor
INNER JOIN pedidos p
    ON d.id_pedido = p.id_pedido
ORDER BY
    r.nombre,
    p.fecha_hora;

-- Promedio de entrega por zona
SELECT
    r.zona_asignada,
    AVG(
        TIMESTAMPDIFF(
            MINUTE,
            d.hora_salida,
            d.hora_entrega
        )
    ) AS promedio_minutos
FROM repartidores r
INNER JOIN domicilios d
    ON r.id_repartidor = d.id_repartidor
WHERE d.hora_entrega IS NOT NULL
GROUP BY r.zona_asignada;

-- Clientes que gastaron más de un monto (Mas de 50k)
SELECT
    c.nombre,
    SUM(p.total) AS total_gastado
FROM clientes c
INNER JOIN pedidos p
    ON c.id_cliente = p.id_cliente
GROUP BY
    c.id_cliente,
    c.nombre
HAVING SUM(p.total) > 50000
ORDER BY total_gastado DESC;

-- Búsqueda de nombre de pizza
SELECT
    *
FROM pizzas
WHERE nombre LIKE '%Queso%';

-- Subconsulta para obtener clientes frecuentes
SELECT
    nombre
FROM clientes
WHERE id_cliente IN
(
    SELECT
        id_cliente
    FROM pedidos
    WHERE YEAR(fecha_hora) = 2026
      AND MONTH(fecha_hora) = 7
    GROUP BY id_cliente
    HAVING COUNT(*) > 5
);

