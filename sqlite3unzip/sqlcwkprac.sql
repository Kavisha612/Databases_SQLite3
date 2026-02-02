/*@author Kavisha Gupta */


DROP VIEW IF EXISTS vNoCustomerEmployee;
DROP VIEW IF EXISTS v10MostSoldMusicGenres;
DROP VIEW IF EXISTS vTopAlbumEachGenre;
DROP VIEW IF EXISTS v20TopSellingArtists;
DROP VIEW IF EXISTS vTopCustomerEachGenre;

CREATE VIEW vNoCustomerEmployee AS
SELECT  

    emp.EmployeeId AS EmployeeId, 
    emp.FirstName AS FirstName, 
    emp.LastName AS LastName, 
    emp.Title AS Title
    
FROM 
employees emp

WHERE 
emp.EmployeeID NOT IN (
    SELECT 
    cus.SupportRepId
    FROM 
    customers cus 
);


CREATE VIEW v10MostSoldMusicGenres AS
SELECT
gen.Name AS Genre, 
SUM(tq.Quantity) AS Sales

FROM 
genres gen

JOIN tracks tr 
ON gen.GenreID = tr.GenreID

JOIN invoice_items tq 
ON tr.TrackID = tq.TrackID

GROUP BY gen.Name

ORDER BY Sales DESC

Limit 10;


CREATE VIEW vTopAlbumEachGenre AS
SELECT DISTINCT
gen.Name AS Genre,
FIRST_VALUE(alb.Title) OVER (PARTITION BY gen.GenreId ORDER BY COUNT(*) DESC) AS Album,
art.Name AS Artist,
SUM(aq.Quantity) AS Sales
FROM 
genres gen

INNER JOIN tracks t ON t.GenreId = gen.GenreId
INNER JOIN albums alb ON alb.AlbumId = t.AlbumId
INNER JOIN artists art ON art.ArtistId = alb.ArtistId
INNER JOIN invoice_items aq ON aq.TrackId = t.TrackId
GROUP BY gen.Name, alb.AlbumId, art.ArtistId


HAVING SUM(aq.Quantity) = (
    SELECT MAX(sales) 
    FROM (SELECT SUM(aq2.Quantity) AS Sales
            FROM invoice_items aq2
            INNER JOIN tracks t2 ON t2.TrackId = aq2.TrackId
            INNER JOIN albums alb2 ON alb2.AlbumId = t2.AlbumId
            WHERE t2.GenreId = t.GenreId
            GROUP BY alb2.AlbumId
            ) AS top_sales);

CREATE VIEW v20TopSellingArtists AS
SELECT 
art.Name AS Artist,
COUNT(DISTINCT alb.AlbumId) AS TotalAlbum,
SUM(traq.Quantity) AS TrackSold
FROM 
    artists art

INNER JOIN 
    albums alb ON art.ArtistId =  alb.ArtistId
INNER JOIN 
    tracks t ON alb.AlbumId = t.AlbumId
INNER JOIN 
    invoice_items traq ON t.TrackId = traq.TrackId
GROUP BY 
    art.ArtistId, art.Name

ORDER BY TrackSold DESC,TotalAlbum ASC, Artist DESC
Limit 20;



CREATE VIEW vTopCustomerEachGenre AS
SELECT DISTINCT
    gen.Name AS Genre,
    FIRST_VALUE(cus.FirstName || ' ' || cus.LastName) 
    OVER (PARTITION BY gen.Name ORDER BY ROUND(SUM(ii.Quantity * ii.UnitPrice), 2) DESC)
    AS TopSpender,
    FIRST_VALUE(ROUND(SUM(ii.Quantity * ii.UnitPrice), 2)) OVER (PARTITION BY gen.GenreId 
    ORDER BY ROUND(SUM(ii.Quantity * ii.UnitPrice), 2) DESC) AS TotalSpending

FROM
    genres gen
JOIN tracks t ON gen.GenreId = t.GenreId
JOIN invoice_items ii ON t.TrackId = ii.TrackId
JOIN invoices i ON ii.InvoiceId = i.InvoiceId
JOIN customers cus ON i.CustomerId = cus.CustomerId

GROUP BY Genre, cus.CustomerId, cus.FirstName
ORDER BY Genre;


SELECT * FROM vNoCustomerEmployee;
SELECT * FROM v10MostSoldMusicGenres;
SELECT * FROM vTopAlbumEachGenre;
SELECT * FROM v20TopSellingArtists;
SELECT * FROM vTopCustomerEachGenre;