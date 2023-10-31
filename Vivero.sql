----------------------------------------------------------------------
-- Creación de tablas  --
----------------------------------------------------------------------

--- Crear la tabla Vivero
-- La tabla Vivero contiene información sobre los viveros, con un ID único para cada uno.
-- Para las coordenadas de longitud y latitud, se utiliza el tipo de datos NUMERIC(10, 6),
-- lo que permite almacenar hasta 10 dígitos en total, con hasta 6 dígitos después del punto decimal.
CREATE TABLE Vivero (
    ID SERIAL PRIMARY KEY,
    Nombre VARCHAR(255) NOT NULL,
    Direccion VARCHAR(255) NOT NULL UNIQUE,
    Telefono VARCHAR(15) NOT NULL UNIQUE,
    Longitud NUMERIC(10, 6) NOT NULL,
    Latitud NUMERIC(10, 6) NOT NULL
);


-- Crear la tabla Zona
-- La tabla Zona contiene información sobre las zonas asociadas a los viveros,
-- con una referencia al ID del vivero al que pertenece.
CREATE TABLE Zona (
    ID SERIAL PRIMARY KEY,
    Nombre VARCHAR(255) NOT NULL,
    Longitud NUMERIC(10, 6) NOT NULL,
    Latitud NUMERIC(10, 6) NOT NULL,
    ID_Vivero INT,
    FOREIGN KEY (ID_Vivero) REFERENCES Vivero(ID) ON DELETE CASCADE
);


-- Crear un índice único en las columnas Longitud y Latitud de la tablas
-- Con este índice único, la base de datos asegurará que no pueda haber dos filas
-- con la misma combinación de valores para Longitud y Latitud
CREATE UNIQUE INDEX idx_zona_longitud_latitud ON Zona (Longitud, Latitud);
CREATE UNIQUE INDEX idx_vivero_longitud_latitud ON Vivero (Longitud, Latitud);


-- Crear la tabla Producto
-- La tabla Producto contiene información sobre los productos disponibles en los viveros,
-- con una referencia al ID del vivero al que pertenece.
-- El precio de los productos se almacena como un valor numérico con dos decimales
-- El atributo Cantidad_Stock es calculado
CREATE TABLE Producto (
    ID SERIAL PRIMARY KEY,
    Nombre VARCHAR(255) NOT NULL,
    Precio NUMERIC(10, 2) NOT NULL,
    Cantidad_Stock INT DEFAULT NULL,
    ID_Vivero INT,
    FOREIGN KEY (ID_Vivero) REFERENCES Vivero(ID) ON DELETE CASCADE
);

-- Crear la tabla ProductoZona
-- La tabla ProductoZona establece una relación muchos a muchos entre productos y zonas,
-- con información sobre la cantidad de productos disponibles en cada zona.
CREATE TABLE ProductoZona (
    ID_Producto INT,
    ID_Zona INT,
    Cantidad INT NOT NULL,
    PRIMARY KEY (ID_Producto, ID_Zona),
    FOREIGN KEY (ID_Producto) REFERENCES Producto(ID) ON DELETE CASCADE,
    FOREIGN KEY (ID_Zona) REFERENCES Zona(ID) ON DELETE CASCADE
);


-- Crear el tipo enumerado para el atributo "PuestoActual" en la tabla Empleado y "Puesto" en la tabla EmpleadoZona
CREATE TYPE PuestoEnum AS ENUM ('Gerente', 'Supervisor', 'Vendedor', 'Cajero', 'Jardinero');


-- Crear la tabla Empleado
-- Contiene una referencia al ID del Vivero donde trabaja
-- Contiene una referencial ID de la Zona que se le ha asignado
-- El atributo PuestoActual es un enumerado
-- El atributo Productividad es calculado 
CREATE TABLE Empleado (
    DNI VARCHAR(15) PRIMARY KEY,
    Nombre VARCHAR(255) NOT NULL,
    Apellidos VARCHAR(255) NOT NULL,
    Direccion VARCHAR(255) NOT NULL,
    Telefono VARCHAR(15) NOT NULL UNIQUE,
    Fecha_Contratacion DATE NOT NULL,
    ID_Vivero INT,
    ID_Zona INT,
    PuestoActual PuestoEnum DEFAULT NULL,
    Productividad NUMERIC(5, 2) DEFAULT NULL,
    FOREIGN KEY (ID_Vivero) REFERENCES Vivero(ID) ON DELETE CASCADE,
    FOREIGN KEY (ID_Zona) REFERENCES Zona(ID) ON DELETE CASCADE
);

