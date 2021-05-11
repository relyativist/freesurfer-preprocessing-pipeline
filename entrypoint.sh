#!/bin/sh

dicom_ids=()
for dirname in /input/*.zip; do
    id=${dirname#/input/}
    id=${id%/}
    id=${id%.*}
    time unzip -o -d /tmp/tosort_$id $dirname >> /dev/null
    #cp -r $dirname /tmp/tosort_$id
    dicom_ids+=( "$id" )
done

find /tmp/tosort_* -name "DICOMDIR" -delete 
parallel --jobs 4 --timeout 300% --progress --joblog /tmp/sort.txt python3 /code/dicomsort/dicomsort.py -d -f /tmp/tosort_{1} /tmp/DICOM/{1}/%StudyDate/%SeriesNumber_%SeriesDescription/%InstanceNumber.dcm ::: ${dicom_ids[@]} || true
echo "Sorting - done"
parallel --jobs 4 --timeout 300% --progress --joblog /tmp/convert.txt heudiconv -d /tmp/DICOM/{subject}/*/*/* -f /code/heuristic.py -s {1} -c dcm2niix -b --overwrite -o /tmp/BIDS ::: ${dicom_ids[@]} & wait $!
echo "Convert to BIDS - done" 

all_ids=()
for dirname in /tmp/BIDS/sub-*; do
    id=${dirname#/tmp/BIDS/sub-}
    id=${id%/}
    if [ ! -e "/output/fmriprep/sub-$id.html" ]; then
        # no output file corresponding to this ID found,
        # add it to he list
        all_ids+=( "$id" )
    fi
done 

printf 'Found ID: %s\n' "${all_ids[@]}"
parallel --jobs 4 --timeout 300% --progress --joblog /tmp/preprocessing.txt fmriprep /tmp/BIDS /tmp participant --fs-license-file /opt/freesurfer/license.txt --ignore fieldmaps --anat-only --force-bbr -w /tmp --participant_label {1} ::: ${all_ids[@]} & wait $!
echo "Preprecessing - done"

unzip -o -d /tmp /code/avg_subject.zip & wait $!

cp -r /tmp/freesurfer/sub-* /tmp

parallel --jobs 4 --timeout 300% --progress --joblog /tmp/generate_norm.txt  python /code/generate_norm.py -s sub-{1} ::: ${all_ids[@]} & wait $!
echo "Generate norm - done"
# convert brain.mgz to nii.gz
for sub in ${all_ids[@]}:
do  
    mri_vol2vol --mov /tmp/sub-${sub}/mri/brain.mgz --targ /tmp/sub-${sub}/mri/rawavg.mgz --regheader --o /tmp/sub-${sub}/mri/brain-in-rawavg.mgz --no-save-reg
    mri_convert --in_type mgz --out_type nii --out_orientation RAS /tmp/sub-${sub}/mri/brain-in-rawavg.mgz /tmp/BIDS/sub-${sub}/anat/sub-${sub}_skullstriped.nii.gz
done & wait $!

# for sub in ${all_ids[@]}:
# do
#     mkdir -p /output/freesurfer
#     mkdir -p /output/sub-${sub}
# done& wait $!

mkdir -p /output/freesurfer

parallel --jobs 4 --timeout 300% --progress --joblog /tmp/zip_bids.txt zip -r -j /output/sub-{1}.zip /tmp/BIDS/sub-{1}/anat/*.nii.gz ::: ${all_ids[@]} & wait $!

parallel --jobs 4 --timeout 300% --progress --joblog /tmp/zip_freesurfer.txt zip -r /output/freesurfer/sub-{1}.zip /tmp/sub-{1}/* ::: ${all_ids[@]} || true
echo "Preprocessing - done, data saved to output"

#find /tmp -mindepth 1 -delete
#echo "Temp files cleared" & wait $!

#mri_vol2vol --mov /input/sub-${sub}/mri/brain.mgz --targ /input/sub-${sub}/mri/rawavg.mgz --regheader --o /input/sub-${sub}/mri/brain-in-rawavg.mgz --no-save-reg
#mri_convert --in_type mgz --out_type nii --out_orientation RAS /input/sub-${sub}/mri/brain-in-rawavg.mgz /input/sub-${sub}_skullstriped.nii.gz