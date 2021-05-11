FROM nipreps/fmriprep:20.2.1

ENV TERM xterm

RUN apt-get update -qq && \
	apt-get install --yes --no-install-recommends \
	zip unzip pigz jq moreutils time wget inotify-tools vim

RUN conda install -y -q -f -c conda-forge dcm2niix=1.0.20190902 && \
	sync

RUN commit=c9cf5ad16fb3021bb5c6e94ec5c63aec7ea9a99c && \
	curl -LOk https://github.com/pieper/dicomsort/archive/${commit}.zip && \
	unzip ${commit}.zip -d /code && \
	mv /code/dicomsort-${commit} /code/dicomsort && \
	rm -rf ${commit}.zip

COPY ./requirements.txt /code/requirements.txt
RUN pip install --upgrade pip && \
	pip install -r /code/requirements.txt
	#pip uninstall -y tqdm

RUN wget https://ftpmirror.gnu.org/parallel/parallel-20190222.tar.bz2 \
    && bzip2 -dc parallel-20190222.tar.bz2 | tar xvf - \
    && cd parallel-20190222 \
    && ./configure && make && make install \
	&& rm -r /tmp/parallel-20190222.tar.bz2 /tmp/parallel-20190222

ARG TIMEOUT=24h
ENV timeout $TIMEOUT

#ENTRYPOINT ["bash", "-c", "source timeout $timeout /code/entrypoint.sh > >(ts '[%Y-%m-%d %H:%M:%S]' | tee --append /output/stderr.log) 2>&1"]
ENTRYPOINT ["bash", "-c", "source /code/watcher.sh | ts '[%Y-%m-%d %H:%M:%S]' &>> /tmp/stderr.log"]

COPY freesurfer_license.txt /opt/freesurfer/license.txt
COPY entrypoint.sh avg_subject.zip /code/
COPY heuristic.py /code/heuristic.py
COPY generate_norm.py /code/
COPY series_reg.py /code/
COPY watcher.sh /code/
RUN chmod +x /code/entrypoint.sh && chmod +x /code/watcher.sh
