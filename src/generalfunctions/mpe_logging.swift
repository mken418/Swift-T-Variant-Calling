
#ifndef MPE_SWIFT
#define MPE_SWIFT

(string event) create_pair (string name) "turbine" "0.0"  [
	 "set <<event>> [mpe::create_pair <<name>>] "
 ];

(void signal) mpelog (int eventID, string msg) "turbine" "0.0" [
	"mpe::log <<eventID>> <<msg>>"
];

#endif
