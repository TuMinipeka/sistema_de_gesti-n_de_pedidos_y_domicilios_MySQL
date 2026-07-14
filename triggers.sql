USE pizzeria_db;

-- Actualizar el stock de ingredientes
DELIMITER $$
CREATE TRIGGER trg_actualizar_stock_ingredientes
AFTER INSERT ON detalle_pedido
FOR EACH ROW
BEGIN

    UPDATE ingredientes i
    INNER JOIN pizza_ingredientes pi
        ON i.id_ingrediente = pi.id_ingrediente
    SET i.stock = i.stock - (pi.cantidad_usada * NEW.cantidad)
    WHERE pi.id_pizza = NEW.id_pizza;

END$$
DELIMITER ;


-- Auditoría de precios (registra cualquier cambio de precio)
DELIMITER $$
CREATE TRIGGER trg_historial_precios
AFTER UPDATE ON pizzas
FOR EACH ROW
BEGIN
    IF OLD.precio_base <> NEW.precio_base THEN
        INSERT INTO historial_precios
        (
            id_pizza,
            precio_anterior,
            precio_nuevo,
            fecha_cambio
        )
        VALUES
        (
            NEW.id_pizza,
            OLD.precio_base,
            NEW.precio_base,
            NOW()
        );
    END IF;
END$$
DELIMITER ;


-- Repartidor disponible (El repartidor volvera a estar disponible despues q se registre 1 hora de entega
DELIMITER $$
CREATE TRIGGER trg_repartidor_disponible
AFTER UPDATE ON domicilios
FOR EACH ROW
BEGIN
    IF OLD.hora_entrega IS NULL
       AND NEW.hora_entrega IS NOT NULL THEN
        UPDATE repartidores
        SET estado = 'Disponible'
        WHERE id_repartidor = NEW.id_repartidor;
    END IF;
END$$
DELIMITER ;