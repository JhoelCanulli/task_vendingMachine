DROP TABLE IF EXISTS Maintenance;
DROP TABLE IF EXISTS Product_Supplier;
DROP TABLE IF EXISTS Supplier;
DROP TABLE IF EXISTS Transaction_;
DROP TABLE IF EXISTS Product;
DROP TABLE IF EXISTS VendingMachine;

CREATE TABLE VendingMachine(
	vendingMachineID INT PRIMARY KEY,
	posizione NVARCHAR(50) NOT NULL,
	modello NVARCHAR(50) NOT NULL,
);

CREATE TABLE Product(
	productID INT PRIMARY KEY,
	prod_disponibili INT NOT NULL DEFAULT 0,	-- [totale - acquistati]
	nome NVARCHAR(50) NOT NULL,
	prezzo FLOAT NOT NULL,
	quantita_stock INT NOT NULL DEFAULT 0,	-- quantità totale 
	VendingMachineRIF INT NOT NULL,
	FOREIGN KEY (VendingMachineRIF) REFERENCES VendingMachine(vendingMachineID)
);

CREATE TABLE Transaction_(
	transactionID INT PRIMARY KEY IDENTITY (1,1),
	data_ora DATETIME NOT NULL,
	importo FLOAT NOT NULL,
	VendingMachineRIF INT NOT NULL,
	ProductRIF INT NOT NULL,
	FOREIGN KEY (VendingMachineRIF) REFERENCES VendingMachine(vendingMachineID),
	FOREIGN KEY (ProductRIF) REFERENCES Product(productID)
);

CREATE TABLE Supplier(
	supplierID INT PRIMARY KEY,
	nome NVARCHAR(50) NOT NULL,
	dettagli_contatto NVARCHAR(50) NOT NULL,
);

CREATE TABLE Product_Supplier(
	ProductRIF INT NOT NULL,
	SupplierRIF INT NOT NULL,
	FOREIGN KEY (ProductRIF) REFERENCES Product(productID),
	FOREIGN KEY (SupplierRIF) REFERENCES Supplier(supplierID)
);

CREATE TABLE Maintenance(
	maintenanceID INT PRIMARY KEY,
	data_ora DATETIME NOT NULL,
	descrizione NVARCHAR(50),
	VendingMachineRIF INT NOT NULL,
	FOREIGN KEY (VendingMachineRIF) REFERENCES VendingMachine(vendingMachineID)
);

INSERT INTO VendingMachine(vendingMachineID, posizione, modello) VALUES
	(1, 'via brutti, 33', 'XYZ'),
	(2, 'via sporchi, 44', 'ABC'),
	(3, 'via cattivi, 55', 'RTF');

INSERT INTO Product(productID, prod_disponibili, nome, prezzo, quantita_stock, VendingMachineRIF) VALUES
	(1, 3, 'merendina', 3.50, 10, 1),
	(2, 4, 'acqua', 1, 10, 2),
	(3, 0, 'patatine', 2, 10, 3);

INSERT INTO Transaction_(transactionID, data_ora, importo, VendingMachineRIF, ProductRIF) VALUES
	(1, CONVERT(datetime, '2024-03-15 18:00:00', 120), 2, 2, 2),
	(2, CONVERT(datetime, '2024-03-15 20:00:00', 120), 2, 2, 2),
	(3, CONVERT(datetime, '2024-03-16 06:00:00', 120), 2, 3, 3),
	(4, CONVERT(datetime, '2024-03-17 20:00:00', 120), 3.50, 1, 1),
	(5, CONVERT(datetime, '2024-03-17 20:50:00', 120), 3.50, 1, 1),
	(6, CONVERT(datetime, '2024-03-17 20:50:00', 120), 3.50, 1, 1);

INSERT INTO Supplier(supplierID, nome, dettagli_contatto) VALUES
	(1, 'fornitori tal de tali', 'xxxx'),
	(2, 'fornitori pincopallini', 'yyyy');

INSERT INTO Product_Supplier(ProductRIF, SupplierRIF) VALUES
	(1, 1),
	(1, 2);

INSERT INTO Maintenance(maintenanceID, data_ora, descrizione, VendingMachineRIF) VALUES
    (1, CONVERT(datetime, '2024-03-10 18:00:00', 120), '13 bottiglie incastrate malissimo', 1),
    (2, CONVERT(datetime, '2024-03-11 09:00:00', 120), 'controllo', 1),
	(3, CONVERT(datetime, '2024-11-11 09:00:00', 120), 'controllo programmato', 1);

/*
 | ----------------------------------------------------------- |
 | ------------- Richieste di Creazione di Viste ------------- |
 | ----------------------------------------------------------- |
 
 * 
 * Creare una vista ProductsByVendingMachine che mostri tutti i prodotti disponibili
 * in ciascun distributore, includendo l'ID e la posizione del distributore, il nome del prodotto, 
 * il prezzo e la quantità disponibile
 */

CREATE VIEW ProductsByVendingMachine AS
	SELECT VendingMachine.vendingMachineID AS 'ID machine', VendingMachine.posizione AS 'posizione', Product.nome AS 'prodotto', Product.prezzo AS 'prezzo', Product.prod_disponibili AS 'disponibili' 
	FROM VendingMachine
	JOIN Product ON VendingMachine.vendingMachineID = Product.VendingMachineRIF

SELECT * FROM ProductsByVendingMachine;

-----------------------------------------------------------------------------------

/*
 * Generare una vista RecentTransactions che elenchi le ultime transazioni effettuate, 
 * mostrando l'ID della transazione, la data/ora, il distributore, il prodotto acquistato
 * e l'importo della transazione.
 */
