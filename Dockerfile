# Choose your desired base image
# FROM jupyter/scipy-notebook:latest
FROM jupyter/scipy-notebook:584e9ab39d22

# name your environment and choose python 3.x version
ARG conda_env=python36
ARG py_ver=3.6

# you can add additional libraries you want conda to install by listing them below the first line and ending with "&& \"
RUN conda create --quiet --yes -p $CONDA_DIR/envs/$conda_env python=$py_ver ipython ipykernel && \
    conda clean --all -f -y

# alternatively, you can comment out the lines above and uncomment those below
# if you'd prefer to use a YAML file present in the docker build context

# COPY environment.yml /home/$NB_USER/tmp/
# RUN cd /home/$NB_USER/tmp/ && \
#     conda env create -p $CONDA_DIR/envs/$conda_env -f environment.yml && \
#     conda clean --all -f -y


# create Python 3.x environment and link it to jupyter
RUN $CONDA_DIR/envs/${conda_env}/bin/python -m ipykernel install --user --name=${conda_env} && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

# any additional pip installs can be added by uncommenting the following line
# RUN $CONDA_DIR/envs/${conda_env}/bin/pip install

# prepend conda environment to path
ENV PATH $CONDA_DIR/envs/${conda_env}/bin:$PATH


USER root

## Install Daetools
# Python 3:
RUN apt-get update
RUN apt-get install -y python3-numpy python3-scipy python3-matplotlib python3-pyqt5 mayavi2 python3-lxml
# Optional packages:
RUN apt-get install -y python3-openpyxl python3-h5py python3-pandas python3-pygraphviz


USER $NB_USER
# RUN conda install numpy scipy matplotlib pyqt5 mayavi2 lxml
# RUN conda install install openpyxl h5py pandas pygraphviz

# if you want this environment to be the default one, uncomment the following line:
ENV CONDA_DEFAULT_ENV ${conda_env}


RUN conda install --yes numpy scipy matplotlib pyqt lxml pandas h5py openpyxl

# More - OPTIONAL FOR 3D
# RUN conda install -c menpo vtk=7
# RUN conda run -n python36 conda install pygraphviz
# RUN pip install pybind11 pymetis mayavi

# COPY (this is not extracting when built from vscode...)
ADD daetools-1.9.0-gnu_linux-x86_64.tar.gz work/

# MISSING libfortran
USER root

RUN apt install -y software-properties-common dirmngr apt-transport-https lsb-release ca-certificates
RUN add-apt-repository multiverse
#multiverse
RUN apt-get install -y libgfortran3

USER $NB_USER

RUN cd work/daetools-1.9.0-gnu_linux/ && python setup.py install

# END OF DAETOOLS INSTALLATION WITH python3.6


## STARTING CONFIGURATION FOR GCP

# RUN conda run -n python36 conda install Flask gunicorn
# RUN conda install --yes Flask gunicorn
RUN pip install Flask gunicorn dataclasses_json flask_socketio pyequion tinydb gevent-websocket

# Allow statements and log messages to immediately appear in the Knative logs
ENV PYTHONUNBUFFERED True

# Copy local code to the container image.
ENV APP_HOME /app
WORKDIR $APP_HOME
USER root
RUN chown -R $NB_USER:users /app
USER $NB_USER

COPY --chown=$NB_USER:users . ./


# Hello word working
# CMD exec gunicorn --bind :$PORT --workers 1 --threads 8 --timeout 0 main_helloword:app

# Main App
CMD exec gunicorn --bind :$PORT --workers 1 --threads 8 --timeout 0 \
    main_ws:app





# HELPERS:

# Building Locally:
# docker build -t daetools-for-gcp .

# Running server Locally:
# docker run -e PORT=5000 -p 5000:5000 daetools-for-gcp:latest

# Running iteractive shell
# docker run -it --rm daetools-for-gcp3 /bin/bash


