--DROP TABLE Buys;
--DROP TABLE Tickets;
--DROP TABLE Buyer;
--DROP TABLE Screenings;
--DROP TABLE Venues;
--DROP TABLE Films;
--DROP TABLE Directors;


create table Directors (
    DirectorID INT PRIMARY KEY, 
    phone_num VARCHAR(15), 
    fname CHAR(10), 
    lname CHAR(20)
);

create table Films (
    FilmID INT PRIMARY KEY, 
    Title CHAR(20),
    Genre CHAR(10), 
    release_year INT, 
    DirectorID INT,
    FOREIGN KEY (DirectorID) REFERENCES Directors(DirectorID)
);

create table Venues (
    VenueID INT PRIMARY KEY,
    venue_name CHAR(20),
    max_capacity INT,
    seats_left INT unique,
    address CHAR(25)
);

create table Screenings (
    ScreeningID INT PRIMARY KEY, 
    show_time FLOAT,                
    show_date VARCHAR(10),    
    FilmID INT,
    VenueID INT,
    FOREIGN KEY (FilmID) REFERENCES Films(FilmID)ON DELETE CASCADE,
    FOREIGN KEY (VenueID) REFERENCES Venues(VenueID) ON DELETE CASCADE
);

create table Buyer (
    BuyerID INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fname CHAR(10),
    lname CHAR(20),
    price_payed FLOAT CHECK (price_payed > 0)
);

create table Tickets (
    TicketID INT PRIMARY KEY,
    seat_Num INT unique,
    price FLOAT CHECK (price > 0),
    ScreeningID INT,
    BuyerID INT,
    FOREIGN KEY (ScreeningID) REFERENCES Screenings(ScreeningID) on delete cascade,
    FOREIGN KEY (BuyerID) REFERENCES Buyer(BuyerID)on delete set null
);

create table Buys (
    BuyerID INT,
    TicketID INT,
    date_purchased VARCHAR(10),       
    PRIMARY KEY (BuyerID, TicketID),
    FOREIGN KEY (BuyerID) REFERENCES Buyer(BuyerID)on delete set null,
    FOREIGN KEY (TicketID) REFERENCES Tickets(TicketID)on delete cascade
);

-- Trigger to Update Seats

--checks to see how many seats are left and updates the venues table on how many seats are left for that screening. this is an after insert
CREATE OR REPLACE TRIGGER how_many_seats
after INSERT ON Tickets
FOR EACH ROW
DECLARE
    seats_left INT;
BEGIN
    -- Get the current number of seats left
    SELECT seats_left INTO seats_left
    FROM Venues
    WHERE VenueID = (
        SELECT VenueID
        FROM Screenings
        WHERE ScreeningID = :NEW.ScreeningID
    );

    -- Check if there are seats available
    IF seats_left > 0 THEN
        -- Decrement the number of seats
        UPDATE Venues
        SET seats_left = seats_left - 1
        WHERE VenueID = (
            SELECT VenueID
            FROM Screenings
            WHERE ScreeningID = :NEW.ScreeningID
        );
    ELSE
        -- Raise an error if no seats are left
        RAISE_APPLICATION_ERROR(-20001, 'No seats left for this screening.');
    END IF;
END;
/

--this makes it so tickets cannot be lower than $10
CREATE OR REPLACE TRIGGER enforce_min_ticket_price
BEFORE INSERT ON Tickets
FOR EACH ROW
BEGIN
    IF :NEW.price < 10 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Ticket price must be at least $10.');
    END IF;
END;
/


CREATE OR REPLACE TRIGGER adjust_seats_on_cancel
AFTER DELETE ON Tickets
FOR EACH ROW
BEGIN
    -- Increment the number of seats left
    UPDATE Venues
    SET seats_left = seats_left + 1
    WHERE VenueID = (
        SELECT VenueID
        FROM Screenings
        WHERE ScreeningID = :OLD.ScreeningID
    );
