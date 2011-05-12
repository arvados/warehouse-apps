Get list of files:

 wget ftp://ftp.ncbi.nih.gov/pub/TraceDB/ShortRead/SRA000271/fastq/all.md5s

Download data and store in warehouse:

 ./wget-script | bash 2>&1 | tee -a wget-log-$$

***OR*** in multiple sessions, for example:

 ./wget-script | tail -n +4 | bash 2>&1 | tee -a wget-log-$$
 ./wget-script | head -n 3 | bash 2>&1 | tee -a wget-log-$$

Make a manifest with the same filenames as the FTP data (wget-script forgot to do this):

 ./fix-manifests

Name the resulting manifest:

 wh manifest name name=/tomc/to_be_signed/SRA000271 \
                  newkey=0e0a614e7220c6943da247296ac5220e+164459+K06@templeton

Check md5sums:

 wh job new revision=2421 mrfunction=zhash nodes=8 photons=1 \
            inputkey=0e0a614e7220c6943da247296ac5220e+164459+K06@templeton