CREATE VIEW RecentTransactions AS
	SELECT Transaction_.transactionID AS 'ID transaction', Transaction_.data_ora AS 'data', VendingMachine.modello AS 'distributore', Product.nome AS 'prodotto', Transaction_.importo AS 'importo'
	FROM VendingMachine 
	JOIN Transaction_ ON VendingMachine.vendingMachineID = Transaction_.VendingMachineRIF
	JOIN Product ON Transaction_.ProductRIF = Product.productID
	ORDER BY data_ora DESC
	OFFSET 0 ROWS
	FETCH NEXT 5 ROWS ONLY

SELECT * FROM RecentTransactions 

-----------------------------------------------------------------------------------

/*
 * Creare una vista ScheduleMaintenance che mostri tutti i distributori 
 * che hanno una manutenzione programmata, includendo l'ID e la posizione del distributore e la data
 * dell'ultima e della prossima manutenzione
 */

CREATE VIEW ScheduleMaintenance AS
	SELECT DISTINCT VendingMachine.vendingMachineID AS 'ID machine', VendingMachine.posizione AS 'posizione',
		(SELECT MAX(Maintenance.data_ora) 
		FROM Maintenance 
		WHERE Maintenance.VendingMachineRIF = VendingMachine.vendingMachineID AND Maintenance.data_ora <= GETDATE()) AS 'ultima manutenzione',
		(SELECT MIN(Maintenance.data_ora) 
		FROM Maintenance  
		WHERE Maintenance.VendingMachineRIF = VendingMachine.vendingMachineID AND Maintenance.data_ora > GETDATE()) AS 'manutenzione programmata'
	FROM VendingMachine 
	JOIN Maintenance ON VendingMachine.vendingMachineID = Maintenance.VendingMachineRIF

SELECT * FROM ScheduleMaintenance;

-----------------------------------------------------------------------------------

/*
 | ----------------------------------------------------------- |
 | ------- Richieste di Creazione di Stored Procedures ------- |
 | ----------------------------------------------------------- |
 * 
 * Implementare una stored procedure RefillProduct che consenta di aggiungere scorte 
 * di un prodotto specifico in un distributore, richiedendo l'ID del distributore, l'ID del prodotto
 * e la quantità da aggiungere
 */

ALTER PROCEDURE RefillProduct 
	@vendingMachineID INT,
	@productID INT,
	@quantita INT,
	@nome NVARCHAR(50),
	@prezzo FLOAT
AS
BEGIN
	IF EXISTS (SELECT 1 FROM Product
						WHERE productID = @productID AND VendingMachineRIF = @vendingMachineID)
	BEGIN
		UPDATE Product
		SET quantita_stock = quantita_stock + @quantita, 
			prod_disponibili = prod_disponibili + @quantita
		WHERE productID = @productID AND VendingMachineRIF = @vendingMachineID
	END
	ELSE
	BEGIN
		INSERT INTO Product(productID, nome, prezzo, quantita_stock, prod_disponibili, VendingMachineRIF) VALUES
		(@productID, @nome, @prezzo, @quantita, @quantita, @vendingMachineID);
	END
END;

EXEC RefillProduct 
	@vendingMachineID = 1, 
	@productID = 4, 
	@quantita = 5, 
	@nome = 'bibita', 
	@prezzo = 1.70;

SELECT * FROM Product

-----------------------------------------------------------------------------------

/*
 * Sviluppare una stored procedure RecordTransaction che registri una nuova transazione, 
 * includento l'ID del distributore, l'ID del prodotto e l'importo pagato, aggiornando
 * contemporaneamente la quantità disponibile del prodotto
 */
CREATE PROCEDURE RecordTransaction
	@vendingMachineID INT,
	@productID INT,
	@importo INT
AS
BEGIN
	IF EXISTS (SELECT 1 FROM Product
						WHERE productID = @productID AND VendingMachineRIF = @vendingMachineID)
	BEGIN
		UPDATE Product
		SET prod_disponibili = prod_disponibili - 1
		WHERE productID = @productID AND VendingMachineRIF = @vendingMachineID
		INSERT INTO Transaction_(data_ora, importo, VendingMachineRIF, ProductRIF) VALUES
		(GETDATE(), @importo, @vendingMachineID, @productID);
	END
	ELSE
	BEGIN
		PRINT 'prodotto: ' + CAST(@productID AS NVARCHAR(50)) + ' esaurito o non disponibile';
	END
END;

EXEC RecordTransaction
	@vendingMachineID = 1,
	@productID = 4,
	@importo = 1.70;

SELECT * FROM RecentTransactions 

-----------------------------------------------------------------------------------

/*
 * Implementare una stored procedure UpdateProductPrice che permetta di aggiornare il prezzo 
 * di un prodotto specifico, richiedendo l'ID del prodotto e il nuovo prezzo
 */

CREATE PROCEDURE UpdateProductPrice 
	@productID INT,
	@nuovo_prezzo FLOAT
AS
BEGIN
	IF EXISTS (SELECT 1 FROM Product	
						WHERE productID = @productID)
	BEGIN
		UPDATE Product
		SET prezzo = @nuovo_prezzo
		WHERE productID = @productID
	END
	ELSE
	BEGIN
		PRINT 'prodotto: ' + CAST(@productID AS NVARCHAR(50)) + ' non presente';
	END
END;

EXEC UpdateProductPrice 
	@productID = 2,
	@nuovo_prezzo = 1.30;

SELECT * FROM Product;