END;
/

--this inserts our tickets purchased into the buys table with the buyer id, and date sold
CREATE OR REPLACE TRIGGER insert_into_buys
AFTER INSERT ON Tickets
FOR EACH ROW
BEGIN
    INSERT INTO Buys (BuyerID, TicketID, date_purchased)
    VALUES (:NEW.BuyerID, :NEW.TicketID, TO_CHAR(SYSDATE, 'YYYY-MM-DD'));
END;
/

--creates a veiw on screening revenue as the count of tickets sold and the sum of the revenue from the screenings table with tickets and venues left joined
CREATE OR REPLACE VIEW ScreeningRevenue AS
SELECT 
    s.ScreeningID,
    v.venue_name,
    COUNT(t.TicketID) AS total_tickets_sold,
    SUM(t.price) AS total_revenue
FROM 
    Screenings s
    LEFT JOIN Tickets t ON s.ScreeningID = t.ScreeningID
    LEFT JOIN Venues v ON s.VenueID = v.VenueID
GROUP BY 
    s.ScreeningID, v.venue_name;

--creates an index on show dates from screenings
CREATE INDEX idx_show_date ON Screenings (show_date);
--creates an index on film titles
CREATE INDEX idx_film_title ON Films (Title);

------------------------------------------------
--selects how many seats are left from every venue for each screening from venues and screenings
select v.seats_left
from venues v , screenings s
where v.venueID = s.venueid;

--gives you total revenue for each screening
SELECT * FROM ScreeningRevenue;

--give you total amount of tickest sold at each venue from venues
SELECT v.venue_name, COUNT(t.TicketID) AS total_tickets
FROM Venues v
LEFT JOIN Screenings s ON v.VenueID = s.VenueID
LEFT JOIN Tickets t ON s.ScreeningID = t.ScreeningID
GROUP BY v.venue_name;

--total revenue and screeningid from screenings with an left join of tickets on screening
SELECT s.ScreeningID, SUM(t.price) AS revenue
FROM Screenings s
LEFT JOIN Tickets t ON s.ScreeningID = t.ScreeningID
GROUP BY s.ScreeningID;

--shows the indexes that we are using on the film table from the user indexes
SELECT INDEX_NAME, TABLE_NAME, UNIQUENESS
FROM USER_INDEXES
WHERE TABLE_NAME = 'FILMS';

--some test queries

--gives screening id, film title, venues and show dates and time from screenings table with films and venue joined
SELECT s.ScreeningID, f.Title AS Film, v.venue_name AS Venue, s.show_date, s.show_time
FROM Screenings s
JOIN Films f ON s.FilmID = f.FilmID
JOIN Venues v ON s.VenueID = v.VenueID;

--give buyerID, first name, last name, ticket id and price each buyer payed from buyer table
SELECT b.BuyerID, b.fname AS FirstName, b.lname AS LastName, t.TicketID, t.price
FROM Buyer b
LEFT JOIN Tickets t ON b.BuyerID = t.BuyerID;

--gives ticket id, seat num, and price from tickets table
SELECT t.TicketID, t.seat_Num, t.price
FROM Tickets t
WHERE t.ScreeningID = 1;

--gives title, genre, and release year of films with director id 1
SELECT f.Title, f.Genre, f.release_year
FROM Films f
WHERE f.DirectorID = 1;

--gives screening id, total tickets and total revenue from screenings with a left join of tickets, count total tickets for how many sold, and a sum for revenue 
SELECT s.ScreeningID, COUNT(t.TicketID) AS TotalTickets, SUM(t.price) AS TotalRevenue
FROM Screenings s
LEFT JOIN Tickets t ON s.ScreeningID = t.ScreeningID
GROUP BY s.ScreeningID;

