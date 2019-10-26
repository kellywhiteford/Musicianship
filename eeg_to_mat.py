#!/usr/bin/env python2
# -*- coding: utf-8 -*-

import mne
import numpy as np
from scipy.io import savemat
from glob import glob
from os.path import exists

show_analysis = True
overwrite = False

opath = '/path/to/eeg/files/'
files = sorted(glob(opath + '*.vhdr'))

for fn in files:
    fn_mat = fn[:-5] + '.mat'
    if overwrite or not exists(fn_mat):
        raw = mne.io.brainvision.read_raw_brainvision(fn, preload=True)
        trigs = mne.find_events(raw)
        start_inds = np.where(trigs[:, -1] == 1)[0]
        events = trigs[start_inds]
        events[:, -1] = trigs[start_inds + 1, -1] // 4
        raw.drop_channels(['STI 014'])
        ep = mne.Epochs(raw, events, tmin=-0.1, tmax=0.3)
        if show_analysis:
            ev = ep.average()
            ev.plot()
        savemat(fn_mat,
                dict(raw=raw._data,
                     fs=raw.info['sfreq'],
                     channels=raw.ch_names,
                     events=events[:, [0, 2]]))
