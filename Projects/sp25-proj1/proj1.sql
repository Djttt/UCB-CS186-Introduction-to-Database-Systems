-- Before running drop any existing views
DROP VIEW IF EXISTS q0;
DROP VIEW IF EXISTS q1i;
DROP VIEW IF EXISTS q1ii;
DROP VIEW IF EXISTS q1iii;
DROP VIEW IF EXISTS q1iv;
DROP VIEW IF EXISTS q2i;
DROP VIEW IF EXISTS q2ii;
DROP VIEW IF EXISTS q2iii;
DROP VIEW IF EXISTS q3i;
DROP VIEW IF EXISTS q3ii;
DROP VIEW IF EXISTS q3iii;
DROP VIEW IF EXISTS q4i;
DROP VIEW IF EXISTS q4ii;
DROP VIEW IF EXISTS q4iii;
DROP VIEW IF EXISTS q4iv;
DROP VIEW IF EXISTS q4v;

-- Question 0
CREATE VIEW q0(era)
AS
  SELECT MAX(era)
  FROM pitching
;

-- Question 1i
CREATE VIEW q1i(namefirst, namelast, birthyear)
AS
  SELECT namefirst, namelast, birthyear
  FROM people
  WHERE weight > 300
;

-- Question 1ii
CREATE VIEW q1ii(namefirst, namelast, birthyear)
AS
  SELECT namefirst, namelast, birthyear
  From people
  WHERE namefirst LIKE '% %'
  ORDER BY namefirst, namelast ASC
;

-- Question 1iii
CREATE VIEW q1iii(birthyear, avgheight, count)
AS
  SELECT birthyear, AVG(height), COUNT(*)
  FROM people
  GROUP BY birthyear
  ORDER BY birthyear ASC
;

-- Question 1iv
CREATE VIEW q1iv(birthyear, avgheight, count)
AS
  SELECT birthyear, AVG(height), COUNT(*)
  From people
  GROUP BY birthyear
  HAVING AVG(height) > 70
  ORDER BY birthyear ASC
;

-- Question 2i
CREATE VIEW q2i(namefirst, namelast, playerid, yearid)
AS
  SELECT people.namefirst, people.namelast, people.playerid, halloffame.yearid
  From people INNER JOIN halloffame
  ON people.playerid = halloffame.playerid AND  halloffame.inducted = 'Y'
  ORDER BY halloffame.yearid DESC, halloffame.playerid ASC
;

-- Question 2ii
CREATE VIEW q2ii(namefirst, namelast, playerid, schoolid, yearid)
AS
  SELECT p.namefirst, p.namelast, p.playerid, s.schoolID, h.yearid
  FROM people AS p INNER JOIN halloffame AS h INNER JOIN schools as s
  INNER JOIN collegeplaying AS c
  ON p.playerid = h.playerid AND h.playerid = c.playerid
    AND  c.schoolID = s.schoolID 
    AND s.schoolState = 'CA' AND h.inducted = 'Y'
  ORDER BY h.yearid DESC, s.schoolID ASC, p.playerid ASC
;

-- Question 2iii
CREATE VIEW q2iii(playerid, namefirst, namelast, schoolid)
AS  
  SELECT p.playerid, p.namefirst, p.namelast, c.schoolID 
  FROM people as p INNER JOIN halloffame AS h 
  ON p.playerid = h.playerid AND h.inducted = 'Y'
  LEFT OUTER JOIN collegeplaying as c
  ON h.playerid = c.playerid
  ORDER BY p.playerid DESC, c.schoolID ASC
;

-- Question 3i
CREATE VIEW q3i(playerid, namefirst, namelast, yearid, slg)
AS
  SELECT p.playerid, p.namefirst, p.namelast, b.yearid, 
  CAST((b.H - b.H2B - b.H3B - b.HR) + 2 * b.H2B + 3 * b.H3B + 4 * b.HR AS FLOAT) 
  / b.AB AS slg
  FROM people AS p INNER JOIN batting AS b
  ON p.playerid = b.playerid 
  WHERE b.AB > 50 
  ORDER BY slg DESC, b.yearid ASC, p.playerid ASC 
  LIMIT 10
;