--gives venue name, and total revenue from that venue using venues, left joined of screenings and tickets. sum of the price as revenue from tickets table
SELECT v.venue_name, SUM(t.price) AS TotalRevenue
FROM Venues v
LEFT JOIN Screenings s ON v.VenueID = s.VenueID
LEFT JOIN Tickets t ON s.ScreeningID = t.ScreeningID
GROUP BY v.venue_name;

--gives screening id, total revenue from tickets table which is left joined to screenings and ordered in descending order of total revenue
SELECT s.ScreeningID, SUM(t.price) AS TotalRevenue
FROM Screenings s
LEFT JOIN Tickets t ON s.ScreeningID = t.ScreeningID
GROUP BY s.ScreeningID
ORDER BY TotalRevenue DESC;

--constraints

--should say tickets must be at least $10
INSERT INTO Tickets (TicketID, seat_Num, price, ScreeningID, BuyerID)
VALUES (6, 10, 5.00, 1, 1);

--returns all the revenue from screenings and how many tickets were sold
SELECT * FROM ScreeningRevenue;


--performance testing
--done by chatGPT, to help me understand the efficiency of my indexes
EXPLAIN PLAN FOR
SELECT * FROM Screenings WHERE show_date = '11-01-2024';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

EXPLAIN PLAN FOR
SELECT * FROM Films WHERE Title = 'Go';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

--gives screning id, ticket id, buyers f and l name with the price they payed
SELECT s.ScreeningID, t.TicketID, b.fname AS BuyerFirstName, b.lname AS BuyerLastName, t.price
FROM Screenings s
LEFT JOIN Tickets t ON s.ScreeningID = t.ScreeningID
LEFT JOIN Buyer b ON t.BuyerID = b.BuyerID;

--should show nothing as there is no venue named home
SELECT b.fname, b.lname, v.venue_name
FROM Buyer b
JOIN Tickets t ON b.BuyerID = t.BuyerID
JOIN Screenings s ON t.ScreeningID = s.ScreeningID
JOIN Venues v ON s.VenueID = v.VenueID
WHERE v.venue_name = 'Home';


--sample data
--directors
insert into directors values(1, '123-456-7890', 'John', 'Smith');
insert into directors values(2, '234-567-8901', 'Jane', 'Doe');
insert into directors values(3, '345-678-9012', 'Steven', 'Spielberg');

--films table
insert into films values(1, 'Inception', 'Sci-Fi', 2010, 1);
insert into films values(2, 'Titanic', 'Romance', 1997, 2);
insert into films values(3, 'Jurassic Park', 'Adventure', 1993, 3);
insert into films values(4, 'The Matrix', 'Action', 1999, 1);

--venues table
insert into venues values(1, 'Cinema One', 200, 200, '123 Main St');
insert into venues values(2, 'The Grand Theater', 150, 150, '456 Elm St');
insert into venues values(3, 'Downtown Cinema', 300, 300, '789 Oak St');

--screenings table
insert into screenings values(1, 14.00, '2024-12-01', 1, 1);
insert into screenings values(2, 17.30, '2024-12-01', 2, 2);
insert into screenings values(3, 20.00, '2024-12-02', 3, 3);
insert into screenings values(4, 18.00, '2024-12-03', 4, 1);

select * from buyer;
--buyers
insert into buyer(fname,lname,price_payed) values('Alice', 'Johnson', 45.00);
insert into buyer(fname,lname,price_payed) values('Bob', 'Smith', 50.00);
insert into buyer(fname,lname,price_payed) values('Charlie', 'Brown', 60.00);
insert into buyer(fname,lname,price_payed) values('Daisy', 'Miller', 70.00);

--tickets table
insert into tickets values(1, 101, 15.00, 1, 1);
insert into tickets values(2, 102, 20.00, 1, 2);
insert into tickets values(3, 103, 25.00, 2, 3);
insert into tickets values(4, 104, 30.00, 3, 4);
insert into tickets values(5, 105, 35.00, 4, 1);
