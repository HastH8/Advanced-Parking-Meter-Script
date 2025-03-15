CREATE TABLE meter (
    licenseplate VARCHAR(75),
    streetname VARCHAR(75),
    parkduration INT,
    parkdate DATE,
    parktime TIME,
    expiration_time DATETIME,
    PRIMARY KEY (licenseplate, streetname)
);


CREATE TABLE meter_robbery (
    identifier VARCHAR(125) PRIMARY KEY,
    robdate DATE,
    robtime TIME,
    expiration DATETIME
);