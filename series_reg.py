from nipype.interfaces.ants import RegistrationSynQuick

import argparse
import os

parser = argparse.ArgumentParser()
parser.add_argument('-s', '--subject', help='Subject ID', required=True)
args = parser.parse_args()

subject = args.subject

reg = RegistrationSynQuick()

reg.inputs.fixed_image = '/tmp/BIDS/sub-1/anat/sub-1_acq-T1MprageSagP2IsoOrig_T1w.nii.gz'
reg.inputs.moving_image = '/tmp/BIDS/sub-1/anat/sub-1_acq-T2SpaceNsTra06MmIso_T2w.nii.gz'
reg.inputs.num_threads = 2
reg.transform_type = 'r'
print(reg.cmdline)
at.run()
print("done")

