
------- vytvoření 1.tabulky:

   

CREATE OR REPLACE TABLE T_Misa_Sacka_project_sql_primary_final
SELECT
 cp.category_code AS food_code,
 cpc.name AS potravina,
 cp.value AS cena_potravina,
 cpc.price_value AS food_price_value,
 cpc.price_unit AS food_price_unit,
 YEAR (cp.date_from) AS rok,
 cp2.industry_branch_code AS industry_code,
 cpib.name AS industry_name,
 cp2.value AS salary
FROM czechia_price AS cp
JOIN czechia_payroll AS cp2
 ON YEAR (cp.date_from) = cp2.payroll_year
JOIN czechia_price_category AS cpc
 ON cpc.code = cp.category_code
JOIN czechia_payroll_industry_branch AS cpib
 ON cpib.code = cp2.industry_branch_code
WHERE cp2.value_type_code = 5958 AND YEAR (cp.date_from) BETWEEN 2015 AND 2018;


----- vytvoření 2. tabulky:  ekonomický přehled o ostatních zemí:

create table T_Misa_Sacka_project_secondary_final
(SELECT
	c.country,
	c.capital_city,
	c.currency_name,
	c.continent,
	e.year,
	c.population,
	e.GDP,
	e.gini gini
FROM countries c 
JOIN economies e 
ON c.country = e.country
);  

  			

----- 1. úkol: 1. Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?

Select*
from T_Misa_Sacka_project_sql_primary_final;



SELECT
 rok,
 industry_name,
 ROUND (AVG (salary),0) AS salary_avg
FROM T_Misa_Sacka_project_sql_primary_final
WHERE industry_code IS NOT NULL
GROUP BY industry_name, rok
ORDER BY rok;


CREATE OR REPLACE VIEW v_prumerna_mzda AS (
SELECT
rok,
 industry_name,
 ROUND (AVG (salary),0) AS salary_avg
FROM T_Misa_Sacka_project_sql_primary_final
WHERE industry_code IS NOT NULL
GROUP BY industry_name, rok
);



CREATE OR REPLACE VIEW v_porovnani_let AS (
SELECT
 rok,
 industry_name,
 salary_avg,
 LEAD (salary_avg,1) OVER (PARTITION BY industry_name ORDER BY industry_name, rok) next_salary_avg
FROM v_prumerna_mzda vpm 
);


SELECT
rok,
 industry_name,
 salary_avg,
 next_salary_avg,
 next_salary_avg - salary_avg AS difference_salary
FROM v_porovnani_let
WHERE next_salary_avg IS NOT NULL AND (next_salary_avg - salary_avg) < 0
ORDER BY rok ASC;




	________________________________
	
	---- 2. úkol: 2. Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?
	--- kód mléka: 114201
	---- kód  chleba: 111301

	
	-----------------------kolik stojí potraviny (chléb a mléko) a kolik je průměrná mzda v tom roce: 
	
	CREATE OR REPLACE VIEW v_potraviny AS (
	SELECT
    rok,
    potravina,
    salary,
    cena_potravina,
    AVG(salary) AS prumerna_mzda,
    AVG (cena_potravina) AS prumerna_cena_potraviny
FROM T_Misa_Sacka_project_sql_primary_final
WHERE potravina  IN ('Chléb konzumní kmínový', 'Mléko polotučné pasterované') AND rok  IN (2015,2018)
GROUP BY potravina , rok 
ORDER BY rok
);

	
SELECT
    rok,
    potravina,
    AVG(salary),
    AVG (cena_potravina),
    ROUND (prumerna_mzda/prumerna_cena_potraviny)
FROM v_potraviny
WHERE potravina  IN ('Chléb konzumní kmínový', 'Mléko polotučné pasterované') AND rok  IN (2015,2018)
GROUP BY potravina, rok 
ORDER BY rok;


------- 3. úkol: Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)?

CREATE OR REPLACE VIEW v_Misa_prumerna_cena_potravin AS (
SELECT
	rok,
	potravina,
	salary,
	 ROUND (AVG (cena_potravina),2) AS prumerna_cena_potraviny
FROM T_Misa_Sacka_project_sql_primary_final
GROUP BY potravina, rok
);


