USE proyecto_piccolo;
DROP FUNCTION IF EXISTS fn_calcular_total_pedido;

DELIMITER $$
CREATE FUNCTION fn_calcular_total_pedido(
    p_id_pedido INT
)
RETURNS DECIMAL(10,2)
DETERMINISTIC
READS SQL DATA
BEGIN

    DECLARE v_subtotal DECIMAL(10,2) DEFAULT 0;
    DECLARE v_envio DECIMAL(10,2) DEFAULT 0;
    DECLARE v_total DECIMAL(10,2);
    -- Total de las pizzas
    SELECT IFNULL(SUM(subtotal),0)
    INTO v_subtotal
    FROM detalle_pedido
    WHERE id_pedido = p_id_pedido;
    -- Costo del domicilio
    SELECT IFNULL(te.costo_envio,0)
    INTO v_envio
    FROM domicilios d
    INNER JOIN tarifas_envio te
        ON d.id_tarifa = te.id_tarifa
    WHERE d.id_pedido = p_id_pedido;
    -- Total + IVA
    SET v_total = (v_subtotal + v_envio) * 1.19;
    RETURN ROUND(v_total,2);
END$$
DELIMITER ;

SELECT fn_calcular_total_pedido(1) AS total_calculado_pedido_1;


DELIMITER $$
CREATE FUNCTION fn_ganancia_neta_diaria(
    p_fecha DATE
)
RETURNS DECIMAL(10,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_ventas DECIMAL(10,2) DEFAULT 0;
    DECLARE v_costos DECIMAL(10,2) DEFAULT 0;
    -- Ventas del día
    SELECT IFNULL(SUM(total),0)
    INTO v_ventas
    FROM pedidos
    WHERE DATE(fecha_hora)=p_fecha
    AND estado='Entregado';
    -- Costo de ingredientes utilizados
    SELECT IFNULL(SUM(
        pi.cantidad_usada
        * dp.cantidad
        * i.costo_unitario
    ),0)
    INTO v_costos
    FROM pedidos p
        INNER JOIN detalle_pedido dp
            ON p.id_pedido=dp.id_pedido
        INNER JOIN pizza_ingredientes pi
            ON dp.id_pizza=pi.id_pizza
        INNER JOIN ingredientes i
            ON pi.id_ingrediente=i.id_ingrediente
    WHERE DATE(p.fecha_hora)=p_fecha
    AND p.estado='Entregado';
    RETURN ROUND(v_ventas-v_costos,2);
END$$
DELIMITER ;

SELECT fn_ganancia_neta_diaria('2026-07-01') AS ganancia_neta_del_dia;

DELIMITER $$
CREATE PROCEDURE sp_entregar_pedido(
    IN p_id_pedido INT
)
BEGIN
    UPDATE pedidos
    SET
        estado='Entregado',
        total=fn_calcular_total_pedido(p_id_pedido)
    WHERE id_pedido=p_id_pedido;
END$$
DELIMITER ;
 
CALL sp_entregar_pedido(4);


