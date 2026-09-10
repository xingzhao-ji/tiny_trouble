#!/usr/bin/env python3
"""Technical movie decode/mix audit. No audition or full-motion review."""
from array import array
import hashlib,json,math,subprocess,sys
from pathlib import Path

FOLDER=Path(__file__).resolve().parent
SOURCE=FOLDER/"harbor.avi"
MOVIE=FOLDER/"Tiny-Trouble-0.2.5-Harbor.mp4"
commands=[]
def run(args,log_name):
    commands.append(args)
    result=subprocess.run(args,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
    (FOLDER/log_name).write_bytes(result.stderr)
    if result.returncode:
        raise RuntimeError(str(args)+" failed: "+result.stderr.decode(errors="replace"))
    return result.stdout

def probe(path):
    return json.loads(run(["ffprobe","-v","error","-show_format","-show_streams","-of","json",str(path)],path.stem+"_probe.log"))

def audio_metrics(path,info):
    stream=next(item for item in info["streams"] if item["codec_type"]=="audio")
    channels=int(stream["channels"]); rate=int(stream["sample_rate"])
    bits=int(stream.get("bits_per_sample",0)) if stream["codec_name"].startswith("pcm_s") else 0
    positive_rail=1.0-2.0**(-(bits-1)) if bits else None
    command=["ffmpeg","-hide_banner","-loglevel","error","-xerror","-err_detect","explode","-i",str(path),"-map","0:a:0","-vn","-c:a","pcm_f64le","-f","f64le","-"]
    commands.append(command)
    rows=[{"samples":0,"peak_absolute":0.0,"sum_squares":0.0,"non_finite_samples":0,"samples_at_or_above_full_scale":0,"samples_at_integer_rails":0 if bits else None} for _ in range(channels)]
    with (FOLDER/(path.stem+"_audio_decode.log")).open("wb") as error:
        process=subprocess.Popen(command,stdout=subprocess.PIPE,stderr=error)
        count=0; carry=b""
        while True:
            block=process.stdout.read(65536)
            if not block:break
            block=carry+block; remainder=len(block)%8
            carry=block[-remainder:] if remainder else b""
            values=array("d"); values.frombytes(block[:-remainder] if remainder else block)
            if sys.byteorder!="little":values.byteswap()
            for value in values:
                row=rows[count%channels]; count+=1; row["samples"]+=1
                if not math.isfinite(value):row["non_finite_samples"]+=1;continue
                row["peak_absolute"]=max(row["peak_absolute"],abs(value));row["sum_squares"]+=value*value
                row["samples_at_or_above_full_scale"]+=abs(value)>=1.0
                if bits:row["samples_at_integer_rails"]+=value>=positive_rail or value<=-1.0
        process.stdout.close();code=process.wait()
    assert code==0 and not carry and count%channels==0 and count>0,(path,code,count)
    squares=sum(row["sum_squares"] for row in rows)
    for row in rows:
        row["rms"]=math.sqrt(row.pop("sum_squares")/row["samples"])
        row["peak_dbfs"]=20*math.log10(row["peak_absolute"]) if row["peak_absolute"] else None
        row["rms_dbfs"]=20*math.log10(row["rms"]) if row["rms"] else None
    peak=max(row["peak_absolute"] for row in rows);rms=math.sqrt(squares/count)
    return {"codec":stream["codec_name"],"channels":channels,"sample_rate":rate,"decoded_samples":count,"decoded_audio_frames":count//channels,"decoded_duration_seconds":count/channels/rate,"peak_absolute":peak,"peak_dbfs":20*math.log10(peak) if peak else None,"rms":rms,"rms_dbfs":20*math.log10(rms) if rms else None,"non_finite_samples":sum(row["non_finite_samples"] for row in rows),"samples_at_or_above_full_scale":sum(row["samples_at_or_above_full_scale"] for row in rows),"samples_at_integer_rails":sum(row["samples_at_integer_rails"] for row in rows) if bits else None,"integer_pcm_bits":bits or None,"positive_integer_rail":positive_rail,"per_channel":rows,"decode_exit_code":code,"meaning":"Sample peak/RMS of complete decoded mix. Full-scale or integer-rail counts flag clipping candidates, not proof of upstream clipping. AAC overshoot and padding are reported separately from the AVI source. Not true peak, LUFS, perceived loudness, audibility or a subjective mix assessment."}

source=probe(SOURCE);movie=probe(MOVIE)
(FOLDER/"movie_encoded_probe.json").write_text(json.dumps(movie,indent=2)+"\n")
for path in [SOURCE,MOVIE]:
    run(["ffmpeg","-hide_banner","-loglevel","error","-xerror","-err_detect","explode","-i",str(path),"-map","0:v:0","-map","0:a:0","-progress",str(FOLDER/(path.stem+"_full_decode_progress.log")),"-f","null","-"],path.stem+"_full_decode.log")
run(["ffmpeg","-hide_banner","-loglevel","error","-n","-i",str(MOVIE),"-vf",r"select=eq(n\,360)+eq(n\,540)+eq(n\,660)","-fps_mode","vfr","-frames:v","3",str(FOLDER/"encoded_frame_%02d.png")],"movie_frames.log")
metrics={"avi_source_mix":audio_metrics(SOURCE,source),"mp4_aac_derivative":audio_metrics(MOVIE,movie)}
for item in metrics.values():assert item["non_finite_samples"]==0 and item["decoded_samples"]>0
video=next(item for item in movie["streams"] if item["codec_type"]=="video")
assert video["width"]==1280 and video["height"]==720 and video["avg_frame_rate"]=="60/1" and int(video["nb_frames"])==870,video
report={"result":"PASS technical encode/decode and finite-signal audit","scope":"Recorded actual 0.2.5 Harbor route. Movie Maker fixed60FPS video is not real-time performance evidence; no audition, complete motion review or human result.","artifacts":[{"path":path.name,"bytes":path.stat().st_size,"sha256":hashlib.file_digest(path.open("rb"),"sha256").hexdigest()} for path in [SOURCE,MOVIE]],"video":{"codec":video["codec_name"],"width":video["width"],"height":video["height"],"average_frame_rate":video["avg_frame_rate"],"frames":int(video["nb_frames"]),"duration_seconds":float(video["duration"]),"pixel_format":video["pix_fmt"]},"full_decode":{"avi_video_and_audio_exit_code":0,"mp4_video_and_audio_exit_code":0,"fail_on_decode_error":True},"decoded_mix":metrics,"frames_for_bounded_visual_review":[{"file":"encoded_frame_01.png","timestamp_seconds":6},{"file":"encoded_frame_02.png","timestamp_seconds":9},{"file":"encoded_frame_03.png","timestamp_seconds":11}],"commands":commands,"ffmpeg_version":subprocess.check_output(["ffmpeg","-version"],text=True).splitlines()[0]}
(FOLDER/"movie_technical_audit.json").write_text(json.dumps(report,indent=2)+"\n")
print(json.dumps({"result":report["result"],"video":report["video"],"decoded_mix":metrics},indent=2))
