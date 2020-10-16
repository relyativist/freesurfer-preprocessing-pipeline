#!/bin/sh

:"

Common preproccesing code block
generated freesurfer output to /tmp/freesurfer_${smri} with command:

recon-all -all -i $input_file -subject_id freesurfer_${smri} -sd /tmp -all

"
unzip -o -d /tmp /code/avg_subject.zip

python generate_norm.py -s freesurfer_$smri