-- Question 3ii
CREATE VIEW q3ii(playerid, namefirst, namelast, lslg)
AS
  SELECT p.playerid, p.namefirst, p.namelast,
  CAST((SUM(b.H) - SUM(b.H2B) - SUM(b.H3B) - SUM(b.HR)) + 2 * SUM(b.H2B) + 3 * SUM(b.H3B) + 4 * SUM(b.HR) AS FLOAT) 
  / SUM(b.AB) AS lslg
  FROM people AS p INNER JOIN batting AS b
  ON p.playerid = b.playerid
  GROUP BY p.playerid
  HAVING SUM(b.AB) > 50
  ORDER BY lslg DESC, p.playerid ASC
  LIMIT 10
;

-- Question 3iii
CREATE VIEW q3iii(namefirst, namelast, lslg)
AS
  SELECT p.namefirst, p.namelast,
  CAST((SUM(b.H) - SUM(b.H2B) - SUM(b.H3B) - SUM(b.HR)) + 2 * SUM(b.H2B) + 3 * SUM(b.H3B) + 4 * SUM(b.HR) AS FLOAT) 
  / SUM(b.AB) AS lslg
  FROM people AS p INNER JOIN batting AS b
  ON p.playerid = b.playerid
  GROUP BY p.playerid
  HAVING SUM(b.AB) > 50 AND 
  lslg > (
    SELECT 
      CAST((SUM(b2.H) - SUM(b2.H2B) - SUM(b2.H3B) - SUM(b2.HR)) + 2 * SUM(b2.H2B) + 3 * SUM(b2.H3B) + 4 * SUM(b2.HR) AS FLOAT) 
    / SUM(b2.AB) AS lslg
    FROM batting AS b2
    WHERE b2.playerid = 'mayswi01'
    GROUP BY b2.playerid
  )
;

-- Question 4i
CREATE VIEW q4i(yearid, min, max, avg)
AS
  SELECT yearid, MIN(salary), MAX(salary), AVG(salary)
  FROM salaries
  GROUP BY yearid
  ORDER BY yearid ASC
;

-- Question 4ii
CREATE VIEW q4ii(binid, low, high, count) AS
WITH stats AS (
    SELECT MIN(salary) AS min_salary,
           MAX(salary) AS max_salary,
           (MAX(salary) - MIN(salary)) / 10.0 AS bin_width
    FROM salaries
    WHERE yearid = 2016
),
salary_bins AS (
    SELECT CAST((salary - stats.min_salary) / stats.bin_width AS INT) AS binid
    FROM salaries, stats
    WHERE yearid = 2016
)
SELECT
    b.binid,
    stats.min_salary + stats.bin_width * b.binid AS low,
    CASE WHEN b.binid = 9 THEN CAST(stats.max_salary AS FLOAT)
         ELSE stats.min_salary + stats.bin_width * (b.binid + 1)
    END AS high,
    COUNT(s.binid) AS count
FROM binids b
LEFT JOIN salary_bins s
ON s.binid = b.binid
CROSS JOIN stats
GROUP BY b.binid
ORDER BY b.binid;


-- Question 4iii
CREATE VIEW q4iii(yearid, mindiff, maxdiff, avgdiff)
AS
  SELECT c.yearid,
  (c.min - p.min) as mindiff,
  (c.max - p.max) as maxdiff,
  (c.avg - p.avg) as avgdiff
  FROM q4i AS c INNER JOIN q4i AS p
  WHERE c.yearid = p.yearid + 1
  ORDER BY c.yearid ASC
;

-- Question 4iv
CREATE VIEW q4iv(playerid, namefirst, namelast, salary, yearid)
AS
  SELECT p.playerid, p.namefirst, p.namelast, s.salary, s.yearid
  FROM people p INNER JOIN salaries AS s
  ON p.playerid = s.playerid
  WHERE (s.yearid = 2000 AND s.salary = (SELECT MAX(salary) 
                                          FROM salaries  
                                          WHERE yearid = 2000))
    OR (s.yearid = 2001 AND s.salary = (SELECT MAX(salary) 
                                          FROM salaries
                                          WHERE yearid = 2001))
;
-- Question 4v
CREATE VIEW q4v(team, diffAvg) AS
  SELECT a.teamID, (MAX(s.salary) - MIN(s.salary)) AS diffAvg
  FROM salaries AS s INNER JOIN allstarfull AS a
  ON s.playerid = a.playerid AND s.yearid = 2016
  WHERE a.yearid = 2016
  GROUP BY a.teamID
;

