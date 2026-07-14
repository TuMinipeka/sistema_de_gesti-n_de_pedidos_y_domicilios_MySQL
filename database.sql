DROP DATABASE IF EXISTS pizzeria_db;
CREATE DATABASE pizzeria_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE pizzeria_db;

CREATE TABLE clientes (
    id_cliente          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    nombre              VARCHAR(100) NOT NULL,
    telefono            VARCHAR(20)  NULL,
    direccion           VARCHAR(255) NULL,
    correo_electronico  VARCHAR(100) NOT NULL,
    PRIMARY KEY (id_cliente),
    UNIQUE KEY clientes_correo_electronico_unique (correo_electronico)
) ENGINE=InnoDB;


CREATE TABLE pizzas (
    id_pizza     INT UNSIGNED NOT NULL AUTO_INCREMENT,
    nombre       VARCHAR(100) NOT NULL,
    tamaño       ENUM('Pequeña', 'Mediana', 'Grande') NOT NULL,
    precio_base  DECIMAL(10, 2) NOT NULL,
    tipo         ENUM('Vegetariana', 'Especial', 'Clásica') NOT NULL,
    disponible   BOOLEAN NOT NULL DEFAULT TRUE,
    PRIMARY KEY (id_pizza)
) ENGINE=InnoDB;


CREATE TABLE ingredientes (
    id_ingrediente   INT UNSIGNED NOT NULL AUTO_INCREMENT,
    nombre           VARCHAR(100) NOT NULL,
    stock            INT NOT NULL DEFAULT 0,
    stock_minimo     INT NOT NULL DEFAULT 10,
    costo_unitario   DECIMAL(10, 2) NOT NULL,
    PRIMARY KEY (id_ingrediente),
    CONSTRAINT chk_ingredientes_stock CHECK (stock >= 0),
    CONSTRAINT chk_ingredientes_stock_minimo CHECK (stock_minimo >= 0)
) ENGINE=InnoDB;