-- Crear la tabla EmpleadoZona
-- La tabla EmpleadoZona establece una relación muchos a muchos entre Empleado y Zona,
-- con información referente al trabajo de un empleado en una zona
-- Contiene una referencia al DNI del empleado y otra a la ID de la zona
-- El atributo Fecha_Fin puede ser null
-- El atributo Duracion es calculado
CREATE TABLE EmpleadoZona (
    DNI VARCHAR(15),
    ID_Zona INT,
    Puesto PuestoEnum,
    Productividad NUMERIC(5, 2) NOT NULL,
    Fecha_Inicio DATE NOT NULL,
    Fecha_Fin DATE DEFAULT NULL,
    Duracion INTERVAL DEFAULT NULL,
    PRIMARY KEY (DNI, ID_Zona),
    FOREIGN KEY (DNI) REFERENCES Empleado(DNI) ON DELETE CASCADE,
    FOREIGN KEY (ID_Zona) REFERENCES Zona(ID) ON DELETE CASCADE
);


-- Crear la tabla Cliente
CREATE TABLE Cliente (
    DNI VARCHAR(15) PRIMARY KEY,
    Nombre VARCHAR(255) NOT NULL,
    Apellidos VARCHAR(255) NOT NULL,
    Telefono VARCHAR(15) NOT NULL UNIQUE,
    Plus BOOLEAN NOT NULL
);

-- Crear la tabla ClientePlus
-- Representa un cliente que se ha afiliado al programa Tajinaste Plus
-- Contiene una referencia al DNI del cliente
CREATE TABLE ClientePlus (
    ID VARCHAR(15) PRIMARY KEY,
    Volumen_Compra_Mensual NUMERIC(10, 2) NOT NULL,
    Fecha_Afiliacion DATE NOT NULL,
    FOREIGN KEY (ID) REFERENCES Cliente(DNI) ON DELETE CASCADE
);

-- Crear la tabla Pedido
-- La tabla Pedido establece una relación muchos a muchos entre Empleado, Cliente y Producto,
-- con información que describe la realización de un pedido
-- Contiene una referencia al DNI del cliente, otra al DNI del empleado y una referencia al ID de la zona
-- El atributo PrecioProducto es calculado
-- El atributo PrecioTotal es calculado
CREATE TABLE Pedido (
    DNI_Cliente VARCHAR(15),
    DNI_Empleado VARCHAR(15),
    ID_Producto INT,
    Fecha DATE NOT NULL,
    Descuento NUMERIC(5, 2) NOT NULL,
    PrecioProducto NUMERIC(10, 2) DEFAULT NULL,
    PrecioTotal NUMERIC(10, 2) DEFAULT NULL,
    FOREIGN KEY (DNI_Cliente) REFERENCES Cliente(DNI) ON DELETE CASCADE,
    FOREIGN KEY (DNI_Empleado) REFERENCES Empleado(DNI) ON DELETE CASCADE,
    FOREIGN KEY (ID_Producto) REFERENCES Producto(ID) ON DELETE CASCADE
);


----------------------------------------------------------------------
-- Vistas
----------------------------------------------------------------------

-- Vista que recoge para cada DNI la fila con el atributo Fecha_Inicio más reciente
CREATE VIEW VistaEmpleadoZona AS
SELECT DISTINCT ON (DNI)
    DNI,
    ID_Zona,
    Puesto,
    Productividad,
    Fecha_Inicio,
    Fecha_Fin,
    Duracion
FROM EmpleadoZona
ORDER BY DNI, ABS(Fecha_Inicio - CURRENT_DATE), Fecha_Inicio DESC;

-- Vista que selecciona para cada empleado su productividad total
CREATE VIEW VistaProductividadTotal AS
SELECT e.DNI, e.Nombre, e.Apellidos,
       SUM(ez.Productividad) / COUNT(ez.ID_Zona) AS Productividad
FROM Empleado e
JOIN EmpleadoZona ez ON e.DNI = ez.DNI
GROUP BY e.DNI, e.Nombre, e.Apellidos;


----------------------------------------------------------------------
-- Funciones --
----------------------------------------------------------------------

-- Función que actualiza el atributo Cantidad_Stock de la tabla Producto
CREATE OR REPLACE FUNCTION actualizarCantidadStock()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE Producto p
    SET Cantidad_Stock = (
        SELECT SUM(pz.Cantidad)
        FROM ProductoZona pz
        WHERE pz.ID_Producto = NEW.ID_Producto
    )
    WHERE p.ID = NEW.ID_Producto;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Función que actualiza el atributo PuestoActual de la tabla Empleado
