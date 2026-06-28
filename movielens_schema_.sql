--  MovieLens Movie Recommendation — MySQL Workbench Setup
CREATE DATABASE IF NOT EXISTS movielens;
USE movielens;

-- table 1 : movies 
create table if not exists movies (
	movieId INT NOT NULL ,
    Title VARCHAR(300) NOT NULL,
    Release_year INT,
    primary KEY (movieId)
    );
    
-- table 2 : ratings
create table if not exists ratings (
	userId INT NOT NULL,
    movieId INT NOT NULL,
    rating decimal(2,1) NOT NULL,
    rated_at datetime,
    primary key (userId,movieId),
    foreign key (movieId) references movies(movieId)
    );
    
-- table 3 : genres
create table if not exists genre(
	genreId INT NOT NULL AUTO_INCREMENT,
	genreName varchar(40) NOT NULL UNIQUE,
    PRIMARY KEY (genreId)
    );
    
-- table 4 : movie_genres
CREATE TABLE IF NOT EXISTS movie_genres (
    movieId INT NOT NULL,
    genreId INT NOT NULL,
    PRIMARY KEY (movieId, genreId),
    FOREIGN KEY (movieId) REFERENCES movies(movieId),
    FOREIGN KEY (genreId) REFERENCES genre(genreId)
);

-- table 5 : tags
create table if not exists tags(
	tagId  INT NOT NULL AUTO_INCREMENT,
	userId INT NOT NULL,
    movieId INT NOT NULL,
    tag varchar(255) NOT NULL,
    tagged_at datetime,
    primary key (tagId),
    foreign key (movieId) REFERENCES movies(movieId)
    );

-- table 6 : links
CREATE TABLE IF NOT EXISTS links (
    movieId INT NOT NULL,
    imdbId  VARCHAR(20),
    tmdbId  VARCHAR(20),
    PRIMARY KEY (movieId),
    FOREIGN KEY (movieId) REFERENCES movies(movieId)
);

-- STAGING RAW TABLES

CREATE TABLE IF NOT EXISTS raw_movies (
    movieId INT,
    title   VARCHAR(300),
    genres  VARCHAR(500)
);

CREATE TABLE IF NOT EXISTS raw_ratings (
    userId    INT,
    movieId   INT,
    rating    DECIMAL(2,1),
    timestamp BIGINT
);

CREATE TABLE IF NOT EXISTS raw_tags (
    userId    INT,
    movieId   INT,
    tag       VARCHAR(255),
    timestamp BIGINT
);

CREATE TABLE IF NOT EXISTS raw_links (
    movieId INT,
    imdbId  VARCHAR(20),
    tmdbId  VARCHAR(20)
);

-- LOAD CSVs INTO STAGING
SHOW VARIABLES LIKE 'secure_file_priv';

LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/ml-latest-small/movies.csv"
INTO TABLE raw_movies
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/ml-latest-small/ratings.csv"
INTO TABLE raw_ratings
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/ml-latest-small/tags.csv"
INTO TABLE raw_tags
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/ml-latest-small/links.csv"
INTO TABLE raw_links
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

--  POPULATE NORMALIZED TABLES FROM STAGING

-- STEP 1: movies (extract release year from title)

insert ignore into movies(movieId ,Title,Release_year)
select movieId,
		TRIM(REGEXP_REPLACE(Title , '\\(\\d{4}\\)' , '')) as Title,
        CAST(REGEXP_SUBSTR(Title , '\\d{4}') AS UNSIGNED) as Release_year
from raw_movies;


SET NAMES utf8mb4;
TRUNCATE TABLE raw_movies;
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/ml-latest-small/movies.csv'
INTO TABLE raw_movies
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- STEP 2: genres (extract all unique genre names) (FAILED)
INSERT IGNORE INTO genre (genreName)
SELECT DISTINCT TRIM(j.genre)
FROM raw_movies m
JOIN JSON_TABLE(
    CONCAT('["', REPLACE(REPLACE(m.genres, '|', '","'), '(no genres listed)', 'Unknown'), '"]'),
    '$[*]' COLUMNS (genre VARCHAR(50) PATH '$')
) j
WHERE TRIM(j.genre) != ''; 

