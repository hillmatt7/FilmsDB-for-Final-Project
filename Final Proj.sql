//this is a test

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
    date_purchased VARCHAR(10),       
    PRIMARY KEY (BuyerID, TicketID),
    FOREIGN KEY (BuyerID) REFERENCES Buyer(BuyerID),
    FOREIGN KEY (TicketID) REFERENCES Tickets(TicketID)
);
