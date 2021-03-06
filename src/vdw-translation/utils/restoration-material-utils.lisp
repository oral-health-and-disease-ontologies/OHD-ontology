(defun vdw-material-name (ada-code)
  "Returns the name the material used in a restoration based on ada code."
  (let ((material-name nil))
    ;; get the numeric part of code
    (setf ada-code (str-right ada-code 4))
    
    ;; compare ada code to respective global code lists
    (cond
      ((member ada-code *amalgam-code-list* :test 'equal) 
       (setf material-name "amalgam"))
      ((member ada-code *resin-code-list* :test 'equal) 
       (setf material-name "resin"))
      ((member ada-code *resin-with-noble-metal-code-list* :test 'equalp)
       (setf material-name "resin with noble metal"))
      ((member ada-code *resin-with-high-noble-metal-code-list* :test 'equalp)
       (setf material-name "resin with high noble metal"))
      ((member ada-code *resin-with-predominantly-base-metal-code-list* :test 'equalp)
       (setf material-name "resin with predominantly base metal"))
      ((member ada-code *gold-code-list* :test 'equal)
       (setf material-name "gold"))
      ((member ada-code *metal-code-list* :test 'equal)
       (setf material-name "metal"))
      ((member ada-code *ceramic-code-list* :test 'equal)
       (setf material-name "ceramic"))
      ((member ada-code *porcelain-code-list* :test 'equalp)
       (setf material-name "porcelain"))
      ((member ada-code *porcelain-fused-to-noble-metal-code-list* :test 'equalp)
       (setf material-name "porcelain fused to noble metal"))
      ((member ada-code *porcelain-fused-to-high-noble-metal-code-list* :test 'equalp)
       (setf material-name "porcelain fused to high noble metal"))
      ((member ada-code *porcelain-fused-to-predominantly-base-metal-code-list* :test 'equalp)
       (setf material-name "porcelain fused to predominantly base metal"))
      ((member ada-code *noble-metal-code-list* :test 'equalp)
       (setf material-name "noble metal"))
      ((member ada-code *high-noble-metal-code-list* :test 'equalp)
       (setf material-name "high noble metal"))
      ((member ada-code *predominantly-base-metal-code-list* :test 'equalp)
       (setf material-name "predominantly base metal"))
      ((member ada-code *stainless-steel-code-list* :test 'equalp)
       (setf material-name "stainless steel"))
      ((member ada-code *stainless-steel-with-resin-window-code-list* :test 'equalp)
       (setf material-name "stainless steel with resin window"))
      ((member ada-code *titanium-code-list* :test 'equalp)
       (setf material-name "titanium"))
      ((member ada-code *three-fourths-ceramic-code-list* :test #'equalp)
       (setf material-name "3/4 ceramic"))
      ((member ada-code *three-fourths-high-noble-metal-code-list* :test #'equalp)
       (setf material-name "3/4 predominantly high noble metal"))
      ((member ada-code *three-fourths-noble-metal-code-list* :test #'equalp)
       (setf material-name "3/4 predominantly noble metal"))
      ((member ada-code *three-fourths-predominantly-base-metal-code-list* :test #'equalp)
       (setf material-name "3/4 predominantly base metal"))
      ((member ada-code *three-fourths-resin-code-list* :test #'equalp)
       (setf material-name "3/4 resin"))
      (t (setf material-name "dental restoration material")))

    ;; return material name
    material-name))

(defun vdw-material-uri (ada-code)
  "Returns the uri of the material used in a restoration based on ada code."
  (let ((material-uri nil))
    ;; get the numeric part of code
    (setf ada-code (str-right ada-code 4))
    
    ;; compare ada code to respective global code lists
    (cond
      ((member ada-code *amalgam-code-list* :test 'equalp)
       (setf material-uri !'amalgam dental restoration material'@ohd))
      ((member ada-code *resin-code-list* :test 'equalp)
       (setf material-uri !'resin dental restoration material'@ohd))
      ((member ada-code *resin-with-noble-metal-code-list* :test 'equalp)
       (setf material-uri !'resin with noble metal dental restoration material'@ohd))
      ((member ada-code *resin-with-high-noble-metal-code-list* :test 'equalp)
       (setf material-uri !'resin with high noble metal dental restoration material'@ohd))
      ((member ada-code *resin-with-predominantly-base-metal-code-list* :test 'equalp)
       (setf material-uri !'resin with predominantly base metal dental restoration material'@ohd))
      ((member ada-code *gold-code-list* :test 'equalp)
       (setf material-uri !'gold dental restoration material'@ohd))
      ((member ada-code *metal-code-list* :test 'equalp)
       (setf material-uri !'metal dental restoration material'@ohd))
      ((member ada-code *ceramic-code-list* :test 'equalp)
       (setf material-uri !'ceramic dental restoration material'@ohd))
      ((member ada-code *porcelain-code-list* :test 'equalp)
       (setf material-uri !'porcelain dental restoration material'@ohd))
      ((member ada-code *porcelain-fused-to-noble-metal-code-list* :test 'equalp)
       (setf material-uri !'porcelain fused to noble metal dental restoration material'@ohd))
      ((member ada-code *porcelain-fused-to-high-noble-metal-code-list* :test 'equalp)
       (setf material-uri !'porcelain fused to high noble metal dental restoration material'@ohd))
      ((member ada-code *porcelain-fused-to-predominantly-base-metal-code-list* :test 'equalp)
       (setf material-uri !'porcelain fused to predominantly base metal dental restoration material'@ohd))
      ((member ada-code *noble-metal-code-list* :test 'equalp)
       (setf material-uri !'noble metal dental restoration material'@ohd))
      ((member ada-code *high-noble-metal-code-list* :test 'equalp)
       (setf material-uri !'high noble metal dental restoration material'@ohd))
      ((member ada-code *predominantly-base-metal-code-list* :test 'equalp)
       (setf material-uri !'predominantly base metal dental restoration material'@ohd))
      ((member ada-code *stainless-steel-code-list* :test 'equalp)
       (setf material-uri !'stainless steel dental restoration material'@ohd))
      ((member ada-code *stainless-steel-with-resin-window-code-list* :test 'equalp)
       (setf material-uri !'stainless steel with resin window dental restoration material'@ohd))
      ((member ada-code *titanium-code-list* :test 'equalp)
       (setf material-uri !'titanium dental restoration material'@ohd))
      ((member ada-code *three-fourths-ceramic-code-list* :test #'equalp)
       (setf material-uri !'3/4 ceramic dental restoration material))
      ((member ada-code *three-fourths-high-noble-metal-code-list* :test #'equalp)
       (setf material-uri !'3/4 high noble metal dental restoration material))
      ((member ada-code *three-fourths-noble-metal-code-list* :test #'equalp)
       (setf material-uri !'3/4 noble metal dental restoration material))
      ((member ada-code *three-fourths-predominantly-base-metal-code-list* :test #'equalp)
       (setf material-uri !'3/4 predominantly base metal dental restoration material))
      ((member ada-code *three-fourths-resin-code-list* :test #'equalp)
       (setf material-uri !'3/4 resin dental restoration material))
      (t 
       (setf material-uri !'dental restoration material'@ohd)))
    
    ;; return material uri
    material-uri))
