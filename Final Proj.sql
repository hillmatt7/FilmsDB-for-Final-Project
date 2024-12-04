DROP TABLE Buys;
DROP TABLE Tickets;
DROP TABLE Buyer;
DROP TABLE Screenings;
DROP TABLE Venues;
DROP TABLE Films;
DROP TABLE Directors;
DROP trigger how_many_seats;


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
--drop table venues;
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
    FOREIGN KEY (FilmID) REFERENCES Films(FilmID),
    FOREIGN KEY (VenueID) REFERENCES Venues(VenueID)
);

create table Buyer (
    BuyerID INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fname CHAR(10),
    lname CHAR(20),
    price_payed FLOAT CHECK (price_payed > 0)
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
    date_purchased VARCHAR(10),       
    PRIMARY KEY (BuyerID, TicketID),
    FOREIGN KEY (BuyerID) REFERENCES Buyer(BuyerID),
    FOREIGN KEY (TicketID) REFERENCES Tickets(TicketID)
);

-- Trigger to Update Seats
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


    
select * from venues;


insert into venues values(1,'Home',100,100,'123 home');
insert into venues values(2,'Crib',100,120,'123 crib');


select * from directors;

insert into Directors values (1,'585-5885','Frank','Lynn');

select * from films;

insert into films values(1,'Go','horror','2024',1);

select * from screenings;

    
insert into screenings values(1,10.00, '11-01-2024',1,1);
insert into screenings values(2,20.00, '11-02-2024',1,2);


select * from buyer;

insert into buyer(fname,lname,price_payed) values('Frank','franky',23.39);


select * from tickets;
--TRUNCATE TABLE tickets;
insert into tickets values(1,1,23.39,1,1);
insert into tickets values(2,1,24.29,1,1);
insert into tickets values(3,1,23.20,1,1);
insert into tickets values(4,1,23,1,1);

select v.seats_left
from venues v , screenings s
where v.venueID = s.venueid;

select *
from screenings;

delete tickets where ticketID = 1;
