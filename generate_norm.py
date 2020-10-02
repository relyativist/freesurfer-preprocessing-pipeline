# Transforms thicknesses from average hcp group and generates norm into subject /surf

import os
import argparse
import nibabel
import numpy as np
from nibabel import freesurfer
from nipype.interfaces.freesurfer import SurfaceTransform


def norm(subj_path, avgtosubj_path):
    thickness_avg_to_subj = nibabel.load(avgtosubj_path).get_data().view(type=np.ndarray)
    thickness_avg_to_subj = thickness_avg_to_subj.reshape((thickness_avg_to_subj.shape)[0])
    thickness_subject = nibabel.freesurfer.io.read_morph_data(subj_path)
    norm = np.divide(thickness_subject, thickness_avg_to_subj, out=np.zeros_like(thickness_subject), where=thickness_avg_to_subj != 0)
    # norm = np.divide(thickness_subject, thickness_avg_to_subj, out=np.full_like(thickness_subject, 1), where=thickness_avg_to_subj != 0) 
    return norm


if __name__ == "__main__":

    parser = argparse.ArgumentParser()
    parser.add_argument('-s', '--subject', help='Subject ID', required=True)
    args = parser.parse_args()

    subject = args.subject
    
    hemi = ["rh", "lh"]
    output = "/tmp"

    sxfm = SurfaceTransform()
    for h in hemi:
        avgtosubj_path = os.path.join(output, subject, "surf", h + f".avg_to_{subject}.mgh")
        subjthickness_path = os.path.join(output, subject, "surf", h + ".thickness")
        normthickness_path = os.path.join(output, subject, "surf", h + ".norm" + ".thickness")
        

        sxfm.inputs.subjects_dir = "/tmp"
        sxfm.inputs.source_subject = "avg_subject_91_expopts"
        sxfm.inputs.source_file = "/tmp/avg_subject_91_expopts/surf/lh.thickness"
        sxfm.inputs.hemi = h
        sxfm.inputs.target_subject = f"{subject}"
        sxfm.inputs.out_file = avgtosubj_path
        sxfm.inputs.reshape = False
        sxfm.inputs.args = "--sfmt curv --cortex"
        print(sxfm.cmdline)
        print(f'run {subject}')
        sxfm.run()
        print(f'run {subject}') 

        norm_to_save=norm(subjthickness_path, avgtosubj_path)
        nibabel.freesurfer.io.write_morph_data(normthickness_path, norm_to_save)
        print("Normalized thickness generated: {}".format(os.path.join(normthickness_path)))
