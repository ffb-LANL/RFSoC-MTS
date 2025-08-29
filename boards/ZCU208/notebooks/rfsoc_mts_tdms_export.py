# rfsoc_mts_tdms_export.py
# -------------------------------------------------------------
# Save RFSoC DAC/ADC arrays to NI TDMS using npTDMS (nptdms),
# and show a Jupyter "download" link for the generated file.
#
# Group:    'p'
# Channels: 'out' (DAC waveform), 'in' (ADC deep capture)
#
# Usage in a notebook:
#   from rfsoc_mts_tdms_export import write_pulses_to_tdms, jupyter_download_link
#   tdms_path = write_pulses_to_tdms(dac_wave, adc_deep, fs_dac_hz, fs_adc_hz, filename="pulses.tdms")
#   jupyter_download_link(tdms_path)
# -------------------------------------------------------------

from __future__ import annotations

import os, time
from pathlib import Path
from typing import Optional, Union, Dict, Any
import numpy as np

# Import nptdms only inside the writer to avoid failing just by importing this module
_NPTDMS_IMPORT_MSG = (
    "The 'nptdms' package is required. Install on PYNQ with:\n"
    "    pip3 install --upgrade nptdms\n"
)

ArrayLike = Union[np.ndarray, memoryview, bytes, bytearray]

def _as_contiguous_1d(a: ArrayLike, dtype: Optional[np.dtype]) -> np.ndarray:
    """
    Return a 1‑D contiguous NumPy view/copy of *a*.
    If *dtype* is provided, interpret/cast as that dtype.
    Works with numpy arrays or any buffer‑protocol object (e.g., PYNQ buffers).
    """
    if isinstance(a, np.ndarray):
        arr = a
        if dtype is not None and arr.dtype != dtype:
            arr = arr.astype(dtype, copy=False)
    else:
        # Create a zero‑copy view over the buffer if possible
        arr = np.frombuffer(a, dtype=(dtype or np.uint8))
    arr = np.ascontiguousarray(arr)
    if arr.ndim > 1:
        arr = arr.reshape(-1)
    return arr

def _now_iso() -> str:
    return time.strftime("%Y-%m-%dT%H:%M:%S", time.localtime())

def write_pulses_to_tdms(
    out_wave: Optional[ArrayLike],
    in_capture: ArrayLike,
    fs_out_hz: float,
    fs_in_hz: float,
    filename: str = "capture.tdms",
    out_dtype: Union[np.dtype, str] = "int16",
    in_dtype: Union[np.dtype, str] = "int16",
    directory: Union[str, os.PathLike] = "captures",
    group_name: str = "p",
    out_channel: str = "out",
    in_channel: str = "in",
    chunk_samples: Optional[int] = None,
    properties: Optional[Dict[str, Any]] = None,
) -> str:
    """
    Write DAC waveform (*out_wave*) and ADC deep capture (*in_capture*) to a TDMS file.

    * out_wave: optional; omit or pass None/empty to skip channel 'out'
    * in_capture: required; will be written to channel 'in'
    * fs_out_hz / fs_in_hz: stored as TDMS properties
    * out_dtype / in_dtype: storage types (e.g., 'int16' raw codes, or 'float32' in engineering units)
    * chunk_samples: segment size for streaming 'in' (defaults to ~16 MiB per segment)

    Returns: absolute path to the TDMS file.
    """
    try:
        from nptdms import TdmsWriter, ChannelObject, RootObject, GroupObject  # type: ignore
    except Exception as e:
        raise ImportError(_NPTDMS_IMPORT_MSG) from e

    directory = Path(directory)
    directory.mkdir(parents=True, exist_ok=True)
    if not filename.lower().endswith(".tdms"):
        filename += ".tdms"
    tdms_path = (directory / filename).resolve()

    out_arr = None
    if out_wave is not None:
        try:
            has_len = len(out_wave) > 0  # numpy or buffer
        except TypeError:
            has_len = False
        if has_len:
            out_arr = _as_contiguous_1d(out_wave, np.dtype(out_dtype))

    in_arr = _as_contiguous_1d(in_capture, np.dtype(in_dtype))

    # Default chunk size ≈ 16 MiB per segment
    if chunk_samples is None:
        bytes_per = np.dtype(in_dtype).itemsize
        target_bytes = 16 * (1 << 20)
        chunk_samples = max(1, target_bytes // max(1, bytes_per))

    # Properties on the TDMS group
    group_props: Dict[str, Any] = {
        "created": _now_iso(),
        "fs_out_hz": float(fs_out_hz),
        "fs_in_hz": float(fs_in_hz),
        "out_dtype": str(np.dtype(out_dtype)),
        "in_dtype": str(np.dtype(in_dtype)),
        "generator": "RFSoC-MTS (PYNQ)",
    }
    if properties:
        for k, v in properties.items():
            if isinstance(k, str):
                group_props[k] = v

    root = RootObject(properties={"writer": "rfsoc_mts_tdms_export.py"})
    group = GroupObject(group_name, properties=group_props)

    with TdmsWriter(str(tdms_path)) as w:
        objs = [root, group]

        # 'out' is typically small (DAC buffer); write it in the first segment if provided
        if out_arr is not None and out_arr.size > 0:
            ch_out = ChannelObject(group_name, out_channel, out_arr, properties={"role": "DAC_out"})
            objs.append(ch_out)

        # Write 'in' in one or more segments
        n = in_arr.size
        first_n = min(n, int(chunk_samples))
        ch_in = ChannelObject(group_name, in_channel, in_arr[:first_n], properties={"role": "ADC_in"})
        objs.append(ch_in)
        w.write_segment(objs)  # segment 1: root+group+(out?)+first chunk of 'in'

        # Subsequent segments: only the continuing 'in' channel
        offset = first_n
        while offset < n:
            next_off = min(n, offset + int(chunk_samples))
            seg = [ChannelObject(group_name, in_channel, in_arr[offset:next_off])]
            w.write_segment(seg)
            offset = next_off

    return str(tdms_path)

def jupyter_download_link(path: Union[str, os.PathLike], link_text: Optional[str] = None):
    """
    Return an HTML object that shows a 'Save file' link inside a Jupyter notebook.
    """
    try:
        from IPython.display import HTML  # type: ignore
    except Exception:
        raise RuntimeError("Use jupyter_download_link() inside a Jupyter notebook")

    p = Path(path).resolve()
    try:
        rel = p.relative_to(Path.cwd())
    except ValueError:
        rel = p.name  # fall back to filename
    link_text = link_text or f"⬇️ Download {p.name}"
    return HTML(f'<a href="files/{rel.as_posix()}" download="{p.name}">{link_text}</a>')

__all__ = ["write_pulses_to_tdms", "jupyter_download_link"]