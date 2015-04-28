# Author: Alan Ruttenberg
# Project: OHD
# Date: 2015-04-24
#
# WIP survival analysis


# Querying for pairs of events for survival analysis
# Todo - bring in correlates - age, gender, tooth type

# collect all known resin restoration failures - cases where another restoration or procedure indicates failure
# ?patient - Label of patient
# ?proci1  - The initial resin restoration
# ?date1   - The date of the initial restoration
# ?proci2  - The restoration that indicates failure
# ?soonest_date2" - The date of the restoration that indicates failure
# ?previous_visit_date - The date of the visit just prior to date of the 
#   restoration that indicates failure. For later use with interval censoring.

# The query strategy is slightly odd. The job of the inner select is
# to find pairs of restoration and subsequent restoration. However We
# only want the soonest one, so we aggregate to get date2 which is
# the least date.

# However if we projected ?date2 or ?proci2 out of the inner select
# the grouping wouldn't have anything to max over. So we bind proci2
# and date2 again given the results.

#  surface_restoration_pattern() defines the contraints for the initial restoration
#  surface_restoration_failure_pattern() defines the constraints for considering it a failure

collect_restoration_failures <-function ()
  { queryc("select distinct ?patient ?proci1 ?date1 ?proci2 ?is_posterior (max(?one_before_date) as ?previous_visit_date) ?soonest_date2",
           "where {",
           "{select distinct ?patienti ?proci1 ?date1 ?toothi ?surfacei (min(?date2) as ?soonest_date2)",
           "where {",
           "?patienti a homo_sapiens: .",
           "?toothi rdf:type tooth: .",
           "?toothi asserted_type: ?toothtypei. ",
           "?toothi is_part_of: ?patienti .",
           "?surfacei rdf:type tooth_surface: .",
           "?surfacei asserted_type: ?surfacetypei .",
           "?surfacei is_part_of: ?toothi .",
           surface_restoration_pattern(proci="?proci1",date="?date1"),
           "?proci1 later_encounter: ?proci2.",
           surface_restoration_failure_pattern(proci="?proci2",date="?date2"),
           "} group by ?patienti ?toothi ?surfacei ?proci1 ?date1",
           "}",
           surface_restoration_failure_pattern(proci="?proci2",date="?soonest_date2"),
           "optional { BIND(1 as ?is_posterior). {{?toothi a pre_molar:.} UNION {?toothi a molar:}} } ",
           "?proc_minus_1 next_encounter: ?proci2.",
           "?proc_minus_1 occurrence_date: ?one_before_date.",
           "?patienti rdfs:label ?patient.",
           "?toothi rdfs:label ?tooth .",
           "?surfacei rdfs:label ?surface .",
           "?proci1 rdfs:label ?procedure1 .",
           "?proci2 rdfs:label ?procedure2 .",
           "} group by ?patient ?proci1 ?date1 ?proci2 ?soonest_date2 ?is_posterior")
  }

# Note: pairs of procedure and surface are not unique (since one procedure can be multi-surface)

# For each of the initial restorations, find the latest date that there was a visit.
# ?proci1  - The initial resin restoration
# ?date1   - The date of the initial restoration
# ?latest_date2" - The date of the last visit of any kind the patient had

# The structure of the query is very similar to the above, except we
# omit the constraint on the second visit.


collect_all_restorations_and_latest_followup <-function ()
  { queryc("select distinct ?proci1 ?date1 ?latest_date2 ?is_posterior",
           "where{",
           "  {select distinct ?patienti ?proci1 ?date1 ?toothi ?surfacei (max(?date2) as ?latest_date2) ",
           "    where {",
           "      ?patienti a homo_sapiens: .",
           "      ?toothi rdf:type tooth: .",
           "      ?toothi asserted_type: ?toothtypei. ",
           "      ?toothi is_part_of: ?patienti .",
           "      ?surfacei rdf:type tooth_surface: .",
           "      ?surfacei asserted_type: ?surfacetypei .",
                  surface_restoration_pattern(proci="?proci1",date="?date1"),
           "      ?surfacei is_part_of: ?toothi .",
           "      ?proci1 a tooth_restoration_procedure: .",
           "      ?role2 a tooth_to_be_restored_role: .",
           "      ?role2 inheres_in: ?toothi .",
           "      ?proci1 realizes: ?role2 .",
           "      ?proci1 occurrence_date: ?date1.",
           "      ?proci1 has_participant: ?surfacei .",
           "      optional",
           "      { ?proci1 later_encounter: ?proci2.",
           "      ?proci2 occurrence_date: ?date2 }",
           "      }",
           "    group by ?proci1 ?patienti ?date1 ?toothi ?surfacei order by ?date1",
           "    }",
           "   optional",
           "  { ?proci1 later_encounter: ?proci2.",
           "    ?proci2 occurrence_date: ?latest_date2.",
           "    ?proci2 rdfs:label ?procedure2 }",
           "  optional { BIND(1 as ?is_posterior). {{?toothi a pre_molar:.} UNION {?toothi a molar:}} } ",
           "  ?patienti rdfs:label ?patient.",
           "  ?toothi rdfs:label ?tooth .",
           "  ?surfacei rdfs:label ?surface .",
           "  ?proci1 rdfs:label ?procedure1 .",
           "} ",
           "order by ?date1")


role_inheres_realizes_pattern <- function (...) #role_type, bearer, procedure)
  { bgp = tb(
      "      ?proci a proc_type: .",
      "      :_role a role_type: .",
      "      :_role inheres_in: ?bearer .",
      "      ?proci realizes: :_role .")
    sparql_interpolate(bgp);
  }

surface_restoration_pattern <- function (...)
    {  bgp<- tb(
        "?proci a resin_filling_restoration:.",
        "_:role a tooth_to_be_restored_role:.",
        "_:role  inheres_in: ?toothi.",
        "?proci realizes: _:role.",
        "?proci occurrence_date: ?date.", 
        "?proci has_participant: ?surfacei."
        );
       sparql_interpolate(bgp)
  }


surface_restoration_failure_pattern <- function (...)
    { bgp <- 
        sparql_union(
          tb(
            sparql_union(
              "?proci a tooth_restoration_procedure:.",
              "?proci a inlay_restoration:."),
            "_:role a tooth_to_be_restored_role: .",
            "_:role inheres_in: ?toothi.",
            "?proci realizes: _:role .",
            "?proci occurrence_date: ?date .", 
            "?proci has_participant: ?surfacei ."),
          tb(sparql_union(
            "?proci a crown_restoration: .",
            "?proci a tooth_extraction: .",
            "?proci a endodontic_procedure: ."),
             "_:role1 a target_of_tooth_procedure: .",
             "_:role1 inheres_in: ?toothi.",
             "?proci realizes: _:role1 .",
             "?proci occurrence_date: ?date."))
      sparql_interpolate(bgp)
       #      ,missing_tooth_pattern(exam="?proci",tooth="toothi",date,patient)
    }
    


#constrained: ?patient,?tooth (which used to exist), 
#constrains: ?proci,?date (when it doesn't exist)

missing_tooth_pattern <- function(...){
    interpolate_sparql_vars(
        "?patienti participates_in: ?exam.",
        "?exam a oral_evaluation:.",
        "?exam occurrence_date: ?date.",
        "?exam has_specified_output: _:finding",
        "_:finding is_about: ?patient.",
        "_:finding a missing_tooth_finding:.",
        "?tooth_number is_part_of: _:finding.",
        "?toothi a _:tooth_class.",
        "?tooth_number is_about: _:tooth_class."
        )
}