CREATE OR REPLACE VIEW v_Misa_rozdil_v_letech AS (
SELECT
 rok,
 potravina,
 prumerna_cena_potraviny,
 salary,
 LEAD (prumerna_cena_potraviny,1) OVER (PARTITION BY potravina  ORDER BY potravina, rok) AS next_prumerna_cena_potravin
FROM v_Misa_prumerna_cena_potravin
);

CREATE OR REPLACE VIEW v_Misa_rozdil_v_letech_procento AS (
SELECT
 rok,
 potravina,
 prumerna_cena_potraviny,
 salary,
next_prumerna_cena_potravin,
 ROUND (((next_prumerna_cena_potravin-prumerna_cena_potraviny)/next_prumerna_cena_potravin)*100,2) AS procento_zmeny_ceny
FROM v_Misa_rozdil_v_letech
GROUP BY rok, potravina
ORDER BY potravina, rok
);


SELECT
potravina,
rok,
MIN (procento_zmeny_ceny)
FROM v_Misa_rozdil_v_letech_procento;


------- 4.úkol:	Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?

CREATE OR REPLACE VIEW V_MISA_PRUMERY AS (
SELECT 
ROK,
AVG (SALARY) AS Prumerna_mzda,
AVG (CENA_POTRAVINA) AS Prumerna_cena
FROM T_Misa_Sacka_project_sql_primary_final tmspspf 
GROUP BY rok
)


CREATE OR REPLACE VIEW V_MISA_PRUMERY_rozdil AS (
SELECT
 rok,
 prumerna_mzda,
 prumerna_cena,
 LEAD (prumerna_cena,1) OVER  (ORDER BY  rok) AS next_prumerna_cena_potravin,
 LEAD (prumerna_mzda,1) OVER  (ORDER BY  rok) AS next_prumerna_mzda
FROM V_MISA_PRUMERY
ORDER BY rok
);


CREATE OR REPLACE VIEW v_Misa_rozdil_v_letech_procento AS (
SELECT
 rok,
 prumerna_mzda,
 next_prumerna_mzda,
 prumerna_cena,
 next_prumerna_cena_potravin,
 ROUND (((next_prumerna_cena_potravin-prumerna_cena)/next_prumerna_cena_potravin)*100,2) AS procento_zmeny_ceny,
 ROUND (((next_prumerna_mzda-prumerna_mzda)/next_prumerna_mzda)*100,2) AS procento_zmeny_mzdy
FROM V_MISA_PRUMERY_rozdil
GROUP BY rok
ORDER BY rok
);


SELECT 
rok,
procento_zmeny_ceny - procento_zmeny_mzdy
FROM v_Misa_rozdil_v_letech_procento vmrvlp; 





------- 5.úkol:	Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, projeví se to na cenách potravin či mzdách ve stejném nebo násdujícím roce výraznějším růstem?



CREATE OR REPLACE VIEW v_Misa_cr_GDP_nasledujici_rok AS (
SELECT
 country,
 YEAR,
 GDP,
 LEAD (GDP,1) OVER (PARTITION BY country ORDER BY country, year) next_year_GDP
FROM T_Misa_Sacka_project_secondary_final tmspsf 
WHERE country = 'Czech republic' AND YEAR BETWEEN 2015 AND 2018
ORDER BY YEAR
);



CREATE OR REPLACE VIEW v_Misa_cr_GDP_rozdily AS (
SELECT
 country,
 YEAR,
 GDP,
 next_year_gdp,
 ROUND (((next_year_gdp - GDP)/next_year_gdp)*100,2) AS procento_gdp_rozdil
FROM v_Misa_cr_GDP_nasledujici_rok 
);



SELECT
 YEAR, 
 next_year_GDP,
 procento_gdp_rozdil,
 procento_zmeny_ceny,
 procento_zmeny_mzdy
FROM v_Misa_cr_GDP_rozdily
JOIN v_Misa_rozdil_v_letech_procento
 ON YEAR  = rok;




