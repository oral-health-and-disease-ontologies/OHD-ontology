;;;;; general shared functions ;;;;

;; Assuming that FMA uses the same numbering system, here's how the vector is computed
;; (loop with alist 
;;    for (rel tooth) in (get FMA::|Secondary dentition| :slots)
;;    nwhen (eq rel fma::|member|)
;;    do 
;;     (let ((syns (remove-if-not (lambda(e) (eq (car e) fma::|Synonym|)) (get tooth :slots))))
;;        (loop for (rel syn) in syns
;; 	  for name = (second (find fma::|name| (get syn :slots) :key 'car))
;; 	  for number = (caar (all-matches name ".*?(\\d+).*" 1))
;; 	  when number do (push (cons (parse-integer number) tooth) alist)))
;;    finally (return (coerce 
;; 		    (mapcar (lambda(e) (cons (fma-uri e) (string e)))
;; 			    (mapcar 'cdr (sort alist '< :key 'car))) 'vector)))


(defun number-to-fma-tooth (number &key return-tooth-uri return-tooth-name)
  "Translates a tooth number into corresponding fma class.  By default, a cons is returned consisting of the (fma-class . name).  The :return-tooth-uri key specifies that only the uri is returned.  The :return-tooth-name key specifies that only the name is returned."
  (let ((teeth nil)
	(tooth nil))
    (setf teeth
	  #((!obo:FMA_55696 . "Right upper third secondary molar tooth") 
	    (!obo:FMA_55697 . "Right upper second secondary molar tooth")
	    (!obo:FMA_55698 . "Right upper first secondary molar tooth")
	    (!obo:FMA_55688 . "Right upper second secondary premolar tooth")
	    (!obo:FMA_55689 . "Right upper first secondary premolar tooth")
	    (!obo:FMA_55798 . "Right upper secondary canine tooth")
	    (!obo:FMA_55680 . "Right upper lateral secondary incisor tooth")
	    (!obo:FMA_55681 . "Right upper central secondary incisor tooth")
	    (!obo:FMA_55682 . "Left upper central secondary incisor tooth")
	    (!obo:FMA_55683 . "Left upper lateral secondary incisor tooth")
	    (!obo:FMA_55799 . "Left upper secondary canine tooth")
	    (!obo:FMA_55690 . "Left upper first secondary premolar tooth")
	    (!obo:FMA_55691 . "Left upper second secondary premolar tooth")
	    (!obo:FMA_55699 . "Left upper first secondary molar tooth")
	    (!obo:FMA_55700 . "Left upper second secondary molar tooth")
	    (!obo:FMA_55701 . "Left upper third secondary molar tooth")
	    (!obo:FMA_55702 . "Left lower third secondary molar tooth")
	    (!obo:FMA_55703 . "Left lower second secondary molar tooth")
	    (!obo:FMA_55704 . "Left lower first secondary molar tooth")
	    (!obo:FMA_55692 . "Left lower second secondary premolar tooth")
	    (!obo:FMA_55693 . "Left lower first secondary premolar tooth")
	    (!obo:FMA_55687 . "Left lower secondary canine tooth")
	    (!obo:FMA_57141 . "Left lower lateral secondary incisor tooth")
	    (!obo:FMA_57143 . "Left lower central secondary incisor tooth")
	    (!obo:FMA_57142 . "Right lower central secondary incisor tooth")
	    (!obo:FMA_57140 . "Right lower lateral secondary incisor tooth")
	    (!obo:FMA_55686 . "Right lower secondary canine tooth")
	    (!obo:FMA_55694 . "Right lower first secondary premolar tooth")
	    (!obo:FMA_55695 . "Right lower second secondary premolar tooth")
	    (!obo:FMA_55705 . "Right lower first secondary molar tooth")
	    (!obo:FMA_55706 . "Right lower second secondary molar tooth")
	    (!obo:FMA_55707 . "Right lower third secondary molar tooth")))

    (cond
      (return-tooth-uri (setf tooth (car (aref teeth (1- number)))))
      (return-tooth-name (setf tooth (cdr (aref teeth (1- number)))))
      (t (setf tooth (aref teeth (1- number)))))
    ;; return tooth uri/name
    tooth))

;; alanr
;; billd: this was intended to read data that has tooth ranges of the form "3-6".
;; however, we are reading the tooth_data array, which is processed using get-teeth-list
(defun parse-teeth-list (teeth-description)
  "Parses the tooth list format '-' is range, ',' separates, into a list of teeth numbers"
  (let ((teeth-list nil))

    (let ((pieces (split-at-char teeth-description #\,)))
      (loop for piece in pieces do
	   (cond ((find #\- piece) 
		  (destructuring-bind (start end) 
		      (mapcar 'parse-integer 
			      (car (all-matches piece "^(\\d+)-(\\d+)" 1 2)))
		    (loop for i from start to end do (push i teeth-list))))
		 ;; otherwise it is a single number
		 (t (push (parse-integer piece) teeth-list)))))
    ;; return list of teeth
    teeth-list))

(defun get-unique-iri(string &key salt class-type iri-base args)
  "Returns a unique iri by doing a md5 checksum on the string parameter. An optional md5 salt value is specified by the salt key value (i.e., :salt salt). The class-type argument (i.e., :class-type class-type) concatentates the class type to the string.  This parameter is highly suggested, since it helps guarntee that ire will be unique.  The iri-base (i.e., :iri-base iri-base) is prepended to the iri.  For example, (get-unique-iri \"test\" :iri-base \"http://test.com/\" will prepend \"http://test.com/\" to the md5 checksum of \"test\".  The args parmameter is used to specify an other information you wish to concatenate to the string paramenter.  Args can be either a single value or list; e.g., (get-unique-iri \"test\" :args \"foo\") (get-unique-iri \"test\" :args '(\"foo\" \"bar\")."
  ;; check that string param is a string
  (if (not (stringp string)) 
      (setf string (format nil "~a" string)))

  ;; prepend class type to string
  (when class-type
    (setf class-type (remove-leading-! class-type))
    (setf string (format nil "~a~a" class-type string)))
  
  ;; concatenate extra arguments to string
  (when args
    (cond 
      ((listp args)
       (loop for item in args do
	    (setf item (remove-leading-! item))
	    (setf string (format nil "~a~a" string item))))
      (t (setf string (format nil "~a~a" string args)))))

  ;; encode string
  (setf string (encode string :salt salt))
  (when iri-base
    (setf string (format nil "~a~a" iri-base string)))
  (make-uri string))

(defun remove-leading-! (iri)
  "Removes the leading '!' from a iri and returns the iri as a string.
If no leading '!' is present, the iri is simply returned as string."
  (setf iri (format nil "~a" iri))
  (when (equal "!" (subseq iri 0 1)) (setf iri (subseq iri 1)))
  ;; return iri
  iri)

(defun encode (string &key salt)
  "Returns and md5 checksum of the string argument.  When the salt argument is present, it used in the computing of the md5 check sum."
  (let ((it nil))
    ;; check for salt
    (when salt
      (setf string (format nil "~a~a" salt string)))
    
    (setf it (new 'com.hp.hpl.jena.shared.uuid.MD5 string))
    
    (#"processString" it)
    (#"getStringDigest" it)))

(defun str+ (&rest values)
  "A shortcut for concatenting a list of strings. Code found at:
http://stackoverflow.com/questions/5457346/lisp-function-to-concatenate-a-list-of-strings
Parameters:
  values:  The string to be concatenated.
Usage:
  (str+ \"string1\"   \"string1\" \"string 3\" ...)
  (str+ s1 s2 s3 ...)"

  ;; the following make use of the format functions
  ;;(format nil "~{~a~}" values)
  ;;; use (format nil "~{~a^ ~}" values) to concatenate with spaces
  ;; this may be the simplist to understand...
  (apply #'concatenate 'string values))

(defun str-right (string num)
  "Returns num characters from the right of string. E.g. (str-right \"test\" 2) => \"st\""
  (let ((end nil)
	(start nil))
    (setf end (length string))
    (setf start (- end num))
    (when (>= start 0)
      (setf string (subseq string start end)))))

(defun str-left (string num)
  "Returns num characters from the left of string. E.g. (str-right \"test\" 2) => \"te\""
  (when (<= num (length string))
    (setf string (subseq string 0 num))))

;;;; database functions ;;;;

(defun table-exists (table-name url)
  "Returns t if table-name exists in db; nil otherwise; url specifies the connection string for the database."
  (let ((connection nil)
	;;(meta nil)
	(statement nil)
	(results nil)
	(query nil)
	(answer nil))
  
    ;; create query string for finding table name in sysobjects
    (setf query (concatenate 
		 'string
		 "SELECT * FROM dbo.sysobjects "
		 "WHERE name = '" table-name "' AND type = 'U'"))

    (unwind-protect
	 (progn
	   ;; connect to db and get data
	   (setf connection (#"getConnection" 'java.sql.DriverManager url))
	   (setf statement (#"createStatement" connection))
	   (setf results (#"executeQuery" statement query))

	   ;; ** could not get this to work :(
	   ;;(setf meta (#"getMetaData" connection)) ;; col
	   ;;(setf results (#"getTables" meta nil nil "action_codes" "TABLE"))

	   (when (#"next" results) (setf answer t)))

      ;; database cleanup
      (and connection (#"close" connection))
      (and results (#"close" results))
      (and statement (#"close" statement)))
    
    ;; return whether the table exists
    answer))

(defun delete-table (table-name url)
  "Deletes all the rows in table-name; url specificies the connection string for connecting to the database."
  (let ((connection nil)
	(statement nil)
	(query nil)
	(success nil))
    
    (setf query (str+ "DELETE " table-name))

    (unwind-protect
	 (progn
	   ;; connect to db and execute query
	   (setf connection (#"getConnection" 'java.sql.DriverManager url))
	   (setf statement (#"createStatement" connection))
	       
	   ;; create table
	   ;; on success 1 is returned; otherwise nil
	   (setf success (#"executeUpdate" statement query)))

      ;; database cleanup
      (and connection (#"close" connection))
      (and statement (#"close" statement)))

    ;; return success indicator
    success))


;;;; specific to eagle soft ;;;;

(defun get-eaglesoft-database-url ()
  "Returns the url string for connecting to Eaglesoft dabase.
Note: The file ~/.pattersondbpw must be on your system."
  (concatenate 'string 
	       "jdbc:sqlanywhere:Server=PattersonPM;UserID=PDBA;password="
	       (with-open-file (f "~/.pattersondbpw") (read-line f))))

(defun get-eaglesoft-salt ()
  "Returns the salt to be used with the md5 checksum.  
Note: The ~/.pattersondbpw file is required to run this procedure."
  (with-open-file (f "~/.pattersondbpw") (read-line f)))

(defun get-eaglesoft-occurrence-date (table-name date-entered date-completed tran-date)
  "Returns the occurrence date as determined by the name of the table."
  (let ((occurrence-date nil))
    ;; all records in the paient_history table have either a date_entered, 
    ;; date_completed, or tran_date value
    (cond
      ;; the transactions table only has a tran_date
      ((equalp table-name "transactions") (setf occurrence-date tran-date))
      (t
       ;; for existing_services and patient_conditions table
       ;; default to date-completed
       (setf occurrence-date date-completed)
       ;; if no date_completed, the set occurrence-date to date-entered
       (when (equalp date-completed (string-trim " " "n/a"))
	 (setf occurrence-date date-entered))))

    ;; return the occurrence date
    occurrence-date))

(defun prepare-eaglesoft-db (url &key force-create-table)
  "Tests whether the action_codes and patient_history tables exist in the Eaglesoft database. The url parameter specifies the connection string to the database.  If the force-create-db key is given, then the tables tables are created regardless of whether they exist. This is needed when the table definitions change."
  ;; test to see if action_codes table exists
  ;; if not then create it
  (when (or (not (table-exists "action_codes" url)) force-create-table)
    (create-aciton-codes-or-patient-history-table "action_codes" url))

  ;; test to see if patient history table exists
  (when (or (not (table-exists "patient_history" url)) force-create-table)
    (create-aciton-codes-or-patient-history-table "patient_history" url)))

(defun create-aciton-codes-or-patient-history-table (table-name url)
  "Creates either the action_codes or patient_history table, as determined by the table-name parameter.  The url parameter specifies the connection string to the database."
  (let ((connection nil)
	(statement nil)
	(query nil)
	(success nil)
	(table-found nil))

    ;; check to see if the table is in the db
    (setf table-found (table-exists table-name url))
    
    ;; create query string for creating table
    (cond
      ((equal table-name "action_codes") 
       (setf query (get-create-action-codes-query)))
      ((equal table-name "patient_history")
       (setf query (get-create-patient-history-query))))
      
    (unwind-protect
	 (progn
	   ;; connect to db and execute query
	   (setf connection (#"getConnection" 'java.sql.DriverManager url))
	   (setf statement (#"createStatement" connection))
	   
	   ;; if the table is already in the db, delete all the rows
	   ;; this is to ensure that the created table will not have
	   ;; any duplicate rows
	   (when table-found (delete-table table-name url))
	   
	   ;; create table
	   ;; on success a non-nil value is returned (usually the number of rows created)
	   ;; on failure nil is returned
	   (setf success (#"executeUpdate" statement query)))

      ;; database cleanup
      (and connection (#"close" connection))
      (and statement (#"close" statement)))

    ;; return success indicator
    success))

(defun get-create-action-codes-query ()
  "
DROP TABLE IF EXISTS PattersonPM.PPM.action_codes; 
CREATE TABLE PattersonPM.PPM.action_codes (action_code_id int NOT NULL, description varchar(50) NOT NULL, PRIMARY KEY (action_code_id));
insert into PattersonPM.PPM.action_codes (action_code_id, description) values (1, 'Missing Tooth'); 
insert into PattersonPM.PPM.action_codes (action_code_id, description) values (2, 'Caries');
insert into PattersonPM.PPM.action_codes (action_code_id, description) values (3, 'Dental Caries');
insert into PattersonPM.PPM.action_codes (action_code_id, description) values (4, 'Recurring Caries');
insert into PattersonPM.PPM.action_codes (action_code_id, description) values (5, 'Abscess/Lesions');
insert into PattersonPM.PPM.action_codes (action_code_id, description) values (6, 'Open Contact');
insert into PattersonPM.PPM.action_codes (action_code_id, description) values (7, 'Non Functional Tooth');
insert into PattersonPM.PPM.action_codes (action_code_id, description) values (8, 'Fractured Restoration');
insert into PattersonPM.PPM.action_codes (action_code_id, description) values (9, 'Fractured Tooth');
insert into PattersonPM.PPM.action_codes (action_code_id, description) values (10,'Restoration With Poor Marginal Integrity');
insert into PattersonPM.PPM.action_codes (action_code_id, description) values (11,'Wear Facets');
insert into PattersonPM.PPM.action_codes (action_code_id, description) values (12,'Tori');
insert into PattersonPM.PPM.action_codes (action_code_id, description) values (13,'Malposition');
insert into PattersonPM.PPM.action_codes (action_code_id, description) values (14,'Erosion');
insert into PattersonPM.PPM.action_codes (action_code_id, description) values (15,'Extrusion');
insert into PattersonPM.PPM.action_codes (action_code_id, description) values (16,'Root Amputation');
insert into PattersonPM.PPM.action_codes (action_code_id, description) values (17,'Root Canal');
insert into PattersonPM.PPM.action_codes (action_code_id, description) values (18,'Impaction');")

(defun get-create-patient-history-query ()
"
/* This line is needed to force Sybase to return all rows when populating the patient_history table. */
SET rowcount 0

DROP TABLE IF EXISTS PattersonPM.PPM.patient_history

/* Create and define the column names for the patient_history table. */
CREATE TABLE
  PattersonPM.PPM.patient_history
  (
    /* Define field names of patient_history. */
    patient_id INT,
    table_name VARCHAR(20),
    date_completed VARCHAR(15) NULL,
    date_entered VARCHAR(15),
    tran_date VARCHAR(15) NULL,
    description VARCHAR(40) NULL,
    tooth VARCHAR(10) NULL,
    surface VARCHAR(10) NULL,
    action_code VARCHAR(5) NULL,
    action_code_description VARCHAR(50) NULL,
    service_code VARCHAR(5) NULL,
    ada_code VARCHAR(5) NULL,
    ada_code_description VARCHAR(50) NULL,
    tooth_data CHAR(55) NULL,
    surface_detail CHAR(23) NULL
  )


/*
Put values of union query into patient_history table.

A field with the value 'n/a' means that the table/view being queried does not have a corresponding
field.  This is necessary because when doing a union of multiple queries the number of columns
returned by each query must match.  Putting the 'n/a' in as a place holder ensures this.

Note: Many of the field are cast to type VARCHAR.  This is necessary in order to allow an 'n/a' to
be the value of a non-character data field (such as a date).
*/
INSERT
INTO
  patient_history
  (
    patient_id,
    table_name,
    date_completed,
    date_entered,
    tran_date,
    description,
    tooth,
    surface,
    action_code,
    action_code_description,
    service_code,
    ada_code,
    ada_code_description,
    tooth_data,
    surface_detail
  )
/*
The existing_services table is the table for all findings in ES that are, essentially
procedures completed by entities outside the current dental office.
*/

SELECT DISTINCT
  existing_services.patient_id,
  table_name = 'existing_services', -- table_name value
  /* date_completed is the date (usually reported by the patient) that something was done */
  CAST(existing_services.date_completed AS VARCHAR),
  /* date_entered is the date that the record was entered into the system */
  CAST(existing_services.date_entered AS VARCHAR),
  tran_date = 'n/a', -- tran_date is not recorded in the existing_services table
  existing_services.description,
  existing_services.tooth,
  existing_services.surface,
  action_code = 'n/a', -- action_code in not recorded in the existing_services table
  action_code_description = 'n/a', -- there is no action code description in the existing_services table
  existing_services.service_code,
  
  ada_code =
  (
    -- This subquery finds the ada_code (if any) associated with a service code.
    SELECT
      services.ada_code
    FROM
      services
    WHERE
      services.service_code = existing_services.service_code),
  
  ada_code_descriiption =
  (
    -- This subquery finds the ada code description (if any) associated with a service code
    SELECT
      services.description
    FROM
      services
    WHERE
      services.service_code = existing_services.service_code),
  
  tooth_data =
  (
    SELECT
      existing_services_extra.tooth_data
    FROM
      existing_services_extra
    WHERE
      existing_services.patient_id = existing_services_extra.patient_id
    AND existing_services.line_number = existing_services_extra.line_number),
  
  surface_detail =
  (
    SELECT
      surface_detail
    FROM
      existing_services_extra
    WHERE
      existing_services.patient_id = existing_services_extra.patient_id
    AND existing_services.line_number = existing_services_extra.line_number)
FROM
  existing_services
WHERE
  patient_id IN
  (
    SELECT
      patient_id
    FROM
      patient
    WHERE
      LENGTH(birth_date) > 0)

UNION ALL
/*
The patient_conditions table is the table for all conditions in ES that do not result from a
procedure, i.e. all things that happen one their own (fracture, caries, etc.)
*/
SELECT DISTINCT
  patient_conditions.patient_id,
  table_name = 'patient_conditions', -- table_name value
  date_completed = 'n/a', -- date_completed is not recorded in the patient_conditions table
  CAST(patient_conditions.date_entered AS VARCHAR), -- date_entered is the date that the record was entered into the system
  tran_date = 'n/a', -- tran_date is not recorded in the patient_conditions table
  patient_conditions.description,
  patient_conditions.tooth,
  /* The case statement, here, is used to return empty strings for null values. */
  surface =
  CASE
    WHEN patient_conditions.surface IS NULL
    THEN ''
    ELSE patient_conditions.surface
  END,
  
  --see 'EagleSoft queries_123011.xls' spreadsheet for a list of action codes
  CAST(patient_conditions.action_code AS VARCHAR),
  action_code_description =
  (
    -- This subquery finds the desciption associate with an action code.
    SELECT
      action_codes.description
    FROM
      action_codes
    WHERE
      action_codes.action_code_id = patient_conditions.action_code),
  
  -- service codes, ada codes, and ada code descriptions are not recorded in the patient_conditions table
  service_code = 'n/a',
  ada_code = 'n/a',
  ada_code_description = 'n/a',
  
  tooth_data =
  (
    SELECT
      tooth_data
    FROM
      patient_conditions_extra
    WHERE
      patient_conditions.counter_id = patient_conditions_extra.counter_id),
  
  surface_detail =
  (
    SELECT
      surface_detail
    FROM
      patient_conditions_extra
    WHERE
      patient_conditions.counter_id = patient_conditions_extra.counter_id)
FROM
  patient_conditions
WHERE
  patient_id IN
  (
    SELECT
      patient_id
    FROM
      patient
    WHERE
      LENGTH(birth_date) > 0)

UNION ALL
/*
The transactions view records transactions between the provider and the patient.
*/
SELECT DISTINCT
  transactions.patient_id,
  table_name = 'transactions', -- table_name value (although transactions is a viiew)
  date_completed = 'n/a', -- date_completed is not recorded in the transactons view
  date_entered = 'n/a', -- date_entered is not recorded in the transactons view
  CAST(transactions.tran_date AS VARCHAR),
  transactions.description,
  transactions.tooth,
  /* The case statement, here, is used to return empty strings for null values. */
  surface =
  CASE
    WHEN transactions.surface IS NULL
    THEN ''
    ELSE transactions.surface
  END,
  action_code = 'n/a', -- action_code in not recroded in the transactions view
  action_code_description = 'n/a', -- there are no action code descriptions in the transactions view
  transactions.service_code,
  
  ada_code =
  (
    -- This subquery finds the ada_code (if any) associated with a service code.
    SELECT
      services.ada_code
    FROM
      services
    WHERE
      services.service_code = transactions.service_code),
  
  ada_code_description =
  (
    -- This subquery finds the ada code description (if any) associated with a service code
    SELECT
      services.description
    FROM
      services
    WHERE
      services.service_code = transactions.service_code),
  
  tooth_data =
  (
    SELECT
      tooth_data
    FROM
      transactions_extra
    WHERE
      transactions.tran_num = transactions_extra.tran_num),
  
  surface_detail =
  (
    SELECT
      surface_detail
    FROM
      transactions_extra
    WHERE
      transactions.tran_num = transactions_extra.tran_num)
FROM
  transactions
WHERE
  type = 'S'
AND
  patient_id IN
  (
    SELECT
      patient_id
    FROM
      patient
    WHERE
      LENGTH(birth_date) > 0)
  
  /* To use an order by clause in a union query, you reference the column number. */
ORDER BY
  1, -- patient_id
  2, -- table_name
  3, -- date_completed
  4, -- date_entered
  5, -- tran_date
  7 -- tooth
")