CREATE OR REPLACE FUNCTION calcularPuestoActual()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE Empleado e
    SET PuestoActual = (
        SELECT Puesto
        FROM VistaEmpleadoZona vez
        WHERE vez.DNI = NEW.DNI
    )
    WHERE e.DNI = NEW.DNI;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Función que actualiza el atributo Productividad de la tabla Empleado
CREATE OR REPLACE FUNCTION calcularProductividadTotal()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE Empleado e
    SET Productividad = (
        SELECT Productividad
        FROM VistaProductividadTotal vpt
        WHERE vpt.DNI = NEW.DNI
    )
    WHERE e.DNI = NEW.DNI;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Función que actualiza el atributo PrecioProducto de la tabla Pedido
CREATE OR REPLACE FUNCTION actualizarPrecioProducto()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE Pedido p
  SET PrecioProducto = (
    SELECT Precio FROM Producto WHERE ID = NEW.ID_Producto
  )
  WHERE p.ID_Producto = NEW.ID_Producto 
  AND (p.PrecioProducto IS NULL OR p.PrecioProducto <> NEW.PrecioProducto); -- Solo actualiza si PrecioProducto es NULL en Pedido
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Función que actualiza el atributo Duracion de la tabla EmpleadoZona
CREATE OR REPLACE FUNCTION calcularDuracion()
RETURNS TRIGGER AS $$
BEGIN
  NEW.Duracion := 
    CASE 
      WHEN NEW.Fecha_Fin IS NOT NULL THEN NEW.Fecha_Fin - NEW.Fecha_Inicio
      ELSE current_date - NEW.Fecha_Inicio
    END;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Función que actualiza el atributo PrecioTotal de la tabla Pedido
CREATE OR REPLACE FUNCTION calcularPrecioTotal()
RETURNS TRIGGER AS $$
BEGIN
    NEW.PrecioTotal := NEW.PrecioProducto - NEW.Descuento;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


----------------------------------------------------------------------
-- Disparadores --
----------------------------------------------------------------------

-- Crear el trigger para actualizar el atributo Cantidad_Stock
CREATE TRIGGER actualizarCantidadStockTrigger
AFTER INSERT OR UPDATE ON ProductoZona
FOR EACH ROW
EXECUTE FUNCTION actualizarCantidadStock();

-- Crear el trigger para actualizar el atributo PuestoActual
CREATE TRIGGER actualizarPuestoActualTrigger
AFTER INSERT OR UPDATE ON EmpleadoZona
FOR EACH ROW
EXECUTE FUNCTION calcularPuestoActual();

-- Crear el trigger para actualizar el atributo Productividad de la tabla Empleado
CREATE TRIGGER actualizarProductividadTotalTrigger
AFTER INSERT OR UPDATE ON EmpleadoZona
FOR EACH ROW
EXECUTE FUNCTION calcularProductividadTotal();

-- Crear el trigger para actualizar el atributo PrecioProducto
CREATE TRIGGER actualizarPrecioProductoTrigger
AFTER INSERT OR UPDATE ON Pedido
FOR EACH ROW
EXECUTE FUNCTION actualizarPrecioProducto();

-- Crear el trigger para actualizar el atributo Duracion
CREATE TRIGGER calcularDuracionTrigger
BEFORE INSERT OR UPDATE ON EmpleadoZona
FOR EACH ROW EXECUTE FUNCTION calcularDuracion();

-- Crear el trigger para actualizar el atributo PrecioTotal
CREATE TRIGGER calcularPrecioTotalTrigger
BEFORE INSERT OR UPDATE ON Pedido
FOR EACH ROW EXECUTE FUNCTION calcularPrecioTotal();


----------------------------------------------------------------------
-- Inserciones de ejemplo --
----------------------------------------------------------------------

-- Insertar datos en la tabla Vivero
INSERT INTO Vivero (Nombre, Direccion, Telefono, Longitud, Latitud)
VALUES
    ('Vivero A', 'Dirección A', '123456789', -75.123456, 40.123456),
    ('Vivero B', 'Dirección B', '987654321', -75.654321, 40.654321),
    ('Vivero C', 'Dirección C', '111223344', -75.111111, 40.111111),
    ('Vivero D', 'Dirección D', '999888777', -75.999999, 40.999999),
    ('Vivero E', 'Dirección E', '333222111', -75.333333, 40.333333);

