# -*- coding: utf-8 -*-
"""
Created on Fri Jun 17 10:37:49 2016

@author: rkmaddox
"""

from __future__ import print_function
import numpy as np
from expyfun import decimals_to_binary
import sounddevice as sd
from mne.filter import resample
import time
from expyfun.io import read_wav, write_wav

calibration_run = False

if False:
    da, fs_in = read_wav('da_resampled_UR.wav')
    bab, fs_in = read_wav('babble_resampled_UR.wav')

    fs = 48000

    da = resample(da, fs / float(fs_in), 1, n_jobs=1)
    bab = resample(bab, fs / float(fs_in), 1, n_jobs=1)

    write_wav('da_48000_UR.wav', da, fs)
    write_wav('babble_48000_UR.wav', bab, fs)
else:
    da, fs = read_wav('da_48000_UR.wav')
    bab, fs = read_wav('babble_48000_UR.wav')

stim_db = 80
stim_snr = 10
bab *= 10 ** (-stim_snr / 20.)

stim_dur = 170e-3
isi_dur = 83e-3

stim_len = da.shape[-1]
skip_len = int(np.round(fs * (stim_dur + isi_dur)))
isi_len = skip_len - stim_len

n_trials = 3000
phases = (-1) ** np.random.permutation(n_trials)  # choose a random neg half

# set up the triggers
# make the blank trigger pulses
trig_on_dur = 10e-3
trig_pause_dur = 10e-3
trig_on_len = int(fs * trig_on_dur)
trig_pause_len = int(fs * trig_pause_dur)
tube_len_meters = 11. * 25.4 * 1e-3
tube_delay = tube_len_meters / 343.
tube_delay_len = int(np.round(tube_delay * fs))

trig_blanks = np.tile(np.atleast_2d(
        np.concatenate((np.ones(trig_on_len), np.zeros(trig_pause_len)))),
        [1 + 1, 1])

phase_trig_def = {-1: 0, 1: 1}
# neg phase has 4 trigger, pos phase has 8 trigger
trig = dict()
for ph in [-1, 1]:
    stamp = [1]
    stamp += [1 << (b + 2) for b in
              decimals_to_binary([phase_trig_def[ph]], [1])]
    stamp = [b << 8 for b in stamp]
    trig[ph] = np.ravel(np.atleast_2d(stamp).T * trig_blanks)
trig_len = trig[1].shape[-1]

# make the randomly alernating da's
data = np.zeros((4, n_trials * skip_len + isi_len))
start_ind = isi_len
for ti in range(n_trials):
    data[2, start_ind:(start_ind + stim_len)] = da * phases[ti]

    data[[0, 1],
         start_ind + tube_delay_len:start_ind + tube_delay_len + trig_len] = \
        np.atleast_2d(trig[phases[ti]])

    start_ind += skip_len

babble = np.tile(bab, [1, int(np.ceil(data.shape[-1] / bab.shape[-1]) + 1)])
data[2] += np.copy(babble[0, :data.shape[-1]])

data[3] = data[2]


# =============================================================================
#  Set up the RME audio stream
# =============================================================================
# high priorty
def setpriority(pid=None, priority=1):
    """ Set The Priority of a Windows Process.  Priority is a value between
        0-5 where 2 is normal priority.  Default sets the priority of the
        current python process but can take any valid process ID. """

    import win32api
    import win32process
    import win32con

    priorityclasses = [win32process.IDLE_PRIORITY_CLASS,
                       win32process.BELOW_NORMAL_PRIORITY_CLASS,
                       win32process.NORMAL_PRIORITY_CLASS,
                       win32process.ABOVE_NORMAL_PRIORITY_CLASS,
                       win32process.HIGH_PRIORITY_CLASS,
                       win32process.REALTIME_PRIORITY_CLASS]
    if pid is None:
        pid = win32api.GetCurrentProcessId()
    handle = win32api.OpenProcess(win32con.PROCESS_ALL_ACCESS, True, pid)
    win32process.SetPriorityClass(handle, priorityclasses[priority])
setpriority(priority=4)

# get the device set up
did = ['asio' in d['name'].lower() and
       'fireface' in d['name'].lower() for
       d in sd.query_devices()].index(True)

dev_info = sd.query_devices(did)
n_aud_ch = dev_info['max_output_channels']

sd.default.device = did
sd.default.samplerate = int(fs)
sd.default.dither_off = True
sd.default.dtype = 'int32'
sd.default.blocksize = sd.default.samplerate // 5
int_scaler = 2 ** 31 - 1  # scale +/- 1 to fill int32 range

# get the intensity stuff right
ref_rms = 1
ref_db = 111.4  # this is MEASURED dB SPL for a 1kHz sine wave with RMS=ref_rms


def stim_scaler(decibels, stim_rms=0.01):
    return ref_rms / stim_rms * 10 ** ((decibels - ref_db) / 20.)

if calibration_run:
    data[2] = np.sin(
            1000 * 2 * np.pi * np.arange(data.shape[-1]) / float(fs)) \
            / np.sqrt(0.5) * np.std(da)
    data[3] = data[2]


data_scaled = np.zeros((data.shape[-1], n_aud_ch), dtype='int32')
data_scaled[:, [2, 3]] = (
        int_scaler * np.maximum(np.minimum(
                stim_scaler(stim_db, stim_rms=0.1) *
                data[[2, 3]],
                1 - 1e-12), -1 + 1e-12)).T

data_scaled[:, [0, 1]] = data[[0, 1]].T

start_time = time.time()
print('Experiment will run %0.1f minutes' % (data.shape[-1] / float(fs) / 60))
print('Start time: %s' % time.asctime(time.localtime(start_time)))
print('End time: %s' % time.asctime(time.localtime(
        start_time + data.shape[-1] / float(fs))))

status_string = ''

with sd.OutputStream() as stream:
    stream.write(data_scaled)

print('Finished!')
