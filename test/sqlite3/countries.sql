CREATE TABLE countries (
    iso_3166_code TEXT PRIMARY KEY,
    name_en TEXT NOT NULL,
    currency TEXT NOT NULL
);

# 14 countries
INSERT INTO countries (iso_3166_code, name_en, currency) VALUES ('AU', 'Australia', 'AUD');
INSERT INTO countries (iso_3166_code, name_en, currency) VALUES ('ID', 'Indonesia', 'IDR');
INSERT INTO countries (iso_3166_code, name_en, currency) VALUES ('MN', 'Mongolia', 'MNT');
INSERT INTO countries (iso_3166_code, name_en, currency) VALUES ('SD', 'Sudan', 'SDG');
INSERT INTO countries (iso_3166_code, name_en, currency) VALUES ('PL', 'Poland', 'PLN');
INSERT INTO countries (iso_3166_code, name_en, currency) VALUES ('MW', 'Malawi', 'MWK');
INSERT INTO countries (iso_3166_code, name_en, currency) VALUES ('US', 'United States', 'USD');
INSERT INTO countries (iso_3166_code, name_en, currency) VALUES ('JP', 'Japan', 'JPY');
INSERT INTO countries (iso_3166_code, name_en, currency) VALUES ('DE', 'Germany', 'EUR');
INSERT INTO countries (iso_3166_code, name_en, currency) VALUES ('IN', 'India', 'INR');
INSERT INTO countries (iso_3166_code, name_en, currency) VALUES ('BR', 'Brazil', 'BRL');
INSERT INTO countries (iso_3166_code, name_en, currency) VALUES ('ZA', 'South Africa', 'ZAR');
INSERT INTO countries (iso_3166_code, name_en, currency) VALUES ('CA', 'Canada', 'CAD');
INSERT INTO countries (iso_3166_code, name_en, currency) VALUES ('CN', 'China', 'CNY');
