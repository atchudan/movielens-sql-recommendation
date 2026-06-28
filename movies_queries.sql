use movielens;

select * from movies;
select * from genre;
select * from movie_genres ;
select * from ratings ;
select * from tags ;
select * from links;

-- highest rated movies - top 10
select title as Title , ROUND(AVG(r.rating), 2) as Avg_rating, count(rating) as Total_ratings
from movies m 
join ratings r on m.movieId = r.movieId
group by title 
having total_ratings >= 50
order by avg_rating desc
limit 10 ;

-- movies exist per genre
select genreName , count(movieId) as total_Count
from movie_genres mg
join genre g on mg.genreId = g.genreId
group by genreName
order by total_Count desc;

-- ratings per year
SELECT 
    YEAR(rated_at)        AS yr,
    COUNT(*)              AS total_ratings,
    ROUND(AVG(rating), 2) AS avg_rating
FROM ratings
GROUP BY yr
ORDER BY yr;

-- movies released per decade
select concat(floor(Release_year/10) * 10 , 's') as decade,
count(*) as total_movies
from movies
group by decade
having decade is not NULL
order by decade ;

-- genre having highest avg rating
select genreName , avg(rating) as avg_ratings ,count(rating) as total_ratings
from ratings r 
join movie_genres mg on r.movieId = mg.movieId 
join genre g on g.genreId = mg.genreId 
group by genreName
having count(rating) >= 1000
order by avg_ratings desc;

-- users rated the most movies
SELECT 
userId,
COUNT(*) AS total_ratings,
ROUND(AVG(rating), 2) AS avg_rating_given
FROM ratings
GROUP BY userId
ORDER BY total_ratings DESC
LIMIT 10;

-- top 10 movies had controversial ratings
select m.Title ,
count(*) as total_ratings ,
round(avg(rating),2) as avg_rating , 
round(stddev(rating),2) as variance
from movies m 
join ratings r on m.movieId = r.movieId
group by m.movieId
having total_ratings >= 50
order by variance desc
limit 10;

-- top 10 tags 
select tag , count(*) as count 
from tags 
group by tag
order by count desc
limit 10;

-- genre popularity via tags
SELECT 
    g.genreName,
    COUNT(t.tagId) AS total_tags
FROM genre g
JOIN movie_genres mg ON g.genreId = mg.genreId
JOIN tags t    ON mg.movieId = t.movieId
GROUP BY g.genreName
ORDER BY total_tags DESC;

-- percentage of rating higher than 4
select 
g.genreName,
count(rating) as total_ratings,
count(case when rating >= 4 then 1 end ) as high_rating,
round(count(case when rating >= 4 then 1 end ) * 100 / count(rating),2) as high_rating_perc
from ratings r 
join movie_genres mg on mg.movieId = r.movieId
join genre g on g.genreId = mg.genreId
group by g.genreName
having total_ratings >= 1000
order by high_rating_perc desc;

--  Segment users into rating-tendency tiers
with user_avg as
(
select 
userId,
avg(rating) as avg_rating,
count(*) as total_rating
from ratings
group by userId
)
select 
userId,
avg_rating,
total_rating,
ntile(4) over (order by avg_rating desc) as ranking_tier
from user_avg
order by ranking_tier , avg_rating desc;

-- genre popularity by decade 
SELECT 
    g.genreName,
    COUNT(CASE WHEN m.release_year BETWEEN 1990 AND 1999 THEN 1 END) AS "1990s",
    COUNT(CASE WHEN m.release_year BETWEEN 2000 AND 2009 THEN 1 END) AS "2000s",
    COUNT(CASE WHEN m.release_year BETWEEN 2010 AND 2019 THEN 1 END) AS "2010s"
FROM genre g
JOIN movie_genres mg ON g.genreId = mg.genreId
JOIN movies m         ON mg.movieId = m.movieId
GROUP BY g.genreName
ORDER BY g.genreName;

-- Simple LIKE search
SELECT title, release_year
FROM movies
WHERE title LIKE '%Spider%'
ORDER BY release_year;

--  users with the most similar taste
select r1.userId as user_a ,
r2.userId as user_b , 
count(*) as movies_in_common,
round(avg(abs(r1.rating - r2.rating)),2) as avg_rating_diff
from ratings r1 
join ratings r2 on r1.movieId = r2.movieId and r1.userId < r2.userId
where r1.userId = 1
group by user_a,user_b
HAVING movies_in_common >= 10
order by avg_rating_diff , movies_in_common desc
limit 5;

-- Building a simple Movie Recommendation Stored Procedure(User-Based Collaborative Filtering)
DROP PROCEDURE IF EXISTS recommend_movies;

DELIMITER $$

CREATE PROCEDURE recommend_movies(IN target_user INT)
BEGIN

SELECT 
m.Title,
round(avg(r2.rating),2) as predicted_rating,
count(*) as similar_users_rated
FROM ratings r1
JOIN ratings r2 
	ON r1.movieId = r2.movieId 
	AND r1.userId != r2.userId
	AND ABS(r1.rating - r2.rating) <= 0.5 
JOIN ratings r3 
	ON r2.userId = r3.userId
JOIN movies m 
	ON r3.movieId = m.movieId
WHERE r1.userId = target_user
AND r3.movieId NOT IN (
SELECT movieId FROM ratings WHERE userId = target_user)
GROUP BY m.movieId, m.title
HAVING similar_users_rated >= 3
ORDER BY predicted_rating DESC, similar_users_rated DESC
LIMIT 10
;
END$$
DELIMITER ;

-- Run it for any user
CALL recommend_movies(2);