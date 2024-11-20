//this is a test
DROP TABLE Buys;
DROP TABLE Tickets;
DROP TABLE Buyer;
DROP TABLE Screenings;
DROP TABLE Venues;
DROP TABLE Films;
DROP TABLE Directors;
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
    address CHAR(25)
);

create table Screenings (
    ScreeningID INT PRIMARY KEY, 
    show_date date,             
    FilmID INT,
    VenueID INT,
    FOREIGN KEY (FilmID) REFERENCES Films(FilmID),
    FOREIGN KEY (VenueID) REFERENCES Venues(VenueID)
);

create table Buyer (
    BuyerID INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fname CHAR(10),
    lname CHAR(20),
    price_payed FLOAT CHECK (price_payed > 0),
    phone_num CHAR(15)
);

create table Tickets (
    TicketID INT PRIMARY KEY,
    seat_Num INT,
    price FLOAT CHECK (price > 0),
    ScreeningID INT,
    BuyerID INT,
    FOREIGN KEY (ScreeningID) REFERENCES Screenings(ScreeningID),
    FOREIGN KEY (BuyerID) REFERENCES Buyer(BuyerID)
);

create table Buys (
    BuyerID INT,
    TicketID INT,
    date_purchased date,       
    PRIMARY KEY (BuyerID, TicketID),
    FOREIGN KEY (BuyerID) REFERENCES Buyer(BuyerID),
    FOREIGN KEY (TicketID) REFERENCES Tickets(TicketID)
);
drop table ScreeningLog;
CREATE TABLE ScreeningLog (
    LogID INT PRIMARY KEY,
    ScreeningID INt,
    filmID int,
    log_date date
);

//Trigger
drop trigger log_screening_insert;
CREATE TRIGGER log_screening_insert
AFTER INSERT ON Screenings
FOR EACH ROW
BEGIN
    INSERT INTO ScreeningLog VALUES (ScreeningID,FilmID,show_date);
END;

