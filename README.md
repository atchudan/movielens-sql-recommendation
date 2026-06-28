# MovieLens Movie Recommendation System — SQL Project

A complete end-to-end SQL project built on the MovieLens dataset (100,836 ratings, 9,742 movies, 610 users, 3,683 tags). Built entirely in MySQL Workbench, this project goes beyond basic analytics into the logic behind real-world recommendation engines.

---

## 🗂️ Project Structure

```
movielens-sql/
├── schema.sql        # Database creation, normalization, CSV import logic
├── queries.sql        # All 14 business queries (3 difficulty levels)
├── screenshots/        # Query result screenshots
└── README.md
```

---

## 🗃️ Database Schema

The raw flat CSVs were normalized into **6 relational tables**, including a many-to-many bridge table for genres:

```
movies        → movieId (PK), title, release_year
genres        → genreId (PK), genreName
movie_genres  → movieId (FK), genreId (FK)   [bridge table]
ratings       → userId, movieId (FK), rating, rated_at
tags          → tagId (PK), userId, movieId (FK), tag, tagged_at
links         → movieId (FK/PK), imdbId, tmdbId
```

### Relationships
- **Many-to-Many**: One movie has many genres, one genre belongs to many movies → solved with the `movie_genres` bridge table
- **One-to-Many**: One movie has many ratings and many tags
- **One-to-One**: One movie maps to exactly one IMDB/TMDB link

---

## 📊 Business Questions Answered

### 🔰 Level 1 — Basic
| # | Business Question | Concepts Used |
|---|---|---|
| Q1 | What are the top 10 highest rated movies (min 50 ratings)? | AVG, HAVING threshold |
| Q2 | How many movies exist per genre? | Bridge table JOIN |
| Q3 | How many movies were released per decade? | FLOOR(), bucketing |
| Q4 | What is the rating activity per year? | YEAR(), FROM_UNIXTIME |

### 🔶 Level 2 — Intermediate
| # | Business Question | Concepts Used |
|---|---|---|
| Q5 | Which genre has the highest average rating? | 3-table JOIN, HAVING |
| Q6 | Who are the top 10 most active users? | GROUP BY, ORDER BY |
| Q7 | Which movies are most "controversial"? | STDDEV() |
| Q8 | What are the most commonly used tags? | GROUP BY, COUNT |
| Q9 | Which genres get tagged the most? | 3-table JOIN |
| Q10 | What % of ratings per genre are 4+ stars? | CASE WHEN, percentage calc |

### 🔴 Level 3 — Advanced
| # | Business Question | Concepts Used |
|---|---|---|
| Q11 | Segment users by rating tendency | NTILE(), Window Function |
| Q12 | Find users with the most similar taste | Self-Join |
| Q13 | Genre popularity by decade (pivoted) | CASE WHEN as PIVOT |
| Q14 | Recommend unseen movies to a user | Stored Procedure, Self-Join, Collaborative Filtering |

---

## 🔍 Key Findings

- **Drama and Comedy** are the most prolific genres by movie count
- A small number of users account for a disproportionate share of total ratings (power users)
- Some movies show high rating variance — genuinely polarizing titles rather than universally liked or disliked
- The recommendation procedure (Q14) successfully surfaces unseen movies based on the taste of similar users, demonstrating basic **User-Based Collaborative Filtering**

---

## ⚙️ How to Run This Project

### Prerequisites
- MySQL Server 8.0+
- MySQL Workbench

### Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/atchudan/movielens-sql-recommendation.git
   ```

2. **Download the dataset**
   Get `ml-latest-small` from [MovieLens](https://grouplens.org/datasets/movielens/) and place the CSVs in your MySQL secure upload directory:
   ```sql
   SHOW VARIABLES LIKE 'secure_file_priv';
   ```

3. **Run the schema file**
   Open `schema.sql` in MySQL Workbench and run it top to bottom. This creates the database, normalizes the data, and adds indexes.

4. **Run the queries**
   Open `queries.sql` and run any query individually, or call the recommendation procedure directly:
   ```sql
   CALL recommend_movies(1);
   ```

---

## 🛠️ Technical Highlights

- Normalized a flat CSV with pipe-separated genres into a proper **many-to-many bridge table**
- Cleaned real-world messy data — Windows line endings (`\r`), UTF-8 encoding issues, embedded special characters
- Converted Unix timestamps to readable datetimes using `FROM_UNIXTIME()`
- Used **self-joins** to compare users against each other for similarity scoring
- Built a working **stored procedure** that performs collaborative filtering — the same fundamental logic behind Netflix and Amazon's early recommendation systems
- Used `NTILE()` for user segmentation and `STDDEV()` for variance-based insights

---

## 📁 Dataset

- **Source:** [MovieLens ml-latest-small](https://grouplens.org/datasets/movielens/) by GroupLens Research, University of Minnesota
- **Ratings:** 100,836 (0.5–5.0 star scale)
- **Movies:** 9,742
- **Users:** 610
- **Tags:** 3,683
- **Period:** March 1996 – September 2018

> Citation: F. Maxwell Harper and Joseph A. Konstan. 2015. The MovieLens Datasets: History and Context. ACM Transactions on Interactive Intelligent Systems (TiiS) 5, 4: 19:1–19:19.

---

## 👤 Author

Atchudan
https://www.linkedin.com/in/atchudan-sreeram-609b46169/
https://github.com/atchudan
