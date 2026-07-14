USE pizzeria_db;

-- Resume de pedido por cliente 
CREATE VIEW vw_resumen_pedidos_clientes AS
SELECT
    c.id_cliente,
    c.nombre,
    COUNT(p.id_pedido) AS cantidad_pedidos,
    SUM(p.total) AS total_gastado
FROM clientes c
INNER JOIN pedidos p
    ON c.id_cliente = p.id_cliente
GROUP BY
    c.id_cliente,
    c.nombre;

SELECT * FROM vw_resumen_pedidos_clientes;

-- Desempeño de repartidores
CREATE VIEW vw_desempeno_repartidores AS
SELECT
    r.id_repartidor,
    r.nombre,
    r.zona_asignada,
    COUNT(d.id_domicilio) AS total_entregas,
    AVG(
        TIMESTAMPDIFF
        (
            MINUTE,
            d.hora_salida,
            d.hora_entrega
        )
    ) AS tiempo_promedio_minutos
FROM repartidores r
LEFT JOIN domicilios d
    ON r.id_repartidor=d.id_repartidor
WHERE d.hora_entrega IS NOT NULL
GROUP BY
    r.id_repartidor,
    r.nombre,
    r.zona_asignada;

SELECT * FROM vw_desempeno_repartidores;

-- Ingredientes con stock bajo
CREATE VIEW vw_stock_bajo AS
SELECT
    id_ingrediente,
    nombre,
    stock,
    stock_minimo,
    costo_unitario
FROM ingredientes
WHERE stock < stock_minimo;

SELECT * FROM vw_stock_bajo;