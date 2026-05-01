# Complexity Test Report - Thu Apr 30 22:07:19 UTC 2026

| Level | Task | Status | SQL | Result |
|-------|------|--------|-----|--------|
| 1 | List all employees from SCOTT.EMP table. | ❌ FAIL | `SELECT * FROM scott.emp` | Error: ORA-12541 |
| 2 | List employees from SCOTT.EMP with a salary (SAL) greater than 2000. | ❌ FAIL | `SELECT * FROM SCOTT.EMP WHERE SAL > 2000` | Error: ORA-12541 |
| 3 | List employee names (ENAME) and their department names (DNAME) by joining SCOTT.EMP and SCOTT.DEPT on DEPTNO. | ❌ FAIL | `SELECT E.ENAME, D.DNAME
FROM SCOTT.EMP E
JOIN SCOTT.DEPT D ON E.DEPTNO = D.DEPTNO` | Error: ORA-12541 |
| 4 | Count the number of employees in each department. Show DEPTNO and the count from SCOTT.EMP. | ❌ FAIL | `SELECT DEPTNO, COUNT(*) AS EmployeeCount
FROM SCOTT.EMP
GROUP BY DEPTNO` | Error: ORA-12541 |
| 5 | Find the average salary (SAL) for each job (JOB) in the SCOTT.EMP table. | ❌ FAIL | `SELECT JOB, AVG(SAL) AS SAL
FROM SCOTT.EMP
GROUP BY JOB` | Error: ORA-12541 |
| 6 | Find the name (ENAME) of the highest paid employee in each department (DEPTNO) from SCOTT.EMP. | ❌ FAIL | `SELECT d.dname, e.ENAME
FROM scott.emp e, scott dept d
WHERE e.deptno = d.deptno
ORDER BY e.sal DESC
FETCH FIRST 1 ROW ONLY` | Error: ORA-12541 |
| 7 | List employees (ENAME) who earn more than their managers. Join SCOTT.EMP with itself on MGR = EMPNO. | ❌ FAIL | `SELECT e1.ENAME
FROM scott.emp e1
JOIN scott.emp e2 ON e1.mgr = e2.empno
WHERE e1.sal > e2.sal` | Error: ORA-12541 |
| 8 | Find departments (DNAME) from SCOTT.DEPT that have no employees in SCOTT.EMP. | ❌ FAIL | `SELECT dname FROM scott.dept WHERE deptno NOT IN (SELECT deptno FROM scott.emp)` | Error: ORA-12541 |
| 9 | List the top 3 highest earning employees (ENAME, SAL) from the SCOTT.EMP table. | ❌ FAIL | `SELECT ENAME, SAL
FROM SCOTT.EMP
ORDER BY SAL DESC
FETCH FIRST 3 ROWS ONLY` | Error: ORA-12541 |
| 10 | For each department, show the employee name (ENAME), hire date (HIREDATE), and a running total of salaries (SAL) (cumulative sum) ordered by hire date. | ❌ FAIL | `SELECT e.ENAME, e.HIREDATE, SUM(e.SAL) OVER (ORDER BY e.HIREDATE) AS RUNNING_SAL
FROM SCOTT.EMP e
JOIN SCOTT.DEPT d ON e.DEPTNO = d.DEPTNO
ORDER BY e.HIREDATE` | Error: ORA-12541 |