CREATE TABLE pizza_ingredientes (
    id_pizza_ingrediente  INT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_pizza              INT UNSIGNED NOT NULL,
    id_ingrediente        INT UNSIGNED NOT NULL,
    cantidad_usada        INT NOT NULL DEFAULT 1,
    PRIMARY KEY (id_pizza_ingrediente),
    UNIQUE KEY pizza_ingredientes_pizza_ingrediente_unique (id_pizza, id_ingrediente),
    CONSTRAINT chk_pizza_ingredientes_cantidad CHECK (cantidad_usada > 0),
    CONSTRAINT pizza_ingredientes_id_pizza_foreign
        FOREIGN KEY (id_pizza) REFERENCES pizzas (id_pizza)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT pizza_ingredientes_id_ingrediente_foreign
        FOREIGN KEY (id_ingrediente) REFERENCES ingredientes (id_ingrediente)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;


CREATE TABLE repartidores (
    id_repartidor   INT UNSIGNED NOT NULL AUTO_INCREMENT,
    nombre          VARCHAR(100) NOT NULL,
    zona_asignada   VARCHAR(50) NULL,
    estado          ENUM('Disponible', 'No disponible') NOT NULL DEFAULT 'Disponible',
    PRIMARY KEY (id_repartidor)
) ENGINE=InnoDB;


CREATE TABLE tarifas_envio (
    id_tarifa       INT UNSIGNED NOT NULL AUTO_INCREMENT,
    zona            VARCHAR(50) NOT NULL,
    distancia_min   DECIMAL(5, 2) NOT NULL,
    distancia_max   DECIMAL(5, 2) NOT NULL,
    costo_envio     DECIMAL(10, 2) NOT NULL,
    PRIMARY KEY (id_tarifa),
    CONSTRAINT chk_tarifas_distancia CHECK (distancia_max >= distancia_min)
) ENGINE=InnoDB;

--
CREATE TABLE pedidos (
    id_pedido     INT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_cliente    INT UNSIGNED NOT NULL,
    fecha_hora    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    metodo_pago   ENUM('Efectivo', 'Tarjeta', 'App') NOT NULL,
    estado        ENUM('Pendiente', 'En preparación', 'Entregado', 'Cancelado') NOT NULL DEFAULT 'Pendiente',
    total         DECIMAL(10, 2) NOT NULL DEFAULT 0,
    PRIMARY KEY (id_pedido),
    CONSTRAINT pedidos_id_cliente_foreign
        FOREIGN KEY (id_cliente) REFERENCES clientes (id_cliente)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;


CREATE TABLE detalle_pedido (
    id_detalle   INT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_pedido    INT UNSIGNED NOT NULL,
    id_pizza     INT UNSIGNED NOT NULL,
    cantidad     INT NOT NULL DEFAULT 1,
    subtotal     DECIMAL(10, 2) NOT NULL DEFAULT 0,
    PRIMARY KEY (id_detalle),
    CONSTRAINT chk_detalle_pedido_cantidad CHECK (cantidad >= 1),
    CONSTRAINT detalle_pedido_id_pedido_foreign
        FOREIGN KEY (id_pedido) REFERENCES pedidos (id_pedido)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT detalle_pedido_id_pizza_foreign
        FOREIGN KEY (id_pizza) REFERENCES pizzas (id_pizza)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;


CREATE TABLE domicilios (
    id_domicilio   INT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_pedido      INT UNSIGNED NOT NULL,
    id_repartidor  INT UNSIGNED NOT NULL,
    id_tarifa      INT UNSIGNED NOT NULL,
    hora_salida    DATETIME NULL,
    hora_entrega   DATETIME NULL,
    distancia      DECIMAL(5, 2) NOT NULL COMMENT 'Distancia en kilómetros',
    PRIMARY KEY (id_domicilio),
    UNIQUE KEY domicilios_id_pedido_unique (id_pedido),
    CONSTRAINT domicilios_id_pedido_foreign
        FOREIGN KEY (id_pedido) REFERENCES pedidos (id_pedido)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT domicilios_id_repartidor_foreign
        FOREIGN KEY (id_repartidor) REFERENCES repartidores (id_repartidor)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT domicilios_id_tarifa_foreign
        FOREIGN KEY (id_tarifa) REFERENCES tarifas_envio (id_tarifa)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;


CREATE TABLE historial_precios (
    id_historial      INT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_pizza          INT UNSIGNED NOT NULL,
    precio_anterior   DECIMAL(10, 2) NULL,
    precio_nuevo      DECIMAL(10, 2) NULL,
    fecha_cambio      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_historial),
    CONSTRAINT historial_precios_id_pizza_foreign
        FOREIGN KEY (id_pizza) REFERENCES pizzas (id_pizza)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;


INSERT INTO clientes (nombre, telefono, direccion, correo_electronico) VALUES
('Laura Gómez',      '3001234567', 'Cra 15 #45-20, Bucaramanga',        'laura.gomez@mail.com'),
('Carlos Ramírez',   '3012345678', 'Calle 30 #12-10, Floridablanca',    'carlos.ramirez@mail.com'),
('Ana Martínez',     '3023456789', 'Cra 27 #56-30, Bucaramanga',        'ana.martinez@mail.com'),
('Jorge Pérez',      '3034567890', 'Calle 45 #10-05, Girón',            'jorge.perez@mail.com'),
('María Fernández',  '3045678901', 'Cra 33 #22-18, Floridablanca',      'maria.fernandez@mail.com');


INSERT INTO pizzas (nombre, tamaño, precio_base, tipo, disponible) VALUES
('Margarita',        'Mediana', 22000.00, 'Clásica',      TRUE),
('Hawaiana',         'Grande',  28000.00, 'Clásica',      TRUE),
('Vegetariana Deluxe','Grande', 30000.00, 'Vegetariana',  TRUE),
('Cuatro Quesos',    'Mediana', 26000.00, 'Especial',     TRUE),
('Pepperoni',        'Pequeña', 18000.00, 'Clásica',      TRUE);


INSERT INTO ingredientes (nombre, stock, stock_minimo, costo_unitario) VALUES
('Queso mozzarella', 50, 10, 5000.00),
('Salsa de tomate',  40, 10, 2000.00),
('Piña',             20,  5, 1500.00),
('Jamón',            25,  5, 4000.00),
('Pepperoni',        30,  8, 4500.00),
('Champiñón',        15,  5, 2500.00);


INSERT INTO pizza_ingredientes (id_pizza, id_ingrediente, cantidad_usada) VALUES
(1, 1, 2), (1, 2, 1),                       -- Margarita
(2, 1, 2), (2, 2, 1), (2, 3, 1), (2, 4, 1), -- Hawaiana
(3, 1, 2), (3, 2, 1), (3, 6, 2),            -- Vegetariana Deluxe
(4, 1, 3), (4, 2, 1),                       -- Cuatro Quesos
(5, 1, 2), (5, 2, 1), (5, 5, 2);            -- Pepperoni


INSERT INTO repartidores (nombre, zona_asignada, estado) VALUES
('Andrés Torres',   'Norte',    'Disponible'),
('Diego Salazar',   'Sur',      'Disponible'),
('Felipe Rojas',    'Centro',   'No disponible');


INSERT INTO tarifas_envio (zona, distancia_min, distancia_max, costo_envio) VALUES
('Norte',  0.00, 3.00, 3000.00),
('Sur',    0.00, 5.00, 4000.00),
('Centro', 0.00, 2.00, 2500.00);


INSERT INTO pedidos (id_cliente, fecha_hora, metodo_pago, estado, total) VALUES
(1, '2026-07-01 12:30:00', 'Efectivo', 'Entregado',      50000.00),
(2, '2026-07-02 19:15:00', 'Tarjeta',  'Entregado',      33000.00),
(3, '2026-07-03 20:05:00', 'App',      'En preparación', 30000.00),
(1, '2026-07-05 13:00:00', 'Tarjeta',  'Pendiente',      26000.00),
(4, '2026-07-06 18:45:00', 'Efectivo', 'Cancelado',      18000.00),
(5, '2026-07-07 21:00:00', 'App',      'Entregado',      44000.00);

INSERT INTO detalle_pedido (id_pedido, id_pizza, cantidad, subtotal) VALUES
(1, 1, 1, 22000.00), (1, 5, 1, 18000.00),
(2, 2, 1, 28000.00),
(3, 3, 1, 30000.00),
(4, 4, 1, 26000.00),
(5, 5, 1, 18000.00),
(6, 2, 1, 28000.00), (6, 1, 1, 22000.00);



INSERT INTO domicilios (id_pedido, id_repartidor, id_tarifa, hora_salida, hora_entrega, distancia) VALUES
(1, 1, 1, '2026-07-01 12:40:00', '2026-07-01 13:05:00', 2.50),
(2, 2, 2, '2026-07-02 19:25:00', '2026-07-02 19:50:00', 3.80),
(3, 3, 3, '2026-07-03 20:15:00', NULL,                  1.20),
(6, 1, 1, '2026-07-07 21:10:00', '2026-07-07 21:35:00', 2.00);

INSERT INTO historial_precios (id_pizza, precio_anterior, precio_nuevo, fecha_cambio) VALUES
(1, 20000.00, 22000.00, '2026-06-15 09:00:00'),
(3, 28000.00, 30000.00, '2026-06-20 09:00:00');