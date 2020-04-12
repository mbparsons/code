#Part One
#1
-- Schema musicAlbums
-- -----------------------------------------------------
DROP SCHEMA IF EXISTS `musicAlbums` ;
CREATE SCHEMA IF NOT EXISTS `musicAlbums`;
USE `musicAlbums` ;

-- -----------------------------------------------------
-- Table `artist`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `artist` ;

CREATE TABLE IF NOT EXISTS `artist` (
  `ArtistId` INT(11) NOT NULL,
  `Name` VARCHAR(120) NULL DEFAULT NULL,
  PRIMARY KEY (`ArtistId`));


-- -----------------------------------------------------
-- Table `album`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `album` ;

CREATE TABLE IF NOT EXISTS `album` (
  `AlbumId` INT(11) NOT NULL,
  `Title` VARCHAR(160) NOT NULL,
  `ArtistId` INT(11) NOT NULL,
  PRIMARY KEY (`AlbumId`),
  CONSTRAINT `fk_album_artist`
    FOREIGN KEY (`ArtistId`)
    REFERENCES `artist` (`ArtistId`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION);


-- -----------------------------------------------------
-- Table `songs`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `songs` ;

CREATE TABLE IF NOT EXISTS `songs` (
  `trackid` INT(11) NOT NULL AUTO_INCREMENT,
  `AlbumId` INT(11) NOT NULL,
  `trackLineNo` INT(3) NOT NULL,
  `name` VARCHAR(200) NOT NULL,
  `milliseconds` INT(11) NOT NULL,
  `bytes` INT(11) NOT NULL,
  `unitprice` DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (`trackid`),
  CONSTRAINT `fk_songs_album1`
    FOREIGN KEY (`AlbumId`)
    REFERENCES `album` (`AlbumId`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION);
#2
DROP FUNCTION IF EXISTS breakEven;
DELIMITER //
CREATE FUNCTION breakEven (trackid INT, unitprice DECIMAL(10,2)) RETURNS INT(30)
DETERMINISTIC
BEGIN
	DECLARE copies INT(30);
    
    SELECT (15000*count(trackid))/unitprice into copies from songs;
    
	RETURN (copies);
 END //
 DELIMITER ;
 
#3
DROP FUNCTION IF EXISTS breakMillion;
DELIMITER //
CREATE FUNCTION breakMillion (trackid INT, unitprice DECIMAL(10,2)) RETURNS INT(30)
DETERMINISTIC
BEGIN
	DECLARE mcopies INT(30);

    SELECT (1000000 + 150000*count(trackid))/unitprice into mcopies from songs;
    
	RETURN (mcopies);
 END //
 DELIMITER ;
 
 #4
SELECT breakMillion(trackid, unitprice) AS 'Break Million Point' from songs;
SELECT breakEven(trackid, unitprice) AS 'Break Even Point' from songs;

SELECT s.`name`, unitprice, sum(breakEven(s.trackid, s.unitprice)) AS 'Break Even Point', sum(breakMillion(s.trackid, s.unitprice)) AS 'Break Million Point'  from songs s
	join album a on s.AlbumId = a.AlbumId
    join artist ar on a.ArtistId = ar.ArtistId
	group by s.`name`;
 
 #5
INSERT INTO songs(trackid, AlbumId, tracklineNo, `name`, milliseconds, bytes, unitprice)
VALUES ('77','8', '5','Cookies','400000', '20000', '1.99'); 
INSERT INTO album(AlbumId, Title, ArtistID)
VALUES ('8','Cookies','10'); 
INSERT INTO artist( ArtistID, `name`)
VALUES ('10', 'The Fray'); 
DROP PROCEDURE IF EXISTS artistPrice;
select * from songs;

DELIMITER //

CREATE PROCEDURE artistPrice (INOUT id INT(11), INOUT nm VARCHAR(120), OUT totalprice DECIMAL(10,2))
BEGIN
	SELECT sum((SELECT unitprice from songs 
    group by trackid)) into totalprice from songs s
	join album a on s.AlbumId = a.AlbumId
    join artist ar on a.ArtistId = ar.ArtistId
    where ar.ArtistId = id OR ar.`Name` = nm
    group by ar.ArtistId
    ;
    
END //
DELIMITER ;
#6

SET @a = 'The Fray';
CALL artistPrice(@b, @a, @p);
SELECT @b, @a, @p;

SET @b = '10';
CALL artistPrice(@b, @a, @p);
SELECT @b, @a, @p;

#7
delimiter //
CREATE TRIGGER updatecheck BEFORE UPDATE ON songs
FOR EACH ROW
BEGIN
	IF NEW.milliseconds < 1000 
		THEN SET NEW.milliseconds = 1000;
		ELSEIF new.milliseconds > 900000  
           THEN SET NEW.milliseconds = 900000;
           END IF;
       END;//
delimiter ;

#8
delimiter //
CREATE TRIGGER updatefirst BEFORE UPDATE ON album
FOR EACH ROW
BEGIN
	IF NEW.Title <> old.Title 
		THEN SET NEW.Title = upper(left(old.Title,1))+ LOWER(SUBSTRING(old.Title,2,LEN(word)));
		END IF;
       END;//
delimiter ;
#Part Two
#1
USE `musicAlbums` ;

-- -----------------------------------------------------
-- Table `restaurant`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `restaurant` ;

CREATE TABLE IF NOT EXISTS `restaurant` (
  `restaurantid` INT NOT NULL,
  `restaurantname` VARCHAR(100) NOT NULL,
  `isbar` INT (1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`restaurantid`));

-- -----------------------------------------------------
-- Table `playlist`
-- -----------------------------------------------------

DROP TABLE IF EXISTS `playlist` ;

CREATE TABLE IF NOT EXISTS `playlist` (
  `playlistid` INT NOT NULL,
  `playlistname` VARCHAR(100) NOT NULL,
  `restaurantid` INT NOT NULL,
  PRIMARY KEY (`playlistid`),
  CONSTRAINT `fk_playlist_restaurantid`
    FOREIGN KEY (`restaurantid`)
    REFERENCES `restaurant` (`restaurantid`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION);

-- -----------------------------------------------------
-- Table `playlisttrack`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `playlisttrack` ;

CREATE TABLE IF NOT EXISTS `playlisttrack` (
  `playlistLineNo` INT NOT NULL,
  `playlistid` INT NOT NULL,
  `trackid` INT NOT NULL,
  `subscriptionStart` Date NOT NULL,
  `subscriptionEnd` Date NOT NULL,
  `subscriptionCost` DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (`playlistLineNo`),
  CONSTRAINT `fk_playlist_has_track_playlist`
    FOREIGN KEY (`playlistid`)
    REFERENCES `playlist` (`playlistid`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_playlist_has_track_track1`
    FOREIGN KEY (`trackid`)
    REFERENCES `songs` (`trackid`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION);
#2
DELIMITER //
CREATE FUNCTION dailySubCost (subscriptioncost DECIMAL(10,2), subscriptionStart DATE, subscriptionEnd DATE) RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
	DECLARE cost INT(30);
	SELECT subscriptionCost/datediff(subscriptionStart, subscriptionEnd) into cost from playlisttrack
    groupbyplaylistLineNo;
    
	RETURN (cost);
 END //
 DELIMITER ;

 #3
 DELIMITER //
CREATE FUNCTION subscriptionByMonth(playlistLineNo INT, subscriptioncost DECIMAL(10,2), subscriptionStart DATE, subscriptionEnd DATE) RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
	DECLARE m DECIMAL(10,2);
    
	SELECT sum(subscriptionCost) into m from playlisttrack
    group by month(subscriptionStart);
    
	RETURN (cost);
 END //
 DELIMITER ;
 #4
 DELIMITER //

CREATE PROCEDURE playlistCost (INOUt playlistid INT, OUT playlistname VARCHAR(100), OUT c DECIMAL(10,2))
BEGIN
	SELECT sum(subscriptionCost) into c from playlisttrack
    group by playlistLineNo;
    
END //
DELIMITER ;

#5

DELIMITER //
CREATE PROCEDURE restaurantCost (INOUt restaurantid INT, OUT rtname VARCHAR(100), ibar INT(1), OUT c DECIMAL(10,2))
BEGIN
	SELECT sum(subscriptionCost) into c from playlisttrack
    group by restaurantid;
    
END //
DELIMITER ;

#6
CREATE TABLE subscriptionChanges (
playlistLineNo INT not null,
subscriptionStart date not null,
subscriptionEnd date not null,
subscriptionCost dec(10,2) not null,
lastUpdate timestamp not null,
rowValue varchar(20) not null);


#7
DELIMITER //

CREATE TRIGGER playlistupdate before update ON playlisttrack
FOR EACH ROW
BEGIN
	IF NEW.subscriptionStart <> OLD.subscriptionStart OR NEW.subscriptionEnd <> OLD.subscriptionEnd OR NEW.subscriptionCost <> OLD.subscriptionCost
    THEN INSERT INTO subscriptionChanges (playlistLineNo, subscriptionStart, subscriptionEnd, subscriptionCost, lastUpdate, rowValue)
    VALUES(old.playlistLineNo, old.subscriptionStart, old.subscriptionEnd, old.subscriptionCost, current_timestamp(), 'Before Update');
	INSERT INTO subscriptionChanges (playlistLineNo, subscriptionStart, subscriptionEnd, subscriptionCost, lastUpdate, rowValue)
	VALUES(new.playlistLineNo, new.subscriptionStart, new.subscriptionEnd, new.subscriptionCost, current_timestamp(), 'After Update');
	End If;
END //

DELIMITER ;