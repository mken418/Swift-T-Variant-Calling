@dispatch=WORKER
app (file outputfile) CombineGVCFs (string javadir, string gatkdir, string reference, string dbsnp, string variants[] ) {
        javadir "-Xmx8g" "-jar" gatkdir "-T" "CombineGVCFs" "-R" reference "--dbsnp" dbsnp variants "-o" outputfile;
}