-- Insertar datos en la tabla Zona
INSERT INTO Zona (Nombre, Longitud, Latitud, ID_Vivero)
VALUES
    ('Zona 1', -75.123457, 40.123457, 1),
    ('Zona 2', -75.654322, 40.654322, 2),
    ('Zona 3', -75.111112, 40.111112, 3),
    ('Zona 4', -75.999998, 40.999998, 4),
    ('Zona 5', -75.333334, 40.333334, 5);

-- Insertar datos en la tabla Producto
INSERT INTO Producto (Nombre, Precio, ID_Vivero)
VALUES
    ('Producto 1', 10.99, 1),
    ('Producto 2', 5.99, 2),
    ('Producto 3', 7.49, 3),
    ('Producto 4', 12.79, 4),
    ('Producto 5', 8.99, 5);


-- Insertar datos en la tabla ProductoZona
INSERT INTO ProductoZona (ID_Producto, ID_Zona, Cantidad)
VALUES
    (1, 1, 50),
    (2, 2, 70),
    (3, 3, 60),
    (4, 4, 90),
    (5, 5, 40);

-- Insertar datos en la tabla Empleado
INSERT INTO Empleado (DNI, Nombre, Apellidos, Direccion, Telefono, Fecha_Contratacion, ID_Vivero, ID_Zona)
VALUES
    ('123456789A', 'Empleado 1', 'Apellido1 Apellido2', 'Direccion 1', '111222333', '2020-01-01', 1, 1),
    ('987654321B', 'Empleado 2', 'Apellido3 Apellido4', 'Direccion 2', '444555666', '2019-05-15', 2, 2),
    ('111223344C', 'Empleado 3', 'Apellido1 Apellido2', 'Direccion 3', '777888999', '2021-03-10', 3, 3),
    ('999888777D', 'Empleado 4', 'Apellido3 Apellido4', 'Direccion 4', '222333444', '2018-11-20', 4, 4),
    ('333222111E', 'Empleado 5', 'Apellido5 Apellido6', 'Direccion 5', '555666777', '2022-02-28', 5, 5);

-- Insertar datos en la tabla EmpleadoZona
INSERT INTO EmpleadoZona (DNI, ID_Zona, Puesto, Productividad, Fecha_Inicio, Fecha_Fin)
VALUES
    ('123456789A', 1, 'Cajero', 0.85, '2020-01-01', '2020-01-31'),
    ('987654321B', 2, 'Vendedor', 0.78, '2019-05-15', '2019-12-31'),
    ('111223344C', 3, 'Gerente', 0.92, '2021-03-10', '2021-12-31'),
    ('999888777D', 4, 'Supervisor', 0.50, '2018-11-20', '2018-12-31');

INSERT INTO EmpleadoZona (DNI, ID_Zona, Puesto, Productividad, Fecha_Inicio)
VALUES
    ('999888777D', 3, 'Supervisor', 0.90, '2019-11-20');

-- Insertar datos en la tabla Cliente
INSERT INTO Cliente (DNI, Nombre, Apellidos, Telefono, Plus)
VALUES
    ('111111111A', 'Cliente 1', 'Apellido1 Apellido2', '999111222', TRUE),
    ('222222222B', 'Cliente 2', 'Apellido3 Apellido4', '888222333', FALSE),
    ('333333333C', 'Cliente 3', 'Apellido4 Apellido3', '777333444', TRUE),
    ('444444444D', 'Cliente 4', 'Apellido1 Apellido2', '666444555', FALSE),
    ('555555555E', 'Cliente 5', 'Apellido2 Apellido1', '555555666', TRUE);


-- Insertar datos en la tabla ClientePlus
INSERT INTO ClientePlus (ID, Volumen_Compra_Mensual, Fecha_Afiliacion)
VALUES
    ('111111111A', 150.50, '2021-01-15'),
    ('333333333C', 200.75, '2022-03-20'),
    ('555555555E', 180.25, '2021-09-10');

-- Insertar datos en la tabla Pedido
INSERT INTO Pedido (DNI_Cliente, DNI_Empleado, ID_Producto, Fecha, Descuento)
VALUES
    ('111111111A', '123456789A', 1, '2023-10-30', 4.50),
    ('222222222B', '987654321B', 2, '2023-10-31', 5.25),
    ('333333333C', '111223344C', 3, '2023-11-01', 0),
    ('444444444D', '999888777D', 4, '2023-11-02', 2.00),
    ('555555555E', '333222111E', 5, '2023-11-03', 5.00);
