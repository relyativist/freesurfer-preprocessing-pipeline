FROM poldracklab/fmriprep:1.1.8

ENV TERM xterm

RUN apt-get update -qq && \
	apt-get install --yes --no-install-recommends \
	zip unzip pigz jq moreutils time

RUN conda install -y -q -f -c conda-forge dcm2niix=1.0.20190902 && \
	sync

RUN commit=c9cf5ad16fb3021bb5c6e94ec5c63aec7ea9a99c && \
	curl -LOk https://github.com/pieper/dicomsort/archive/${commit}.zip && \
	unzip ${commit}.zip -d /code && \
	mv /code/dicomsort-${commit} /code/dicomsort && \
	rm -rf ${commit}.zip

COPY ./requirements.txt /code/requirements.txt
RUN pip install --upgrade pip && \
	pip install -r /code/requirements.txt && \
	pip uninstall -y tqdm

ADD models.tar.bz2 /models/

COPY utils.py.diff /patch/utils.py.diff
RUN patch /usr/local/miniconda/lib/python3.6/site-packages/heudiconv/utils.py /patch/utils.py.diff

ARG TIMEOUT=24h
ENV timeout $TIMEOUT

ENTRYPOINT ["bash", "-c", "source /code/intro.sh; timeout $timeout /code/entrypoint.sh > >(ts '[%Y-%m-%d %H:%M:%S]' | tee --append /output/stderr.log) 2>&1; source /code/outro.sh"]

COPY freesurfer_license.txt /opt/freesurfer/license.txt
COPY entrypoint.sh avg_subject.zip /code/
RUN chmod +x /code/entrypoint.sh
