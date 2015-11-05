(defun check-missing-dx-codes ()

  (let ((dx-missing-table (make-hash-table :test #'equalp)))

    ;; check that icd9 table is loaded
    (when (not *icd9-code2uri*)
      (load-icd9-code2uri-table))

    ;; iterate over dental-procedure-diagnosis.txt and look
    ;; for codes not in icd9 hash table
    (with-iterator (it :iterator-fn #'dental-procedure-diagnosis-iterator)
      (loop
	 while (next it)
	 for dx-code = (trim-field (fv "DX"))
	 do
	   ;; check that dx-code is not in table 
	   (when (not (gethash dx-code *icd9-code2uri*))
	     ;; check that dx-code is not nil
	     (if dx-code (setf (gethash dx-code dx-missing-table) t)))))
    ;;return hash table
    dx-missing-table))

(defun check-missing-ada-codes ()
  (let ((ada-missing-table (make-hash-table :test #'equalp)))

    ;; check that icd9 table is loaded
    (when (not *ada-code2uri*)
      (load-ada-code2uri-table))

    ;; iterate over dental-procedure-diagnosis.txt and look
    ;; for codes not in icd9 hash table
    (with-iterator (it :iterator-fn #'dental-procedure-diagnosis-iterator)
      (loop
	 while (next it)
	 for ada-code = (trim-field (fv "ADA_CODE"))
	 do
	   ;; check that ada-code is not in table 
	   (when (not (gethash ada-code *ada-code2uri*))
	     ;; check that ada-code is not in nil
	     (if ada-code (setf (gethash ada-code ada-missing-table) t)))))
    ;;return hash table
    ada-missing-table))


(defun create-vdw-extra-cdt-codes-ontology ()
  (let ((count 0)
	(vdw-cdt-uri (make-uri "http://purl.obolibrary.org/obo/ohd/VDW_CDT_0000000")))
	
    ;; check for extra code hash table
    (when (not *vdw-extra-ada-codes*) (load-vdw-extra-ada-codes))
    
    ;; create ontology of the extra ada codes ada codes
    (with-ontology ont (:collecting t
			:base "http://purl.obolibrary.org/obo/ohd/"
			:ontology-iri "http://purl.obolibrary.org/obo/ohd/vdw-cdt-codes.owl")
	(;; create VDW CDT code class
	 (as
	  `((declaration (class ,vdw-cdt-uri))
	    (subclass-of ,vdw-cdt-uri !'current dental terminology code'@ohd)
	    (annotation-assertion !rdfs:label ,vdw-cdt-uri "VDW current dental terminology code")
	    (annotation-assertion !'definition'@ohd
				  ,vdw-cdt-uri "A current dental terminology code found in the VDW data that is not in cdt-imports.owl.")
	    (annotation-assertion !'definition editor' ,vdw-cdt-uri "Bill Duncan")
	    (annotation-assertion !'editor note'@ohd
				  ,vdw-cdt-uri
				  ,(format-comment
				    (str+ 
				     "These codes are in need of more categorization. For example, code D0210 should "
				     "be categorized as a subclass of 'bill code for diagnostic'. However, until this categorization is "
				     "done I'm putting the extra CDT codes in a flat hierarchy under this class.")))
	    (annotation-assertion !'curator note'@ohd
				  ,vdw-cdt-uri
				  ,(format-comment
				    "This class is generated by the function create-vdw-medical-codes-ontology in medical-codes-utils.lisp"))))
	 
	 ;; iterater over extra codes hash table and for each code create code subclasses
	 (loop
	    for code being the hash-keys in *vdw-extra-ada-codes*
	    for code-uri = (make-vdw-cdt-code-uri code)
	    do
	      
	      ;; skip codes "99203" and "T1013"; they are not CDT codes
	      (when (and (not (equalp code "99203"))
			 (not (equalp code "T1013")))
		(incf count)
		(as
		 `((declaration (class ,code-uri))
		   (subclass-of ,code-uri ,vdw-cdt-uri)
		   (annotation-assertion !dc:identifier ,code-uri ,code)
		   (annotation-assertion !rdfs:label ,code-uri ,(str+ "billing code " code))
		   (annotation-assertion !'curator note'@ohd
					 ,code-uri
					 ,(format-comment
					   "This class is generated by the function create-vdw-medical-codes-ontology in medical-codes-utils.lisp")))))))
      
      ;; return ontolgy
      (print-db count)
      ont)))

;; (defun create-vdw-medical-codes-ontology-archive ()
;;   ;; This version created classes for the CPT and HCPPS classes.
;;   ;; BUT, these codes have an internal use in the VDW.
;;   ;; So, these classes will not be used.
;;   ;; I am keeping this code around incase I need it again ...
;;   (let ((count 0)
;; 	(vdw-cdt-uri (make-uri "http://purl.obolibrary.org/obo/ohd/VDW_CDT_0000000"))
;; 	(cpt-uri (make-uri "http://purl.obolibrary.org/obo/ohd/VDW_CPT_0000000"))
;; 	(hcpcs-uri (make-uri "http://purl.obolibrary.org/obo/ohd/VDW_HCPCS_0000000")))

;;     ;; check for extra code hash table
;;     (when (not *vdw-extra-ada-codes*) (load-vdw-extra-ada-codes))

;;     ;; create ontology of the extra ada codes ada codes
;;     (with-ontology ont (:collecting t
;; 			:base "http://purl.obolibrary.org/obo/ohd/"
;; 			:ontology-iri "http://purl.obolibrary.org/obo/ohd/vdw-medical-codes.owl")
;; 	(;; create VDW CDT code class
;; 	 (as
;; 	  `((declaration (class ,vdw-cdt-uri))
;; 	    (subclass-of ,vdw-cdt-uri !'current dental terminology code'@ohd)
;; 	    (annotation-assertion !rdfs:label ,vdw-cdt-uri "VDW current dental terminology code")
;; 	    (annotation-assertion !'definition'@ohd
;; 				  ,vdw-cdt-uri "A current dental terminology code found in the VDW data that is not in cdt-imports.owl.")
;; 	    (annotation-assertion !'definition editor' ,vdw-cdt-uri "Bill Duncan")
;; 	    (annotation-assertion !'editor note'@ohd
;; 				  ,vdw-cdt-uri
;; 				  ,(format-comment
;; 				    (str+ 
;; 				     "These codes are in need of more categorization. For example, code D0210 should "
;; 				     "be categorized as a subclass of 'bill code for diagnostic'. However, until this categorization is "
;; 				     "done I'm putting the extra CDT codes in a flat hierarchy under this class.")))
;; 	    (annotation-assertion !'curator note'@ohd
;; 				  ,vdw-cdt-uri
;; 				  ,(format-comment
;; 				    "This class is generated by the function create-vdw-medical-codes-ontology in medical-codes-utils.lisp"))))
	 
;; 	 ;; create VDW CPT code class
;; 	 (as
;; 	  `((declaration (class ,cpt-uri))
;; 	    (subclass-of ,cpt-uri !'CRID'@ohd)
;; 	    (annotation-assertion !rdfs:label ,cpt-uri "current procedure terminology code")
;; 	    (annotation-assertion !'definition'@ohd
;; 				  ,cpt-uri
;; 				  ,(str+ "A centrally registered indentifier that is a medical code set maintained by the American Medical "
;; 					 "Association through the CPT Editorial Panel. The CPT code set (copyright protected by the AMA) "
;; 					 "describes medical, surgical, and diagnostic services and is designed to communicate uniform "
;; 					 "information about medical services and procedures among physicians, coders, patients, accreditation "
;; 					 "organizations, and payers for administrative, financial, and analytical purposes."))
;; 	    (annotation-assertion !'definition source'@ohd ,cpt-uri "https://en.wikipedia.org/wiki/Current_Procedural_Terminology")
;; 	    (annotation-assertion !'definition editor' ,cpt-uri "Bill Duncan")
;; 	    (annotation-assertion !'editor note'@ohd
;; 				  ,cpt-uri "This class contains CPT codes found in the VDW data. It is not a complete set of codes.")
;; 	    (annotation-assertion !'curator note'@ohd
;; 				  ,cpt-uri
;; 				  ,(format-comment
;; 				    "This class is generated by the function create-vdw-medical-codes-ontology in medical-codes-utils.lisp"))))

;; 	 ;; create Healthcare Common Procedure Coding System (HCPCS) code class
;; 	 (as
;; 	  `((declaration (class ,hcpcs-uri))
;; 	    (subclass-of ,hcpcs-uri !'CRID'@ohd)
;; 	    (annotation-assertion !rdfs:label ,hcpcs-uri "healthcare common procedure coding system code")
;; 	    (annotation-assertion !'definition'@ohd
;; 				  ,hcpcs-uri
;; 				  ,(str+ "A centrally registered indentifier (CRID) that identifies a set of health care procedure codes "
;; 					 "based on the American Medical Association's Current Procedural Terminology (CPT)."))
;; 	    (annotation-assertion !'definition editor' ,hcpcs-uri "Bill Duncan")
;; 	    (annotation-assertion !'definition source' ,hcpcs-uri "https://en.wikipedia.org/wiki/Healthcare_Common_Procedure_Coding_System")
;; 	    (annotation-assertion !'editor note'@ohd
;; 				  ,hcpcs-uri
;; 				  ,(format-comment "This class contains HCPCS codes found in the VDW data. It is not a complete set of codes."))

;; 	    (annotation-assertion !'curator note'@ohd
;; 				  ,hcpcs-uri
;; 				  ,(format-comment
;; 				    "This class is generated by the function create-vdw-medical-codes-ontology in medical-codes-utils.lisp"))))

;; 	 ;; iterater over extra codes hash table and for each code create code subclasses
;; 	 (loop
;; 	    for code being the hash-keys in *vdw-extra-ada-codes*
;; 	    for code-uri = (make-vdw-medical-code-uri code)
;; 	    do
;; 	      (incf count)
;; 	      (as
;; 	       `((declaration (class ,code-uri))
;; 		 (annotation-assertion !dc:identifier ,code-uri ,code)
;; 		 (annotation-assertion !'curator note'@ohd
;; 				       ,code-uri
;; 				       ,(format-comment
;; 					 "This class is generated by the function create-vdw-medical-codes-ontology in medical-codes-utils.lisp"))))

;; 	      ;; determine the super class and label of codea
;; 	      (cond
;; 		((equalp code "99203")
;; 		 (as
;; 		  `((subclass-of ,code-uri ,cpt-uri)
;; 		    (annotation-assertion !rdfs:label ,code-uri ,(str+ "CPT code " code)))))
;; 		((equalp code "T1013")
;; 		 (as
;; 		  `((subclass-of ,code-uri ,hcpcs-uri)
;; 		    (annotation-assertion !rdfs:label ,code-uri ,(str+ "HCPCS code " code)))))
;; 		(t
;; 		 (as
;; 		  `((subclass-of ,code-uri ,vdw-cdt-uri)
;; 		    (annotation-assertion !rdfs:label ,code-uri ,(str+ "billing code " code))))))))
      
;;       ;; return ontolgy
;;       (print-db count)
;;       ont)))
1