#CHECK FOR FAIL
SELECT movieId, title, genres
FROM raw_movies
WHERE HEX(genres) LIKE '%C3%' 
   OR HEX(genres) LIKE '%E2%'
   OR HEX(title)  LIKE '%C3%'
LIMIT 20;

SELECT movieId, title, genres,
       SUBSTRING(genres, 50, 10) AS around_pos_53
FROM raw_movies
WHERE LENGTH(genres) > 50
LIMIT 20;

-- Truncate and reload with proper line endings
TRUNCATE TABLE raw_movies;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/ml-latest-small/movies.csv'
INTO TABLE raw_movies
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

UPDATE raw_movies 
SET genres = REPLACE(genres, '\r', '');

SELECT movieId, genres 
FROM raw_movies 
WHERE genres LIKE '%\r%'
LIMIT 5;

-- STEP 2: genres (extract all unique genre names) (SUCCESS)
INSERT IGNORE INTO genre (genreName)
SELECT DISTINCT TRIM(j.genre)
FROM raw_movies m
JOIN JSON_TABLE(
    CONCAT('["', REPLACE(REPLACE(m.genres, '|', '","'), '(no genres listed)', 'Unknown'), '"]'),
    '$[*]' COLUMNS (genre VARCHAR(50) PATH '$')
) j
WHERE TRIM(j.genre) != '';

-- STEP 3: movie_genres bridge table
INSERT IGNORE INTO movie_genres (movieId, genreId)
SELECT DISTINCT m.movieId, g.genreId
FROM raw_movies m
JOIN JSON_TABLE(
    CONCAT('["', REPLACE(REPLACE(m.genres, '|', '","'), '(no genres listed)', 'Unknown'), '"]'),
    '$[*]' COLUMNS (genre VARCHAR(50) PATH '$')
) j
JOIN genre g ON g.genreName = TRIM(j.genre);

-- STEP 4: ratings (convert unix timestamp to datetime)
INSERT IGNORE INTO ratings (userId, movieId, rating, rated_at)
SELECT userId, movieId, rating,
       FROM_UNIXTIME(timestamp)
FROM raw_ratings;

-- STEP 5: tags (convert unix timestamp to datetime)
INSERT IGNORE INTO tags (userId, movieId, tag, tagged_at)
SELECT userId, movieId, tag,
       FROM_UNIXTIME(timestamp)
FROM raw_tags;

-- STEP 6: links
INSERT IGNORE INTO links (movieId, imdbId, tmdbId)
SELECT movieId, imdbId, tmdbId
FROM raw_links;

--  VERIFY ROW COUNTS
SELECT 'movies'       AS tbl, COUNT(*) AS row_count FROM movies
UNION ALL
SELECT 'genres',      COUNT(*) FROM genre
UNION ALL
SELECT 'movie_genres',COUNT(*) FROM movie_genres
UNION ALL
SELECT 'ratings',     COUNT(*) FROM ratings
UNION ALL
SELECT 'tags',        COUNT(*) FROM raw_tags
UNION ALL
SELECT 'links',       COUNT(*) FROM links;

DROP TABLE raw_movies, raw_ratings, raw_tags, raw_links;

--  INDEXES

CREATE INDEX idx_ratings_movieId   ON ratings(movieId);
CREATE INDEX idx_ratings_userId    ON ratings(userId);
CREATE INDEX idx_ratings_rating    ON ratings(rating);
CREATE INDEX idx_tags_movieId      ON tags(movieId);
CREATE INDEX idx_movie_genres_genre ON movie_genres(genreId);
CREATE INDEX idx_movies_year       ON movies(release_year);
