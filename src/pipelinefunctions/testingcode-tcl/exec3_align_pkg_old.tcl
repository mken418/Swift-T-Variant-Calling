#!/usr/bin/env tclsh

package provide align 0.0

proc bwa {bwadir index R1 R2 rgheader args} {
	set result "$bwadir mem $index $R1 $R2 -R $rgheader $args"
	return $result
}

proc samtools {samtoolsdir args} {
	set result "$samtoolsdir view -b $args"
	return $result
}

proc pipe { out proc1 proc2 } {
       exec {*}$proc1 | {*}$proc2  > $out
       return $out
}

