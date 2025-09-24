-- student_records_schema.sql
-- Student Records Database for a University
-- Creates database and all tables with constraints and relationships
-- Engine: InnoDB, Charset: utf8mb4

DROP DATABASE IF EXISTS student_records;
CREATE DATABASE student_records
  CHARACTER SET = 'utf8mb4'
  COLLATE = 'utf8mb4_unicode_ci';

USE student_records;

-- -----------------------------------------------------
-- STUDENTS (one-to-many -> addresses; one-to-one -> profile)
-- -----------------------------------------------------
DROP TABLE IF EXISTS students;
CREATE TABLE students (
  student_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  registration_number VARCHAR(50) NOT NULL UNIQUE,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  email VARCHAR(255) NOT NULL UNIQUE,
  phone VARCHAR(30),
  date_of_birth DATE,
  enrolled_date DATE NOT NULL,
  status ENUM('active','suspended','graduated','withdrawn') NOT NULL DEFAULT 'active',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- STUDENT_PROFILES (one-to-one with students)
-- -----------------------------------------------------
DROP TABLE IF EXISTS student_profiles;
CREATE TABLE student_profiles (
  profile_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  student_id INT UNSIGNED NOT NULL UNIQUE, -- ensures one-to-one
  gender ENUM('male','female','other'),
  nationality VARCHAR(100),
  bio TEXT,
  emergency_contact_name VARCHAR(150),
  emergency_contact_phone VARCHAR(30),
  FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- ADDRESSES (one-to-many: student -> addresses)
-- -----------------------------------------------------
DROP TABLE IF EXISTS addresses;
CREATE TABLE addresses (
  address_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  student_id INT UNSIGNED NOT NULL,
  label VARCHAR(50) DEFAULT 'home', -- e.g., home, term-time
  line1 VARCHAR(255) NOT NULL,
  line2 VARCHAR(255),
  city VARCHAR(100) NOT NULL,
  state VARCHAR(100),
  postal_code VARCHAR(20),
  country VARCHAR(100) NOT NULL,
  is_primary BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- DEPARTMENTS
-- -----------------------------------------------------
DROP TABLE IF EXISTS departments;
CREATE TABLE departments (
  department_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(150) NOT NULL UNIQUE,
  code VARCHAR(20) NOT NULL UNIQUE,
  description TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- INSTRUCTORS (many instructors belong to a department)
-- -----------------------------------------------------
DROP TABLE IF EXISTS instructors;
CREATE TABLE instructors (
  instructor_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  email VARCHAR(255) NOT NULL UNIQUE,
  phone VARCHAR(30),
  department_id INT UNSIGNED,
  hired_date DATE,
  FOREIGN KEY (department_id) REFERENCES departments(department_id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- COURSES (many-to-one: course -> department)
-- -----------------------------------------------------
DROP TABLE IF EXISTS courses;
CREATE TABLE courses (
  course_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(50) NOT NULL UNIQUE, -- e.g., CS101
  title VARCHAR(200) NOT NULL,
  description TEXT,
  credits TINYINT UNSIGNED NOT NULL CHECK (credits > 0),
  department_id INT UNSIGNED,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (department_id) REFERENCES departments(department_id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- COURSE_INSTRUCTORS (many-to-many: course <-> instructor)
-- -----------------------------------------------------
DROP TABLE IF EXISTS course_instructors;
CREATE TABLE course_instructors (
  course_id INT UNSIGNED NOT NULL,
  instructor_id INT UNSIGNED NOT NULL,
  role ENUM('lead','assistant') NOT NULL DEFAULT 'lead',
  assigned_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (course_id, instructor_id),
  FOREIGN KEY (course_id) REFERENCES courses(course_id) ON DELETE CASCADE,
  FOREIGN KEY (instructor_id) REFERENCES instructors(instructor_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- SEMESTERS (term periods)
-- -----------------------------------------------------
DROP TABLE IF EXISTS semesters;
CREATE TABLE semesters (
  semester_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE, -- e.g., "Fall 2025"
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT FALSE
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- OFFERINGS (a course offered in a particular semester)
-- -----------------------------------------------------
DROP TABLE IF EXISTS course_offerings;
CREATE TABLE course_offerings (
  offering_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  course_id INT UNSIGNED NOT NULL,
  semester_id INT UNSIGNED NOT NULL,
  section VARCHAR(20) DEFAULT 'A',
  capacity INT UNSIGNED NOT NULL DEFAULT 30,
  location VARCHAR(200),
  schedule VARCHAR(200),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY unique_offering (course_id, semester_id, section),
  FOREIGN KEY (course_id) REFERENCES courses(course_id) ON DELETE CASCADE,
  FOREIGN KEY (semester_id) REFERENCES semesters(semester_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- ENROLLMENTS (many-to-many between students and course_offerings)
-- includes extra attributes (enrolled_at, grade, status)
-- -----------------------------------------------------
DROP TABLE IF EXISTS enrollments;
CREATE TABLE enrollments (
  enrollment_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  student_id INT UNSIGNED NOT NULL,
  offering_id INT UNSIGNED NOT NULL,
  enrolled_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  status ENUM('enrolled','dropped','completed','withdrawn') NOT NULL DEFAULT 'enrolled',
  grade VARCHAR(5), -- e.g., A, B+, 3.5
  UNIQUE KEY unique_student_offering (student_id, offering_id),
  FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE,
  FOREIGN KEY (offering_id) REFERENCES course_offerings(offering_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- PREREQUISITES (many-to-many self-reference on courses)
-- a course can require multiple prerequisite courses
-- -----------------------------------------------------
DROP TABLE IF EXISTS course_prerequisites;
CREATE TABLE course_prerequisites (
  course_id INT UNSIGNED NOT NULL,
  prerequisite_course_id INT UNSIGNED NOT NULL,
  PRIMARY KEY (course_id, prerequisite_course_id),
  FOREIGN KEY (course_id) REFERENCES courses(course_id) ON DELETE CASCADE,
  FOREIGN KEY (prerequisite_course_id) REFERENCES courses(course_id) ON DELETE CASCADE,
  CONSTRAINT chk_not_self_prereq CHECK (course_id <> prerequisite_course_id)
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- AUDIT LOG (optional)
-- -----------------------------------------------------
DROP TABLE IF EXISTS audit_logs;
CREATE TABLE audit_logs (
  log_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  entity VARCHAR(100) NOT NULL,
  entity_id VARCHAR(100),
  action VARCHAR(50) NOT NULL,
  performed_by VARCHAR(255),
  details JSON,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- Helpful Indexes
-- -----------------------------------------------------
CREATE INDEX idx_students_name ON students(last_name(50), first_name(50));
CREATE INDEX idx_courses_title ON courses(title(100));
CREATE INDEX idx_offerings_course ON course_offerings(course_id);
CREATE INDEX idx_enrollments_student ON enrollments(student_id);
CREATE INDEX idx_enrollments_offering ON enrollments(offering_id);

-- -----------------------------------------------------
-- Example seed data (optional) - uncomment to insert sample rows
-- -----------------------------------------------------

INSERT INTO departments (name, code, description) VALUES
  ('Computer Science', 'CS', 'Computer science department'),
  ('Mathematics', 'MATH', 'Mathematics department');

INSERT INTO instructors (first_name,last_name,email,department_id) VALUES
  ('Alice','Smith','alice.smith@example.edu',1),
  ('Bob','Jones','bob.jones@example.edu',2);

INSERT INTO courses (code,title,credits,department_id) VALUES
  ('CS101','Intro to Computer Science',3,1),
  ('MATH101','Calculus I',4,2);

INSERT INTO semesters (name,start_date,end_date,is_active) VALUES
  ('Fall 2025','2025-09-01','2025-12-20',TRUE);

INSERT INTO course_offerings (course_id,semester_id,section,capacity,location,schedule) VALUES
  (1,1,'A',50,'Main Hall','Mon/Wed 09:00-10:30'),
  (2,1,'A',60,'Room 201','Tue/Thu 10:00-11:30');

INSERT INTO students (registration_number,first_name,last_name,email,enrolled_date) VALUES
  ('REG2025001','John','Doe','john.doe@example.edu','2025-09-01'),
  ('REG2025002','Jane','Roe','jane.roe@example.edu','2025-09-01');

-- Enroll John into CS101 offering
INSERT INTO enrollments (student_id, offering_id, status) VALUES (1,1,'enrolled');


-- -----------------------------------------------------
-- End of schema
-- -----------------------------------------------------
